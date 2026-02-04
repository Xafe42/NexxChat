import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/call_service.dart';
import 'call_engine.dart';

class WebRTCCallEngine implements CallEngine {
  WebRTCCallEngine({
    required bool isCaller,
    required this.callType, // "video" | "audio"
  }) : _isCaller = isCaller;

  final bool _isCaller;
  final String callType;

  late String _callId;
  late String _userId;
  late String _userName;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RTCPeerConnection? _pc;
  MediaStream? _local;
  MediaStream? _remote;

  final RTCVideoRenderer _localR = RTCVideoRenderer();
  final RTCVideoRenderer _remoteR = RTCVideoRenderer();

  bool _initialized = false;
  bool _ended = false;

  bool _muted = false;
  bool _speakerOn = false;
  bool _videoEnabled = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _statusSub;

  final Set<String> _seenCandidates = {};
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  Timer? _safetyTimer;

  // ✅ prevents double-answer on callee
  bool _answering = false;

  bool get isVideo => callType == 'video';

  // ---------------- LOGS ----------------

  void _log(String m) {
    final role = _isCaller ? 'CALLER' : 'CALLEE';
    // ignore: avoid_print
    print('[$role] ${DateTime.now().toIso8601String()} | $m');
  }

  void _logErr(String ctx, Object e, [StackTrace? st]) {
    // ignore: avoid_print
    print('❌ [$ctx] $e');
    if (st != null) {
      // ignore: avoid_print
      print(st);
    }
  }

  // ---------------- INIT ----------------

  @override
  Future<void> init({
    required String callId,
    required String userId,
    required String userName,
  }) async {
    if (_initialized) return;
    _initialized = true;

    _callId = callId;
    _userId = userId;
    _userName = userName;

    _log('🚀 init START');
    _log('callId=$_callId userId=$_userId userName=$_userName callType=$callType isVideo=$isVideo');

    if (isVideo) {
      _log('🎥 renderer init...');
      await _localR.initialize();
      await _remoteR.initialize();
      _log('🎥 renderer init DONE');
    }

    await _initMedia();
    await _initPeer();

    // default audio route
    await setSpeaker(false);

    // safety timeout (if never connected)
    _safetyTimer?.cancel();
    _safetyTimer = Timer(const Duration(seconds: 35), () async {
      if (_ended) return;
      _log('⚠️ SAFETY TIMEOUT: no connection after 35s => ending');
      await endCall();
    });

    // start listeners
    _listenCandidates();
    _listenCallStatus();

    if (_isCaller) {
      _log('📞 role=CALLER => createOffer + listenAnswer');
      await _createOffer();
      _listenAnswer();
    } else {
      _log('📞 role=CALLEE => listenOfferAndAnswer');
      _listenOfferAndAnswer();
    }

    _log('✅ init END');
  }

  // ---------------- MEDIA ----------------

  Future<void> _initMedia() async {
    _log('🎙️📷 _initMedia START');

    _local = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo ? {'facingMode': 'user'} : false,
    });

    if (isVideo) _localR.srcObject = _local;

    final a = _local?.getAudioTracks() ?? [];
    final v = _local?.getVideoTracks() ?? [];
    _log('LOCAL tracks => audio=${a.length} video=${v.length}');
    for (final t in a) {
      _log('LOCAL audio track: id=${t.id} enabled=${t.enabled}');
    }
    for (final t in v) {
      _log('LOCAL video track: id=${t.id} enabled=${t.enabled}');
    }

    _log('🎙️📷 _initMedia END');
  }

  // ---------------- PEER ----------------

  Future<void> _initPeer() async {
    _log('🧠 _initPeer START');

    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': 'turn:openrelay.metered.ca:80',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
      ],
      'sdpSemantics': 'unified-plan',
    });

    _log('🧠 PeerConnection created');

    // ----- debug states -----
    _pc!.onSignalingState = (s) => _log('📡 SIGNALING: $s');
    _pc!.onIceGatheringState = (s) => _log('🧊 ICE_GATHERING: $s');

    _pc!.onIceConnectionState = (s) async {
      _log('🧊 ICE_CONNECTION: $s');
      if (s == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          s == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _safetyTimer?.cancel();
      }
      if (s == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _log('⚠️ ICE failed => ending');
        await endCall();
      }
    };

    _pc!.onConnectionState = (s) async {
      _log('🔗 CONNECTION: $s');

      if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _safetyTimer?.cancel();
        // mark connected (best-effort)
        try {
          await _db.collection('calls').doc(_callId).set({
            'status': 'connected',
            'connectedAtMs': DateTime.now().millisecondsSinceEpoch,
          }, SetOptions(merge: true));
          _log('✅ status=connected written');
        } catch (e) {
          _logErr('write connected status', e);
        }
      }

      if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _log('⚠️ PC failed => ending');
        await endCall();
      }
    };

    // ----- transceivers (unified-plan) -----
    _log('➕ addTransceiver(audio sendrecv)');
    await _pc!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
    );

    if (isVideo) {
      _log('➕ addTransceiver(video sendrecv)');
      await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );
    }

    // ----- add local tracks -----
    final tracks = _local?.getTracks() ?? [];
    _log('➕ addTrack() count=${tracks.length}');
    for (final t in tracks) {
      await _pc!.addTrack(t, _local!);
      _log('addTrack: kind=${t.kind} id=${t.id}');
    }

    // ----- remote tracks -----
    _pc!.onTrack = (event) async {
      _log('✅ onTrack fired kind=${event.track.kind} streams=${event.streams.length}');
      if (event.streams.isEmpty) return;

      _remote = event.streams.first;

      final ra = _remote?.getAudioTracks() ?? [];
      final rv = _remote?.getVideoTracks() ?? [];
      _log('REMOTE tracks => audio=${ra.length} video=${rv.length}');

      for (final t in ra) {
        t.enabled = true;
      }

      if (isVideo) {
        _remoteR.srcObject = _remote;
      }
    };

    // ----- ICE -> Firestore -----
    _pc!.onIceCandidate = (c) async {
      if (c.candidate == null) return;

      final role = _isCaller ? 'caller' : 'callee';
      try {
        await _db
            .collection('calls')
            .doc(_callId)
            .collection('candidates')
            .doc(role)
            .collection('items')
            .add({
          ...c.toMap(),
          'createdAtMs': DateTime.now().millisecondsSinceEpoch,
        });

        _log('🧊 ICE -> Firestore saved (role=$role) mid=${c.sdpMid} mline=${c.sdpMLineIndex}');
      } catch (e, st) {
        _logErr('sendCandidate', e, st);
      }
    };

    _log('🧠 _initPeer END');
  }

  // ---------------- OFFER / ANSWER ----------------

  /// Caller: write offer + status=ringing
  Future<void> _createOffer() async {
    _log('📤 _createOffer START');

    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': isVideo ? 1 : 0,
    });

    _log('📤 offer created: type=${offer.type} sdpLen=${offer.sdp?.length ?? 0}');

    await _pc!.setLocalDescription(offer);
    _log('📤 setLocalDescription(offer) DONE');

    try {
      await _db.collection('calls').doc(_callId).set({
  'offer': offer.toMap(),
  'createdAtMs': DateTime.now().millisecondsSinceEpoch,
  'callType': callType,
}, SetOptions(merge: true));
      _log('📤 offer written to Firestore (status=ringing)');
    } catch (e, st) {
      _logErr('Firestore write offer', e, st);
      rethrow;
    }

    _log('📤 _createOffer END');
  }

  /// Caller: wait answer then setRemote(answer)
void _listenAnswer() {
  _docSub?.cancel();

  _log('👂 _listenAnswer START');

  _docSub = _db.collection('calls').doc(_callId).snapshots().listen(
    (doc) async {
      final data = doc.data();
      if (data == null) return;

      final ans = data['answer'];

      
      if (ans == null) return;

      
      if ( await _pc?.getRemoteDescription()  != null) {
        _log('⏭️ remoteDescription already set => ignore');
        return;
      }

      _log('📥 ANSWER RECEIVED');

      try {
        final answer = RTCSessionDescription(
          ans['sdp'],
          ans['type'],
        );

        await _pc!.setRemoteDescription(answer);

        _log('✅ setRemoteDescription(answer) DONE');

        await _flushPendingCandidates();

      } catch (e, st) {
        _logErr('setRemoteDescription(answer)', e, st);
      }
    },
    onError: (e) => _logErr('_listenAnswer stream', e),
  );
}

 void _listenOfferAndAnswer() {
  _docSub?.cancel();

  _log('👂 _listenOfferAndAnswer START');

  _docSub = _db.collection('calls').doc(_callId).snapshots().listen(
    (doc) async {
      final data = doc.data();
      if (data == null) return;

      final offerMap = data['offer'];
      if (offerMap == null) return;

      if (_answering) return;

      if (await _pc?.getRemoteDescription() != null) return;

      _answering = true;

      try {
        _log('📥 OFFER RECEIVED');

        final offer = RTCSessionDescription(
          offerMap['sdp'],
          offerMap['type'],
        );

        await _pc!.setRemoteDescription(offer);
        _log('✅ setRemoteDescription(offer)');

        await _flushPendingCandidates();

        final answer = await _pc!.createAnswer();

        await _pc!.setLocalDescription(answer);
        _log('✅ setLocalDescription(answer)');

        await _db.collection('calls').doc(_callId).set({
          'answer': answer.toMap(),
        }, SetOptions(merge: true));

        _log('📤 ANSWER WRITTEN');
      } catch (e, st) {
        _logErr('listenOfferAndAnswer', e, st);
      } finally {
        _answering = false;
      }
    },
  );
}

  // ---------------- CANDIDATES ----------------

  void _listenCandidates() {
    final otherRole = _isCaller ? 'callee' : 'caller';

    _candSub?.cancel();
    _log('👂 _listenCandidates START otherRole=$otherRole');

    _candSub = _db
        .collection('calls')
        .doc(_callId)
        .collection('candidates')
        .doc(otherRole)
        .collection('items')
        .orderBy('createdAtMs')
        .snapshots()
        .listen(
      (snap) async {
        _log('🧊 candidates snapshot => size=${snap.size} changes=${snap.docChanges.length}');

        for (final ch in snap.docChanges) {
          if (ch.type != DocumentChangeType.added) continue;

          final d = ch.doc;
          if (_seenCandidates.contains(d.id)) continue;
          _seenCandidates.add(d.id);

          final m = d.data();
          if (m == null) continue;

          final c = RTCIceCandidate(
            m['candidate'],
            m['sdpMid'],
            m['sdpMLineIndex'],
          );

          _log('🧊 remote candidate received mid=${c.sdpMid} mline=${c.sdpMLineIndex}');

          if (await _pc?.getRemoteDescription()== null) {
            _pendingRemoteCandidates.add(c);
            _log('📥 queued candidate (waiting remoteDescription)');
          } else {
            try {
              await _pc!.addCandidate(c);
              _log('✅ addCandidate DONE');
            } catch (e, st) {
              _logErr('addCandidate', e, st);
            }
          }
        }
      },
      onError: (e) => _logErr('_listenCandidates stream', e),
    );
  }

  Future<void> _flushPendingCandidates() async {
    if (await _pc?.getRemoteDescription() == null) return;
    if (_pendingRemoteCandidates.isEmpty) return;

    _log('🔁 flushing pending candidates: ${_pendingRemoteCandidates.length}');

    final copy = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();

    for (final c in copy) {
      try {
        await _pc?.addCandidate(c);
        _log('✅ addCandidate(flush) DONE');
      } catch (e, st) {
        _logErr('addCandidate(flush)', e, st);
      }
    }
  }

  // ---------------- STATUS ----------------

  void _listenCallStatus() {
    _statusSub?.cancel();
    _log('👂 _listenCallStatus START');

    _statusSub = _db.collection('calls').doc(_callId).snapshots().listen(
      (doc) async {
        final status = doc.data()?['status'];
        if (_ended) return;

        _log('📌 status snapshot => status=$status');

        if (status == 'ended' ||
            status == 'missed' ||
            status == 'declined' ||
            status == 'cancelled') {
          _log('📌 status terminal=$status => cleanup');
          _ended = true;
          await _cleanupOnly();
        }
      },
      onError: (e) => _logErr('_listenCallStatus stream', e),
    );
  }

  // ---------------- END / CLEANUP ----------------

  @override
  Future<void> endCall() async {
    if (_ended) return;
    _ended = true;

    _log('🛑 endCall START');

    // best-effort: mark ended
    try {
      await _db.collection('calls').doc(_callId).set({
        'status': 'ended',
        'endedAtMs': DateTime.now().millisecondsSinceEpoch,
        'endedBy': _userId,
      }, SetOptions(merge: true));
    } catch (_) {}

    try {
      await CallService().endCall(_callId);
      _log('🛑 CallService.endCall DONE');
    } catch (_) {}

    await _cleanupOnly();
    _log('🛑 endCall END');
  }

  Future<void> _cleanupOnly() async {
    _log('🧹 cleanup START');

    _safetyTimer?.cancel();
    _safetyTimer = null;

    try {
      await _docSub?.cancel();
      await _candSub?.cancel();
      await _statusSub?.cancel();
      _log('🧹 subscriptions cancelled');
    } catch (_) {}

    try {
      await _pc?.close();
      _log('🧹 pc.close DONE');
    } catch (_) {}

    try {
      final lt = _local?.getTracks() ?? [];
      final rt = _remote?.getTracks() ?? [];
      _log('🧹 stop local tracks=${lt.length} remote tracks=${rt.length}');

      for (final t in lt) {
        t.stop();
      }
      for (final t in rt) {
        t.stop();
      }

      await _local?.dispose();
      await _remote?.dispose();
      _log('🧹 streams disposed');
    } catch (_) {}

    try {
      if (isVideo) {
        await _localR.dispose();
        await _remoteR.dispose();
        _log('🧹 renderers disposed');
      }
    } catch (_) {}

    _log('🧹 cleanup END');
  }

  // ---------------- CONTROLS ----------------

  @override
  void setMuted(bool muted) {
    _muted = muted;
    for (final track in _local?.getAudioTracks() ?? []) {
      track.enabled = !muted;
    }
    _log('🎙️ muted=$_muted');
  }

  @override
  Future<void> setSpeaker(bool enabled) async {
    _speakerOn = enabled;
    await Helper.setSpeakerphoneOn(enabled);
    _log('🔈 setSpeaker($_speakerOn) DONE');
  }

  @override
  Future<void> switchCamera() async {
    if (!isVideo) return;
    final tracks = _local?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;
    await tracks.first.switchCamera();
    _log('📷 switchCamera DONE');
  }

  @override
  void setVideoEnabled(bool enabled) {
    _videoEnabled = enabled;
    for (final track in _local?.getVideoTracks() ?? []) {
      track.enabled = enabled;
    }
    _log('🎥 videoEnabled=$_videoEnabled');
  }

  // ---------------- UI ----------------

  @override
  Widget buildView() {
    if (!isVideo) {
      return const Center(
        child: Icon(Icons.call, color: Colors.white, size: 120),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: RTCVideoView(
            _remoteR,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
        Positioned(
          right: 16,
          top: 48,
          width: 120,
          height: 180,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RTCVideoView(
              _localR,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    if (!_ended) {
      endCall();
    }
  }
}