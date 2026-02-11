import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/call_service.dart';
import 'call_engine.dart';

class WebRTCCallEngine implements CallEngine {
  WebRTCCallEngine({
    required bool isCaller,
    required this.callType,
  }) : _isCaller = isCaller;

  final bool _isCaller;
  late String callType;

  bool get isVideo => callType == 'video';

  late String _callId;

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

  StreamSubscription? _docSub;
  StreamSubscription? _candSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _activeGateSub;

  final Set<String> _seenCandidates = {};
  final List<RTCIceCandidate> _pending = [];

  bool _answering = false;
  bool _startedSignaling = false;

  // INIT
  @override
  Future<void> init({
    required String callId,
    required String userId,
    required String userName,
  }) async {
    if (_initialized) return;
    _initialized = true;

    _callId = callId;

    print("🧭 ENGINE INIT => role=${_isCaller ? 'CALLER' : 'CALLEE'} callId=$_callId type=$callType user=$userId");

    if (isVideo) {
      await _localR.initialize();
      await _remoteR.initialize();
    }

    await _initMedia();
    await _initPeer();

    await Helper.setSpeakerphoneOn(false);

    // IMPORTANT:
    // For scheduled/calltime calls, callee must NOT start answering while status is still "ringing"
    // We wait until call doc becomes "active".
    await _startWhenActive();

    _listenCandidates();
    _listenCallStatus();
  }

  Future<void> _startWhenActive() async {
    // Caller can start immediately (offer)
    if (_isCaller) {
      _startSignaling();
      return;
    }

    // Callee waits until Firestore status becomes "active"
    _activeGateSub?.cancel();
    _activeGateSub = _db.collection('calls').doc(_callId).snapshots().listen((d) {
      final data = d.data();
      if (data == null) return;

      final status = (data['status'] ?? '').toString();
      if (status != 'active') return;

      if (_startedSignaling) return;
      print("✅ CALL ACTIVE => callee starts signaling callId=$_callId");
      _startSignaling();
    });
  }

  void _startSignaling() {
    if (_startedSignaling) return;
    _startedSignaling = true;

    print("🚦 START SIGNALING => role=${_isCaller ? 'CALLER' : 'CALLEE'} callId=$_callId");

    if (_isCaller) {
      _createOffer().then((_) {
        _listenAnswer();
      });
    } else {
      _listenOfferAndAnswer();
    }
  }

  // MEDIA
  Future<void> _initMedia() async {
    print("🎥 getUserMedia => video=$isVideo");
    _local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    });

    if (isVideo) {
      _localR.srcObject = _local;
    }
  }

  // PEER
  Future<void> _initPeer() async {
    print("🔧 createPeerConnection");
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });

    // add tracks
    for (final t in _local!.getAudioTracks()) {
      await _pc!.addTrack(t, _local!);
    }

    if (isVideo) {
      for (final t in _local!.getVideoTracks()) {
        await _pc!.addTrack(t, _local!);
      }
    }

    // remote tracks
    _pc!.onTrack = (e) {
      if (e.streams.isEmpty) return;
      _remote = e.streams.first;

      for (final t in _remote!.getAudioTracks()) {
        t.enabled = true;
      }

      if (isVideo) {
        _remoteR.srcObject = _remote;
      }

      print("📥 onTrack => remote streams=${e.streams.length} audio=${_remote!.getAudioTracks().length} video=${_remote!.getVideoTracks().length}");
    };

    // ICE send
    _pc!.onIceCandidate = (c) {
      if (c.candidate == null) return;

      final role = _isCaller ? 'caller' : 'callee';
      _db
          .collection('calls')
          .doc(_callId)
          .collection('candidates')
          .doc(role)
          .collection('items')
          .add(c.toMap());

      // small log
      // print("🧊 ICE OUT ($role) mid=${c.sdpMid} index=${c.sdpMLineIndex}");
    };

    _pc!.onConnectionState = (s) {
      print("🔗 PC connectionState=$s");
    };
  }

  // OFFER
  Future<void> _createOffer() async {
    print("📤 createOffer");
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    await _db.collection('calls').doc(_callId).set({
      'offer': offer.toMap(),
      'callType': callType,
    }, SetOptions(merge: true));

    print("✅ offer written to firestore callId=$_callId");
  }

  // ANSWER
  void _listenOfferAndAnswer() {
    _docSub?.cancel();

    _docSub = _db.collection('calls').doc(_callId).snapshots().listen((d) async {
      final data = d.data();
      if (data == null) return;

      final offer = data['offer'];
      if (offer == null) return;

      if (_answering) return;

      final remote = await _pc!.getRemoteDescription();
      if (remote != null) return;

      _answering = true;

      try {
        print("📥 offer received => setRemoteDescription");
        await _pc!.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']),
        );

        print("📤 createAnswer");
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);

        await _db.collection('calls').doc(_callId).set({
          'answer': answer.toMap(),
        }, SetOptions(merge: true));

        print("✅ answer written to firestore callId=$_callId");

        await _flushPending();
      } catch (e) {
        print("🔥 ERROR in offer->answer: $e");
      } finally {
        _answering = false;
      }
    });
  }

  void _listenAnswer() {
    _docSub?.cancel();

    _docSub = _db.collection('calls').doc(_callId).snapshots().listen((d) async {
      final data = d.data();
      if (data == null) return;

      final ans = data['answer'];
      if (ans == null) return;

      final remote = await _pc!.getRemoteDescription();
      if (remote != null) return;

      try {
        print("📥 answer received => setRemoteDescription");
        await _pc!.setRemoteDescription(
          RTCSessionDescription(ans['sdp'], ans['type']),
        );

        await _flushPending();
      } catch (e) {
        print("🔥 ERROR in answer setRemote: $e");
      }
    });
  }

  // ICE RECEIVE
  void _listenCandidates() {
    final other = _isCaller ? 'callee' : 'caller';
    print("🧊 listenCandidates from=$other");

    _candSub = _db
        .collection('calls')
        .doc(_callId)
        .collection('candidates')
        .doc(other)
        .collection('items')
        .snapshots()
        .listen((s) async {
      for (final d in s.docs) {
        if (_seenCandidates.contains(d.id)) continue;
        _seenCandidates.add(d.id);

        final m = d.data();
        final ice = RTCIceCandidate(
          m['candidate'],
          m['sdpMid'],
          m['sdpMLineIndex'],
        );

        final remote = await _pc!.getRemoteDescription();

        if (remote == null) {
          _pending.add(ice);
        } else {
          try {
            await _pc!.addCandidate(ice);
          } catch (e) {
            print("🔥 addCandidate error: $e");
          }
        }
      }
    });
  }

  Future<void> _flushPending() async {
    if (_pending.isEmpty) return;

    final remote = await _pc!.getRemoteDescription();
    if (remote == null) return;

    print("🧊 flushPending => ${_pending.length} candidates");
    for (final c in _pending) {
      try {
        await _pc!.addCandidate(c);
      } catch (e) {
        print("🔥 addCandidate(pending) error: $e");
      }
    }
    _pending.clear();
  }

  // STATUS
  void _listenCallStatus() {
    _statusSub = _db.collection('calls').doc(_callId).snapshots().listen((d) async {
      final data = d.data();
      if (data == null) return;

      final s = (data['status'] ?? '').toString();
      if (_ended) return;

      if (s == 'ended' || s == 'missed' || s == 'declined' || s == 'cancelled') {
        print("🛑 CALL STATUS=$s => cleanup callId=$_callId");
        _ended = true;
        await _cleanup();
      }
    });
  }

  // END
  @override
  Future<void> endCall() async {
    if (_ended) return;
    _ended = true;

    print("🛑 endCall() requested callId=$_callId");
    await CallService().endCall(_callId);
    await _cleanup();
  }

  Future<void> _cleanup() async {
    await _docSub?.cancel();
    await _candSub?.cancel();
    await _statusSub?.cancel();
    await _activeGateSub?.cancel();

    try {
      await _pc?.close();
    } catch (_) {}

    for (final t in _local?.getTracks() ?? []) {
      try {
        t.stop();
      } catch (_) {}
    }

    try {
      await _local?.dispose();
    } catch (_) {}

    try {
      await _remote?.dispose();
    } catch (_) {}

    if (isVideo) {
      try {
        await _localR.dispose();
      } catch (_) {}
      try {
        await _remoteR.dispose();
      } catch (_) {}
    }

    print("✅ cleanup done callId=$_callId");
  }

  // CONTROLS
  @override
  void setMuted(bool muted) {
    _muted = muted;
    for (final t in _local?.getAudioTracks() ?? []) {
      t.enabled = !muted;
    }
  }

  @override
  Future<void> setSpeaker(bool enabled) async {
    _speakerOn = enabled;
    await Helper.setSpeakerphoneOn(enabled);
  }

  @override
  Future<void> switchCamera() async {
    if (!isVideo) return;
    final tracks = _local?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;
    await tracks.first.switchCamera();
  }

  @override
  void setVideoEnabled(bool enabled) {
    if (!isVideo) return;
    _videoEnabled = enabled;
    for (final t in _local?.getVideoTracks() ?? []) {
      t.enabled = enabled;
    }
  }

  // UI
  @override
  Widget buildView() {
    if (!isVideo) {
      return const Center(
        child: Icon(Icons.call, color: Colors.white, size: 120),
      );
    }

    return Stack(children: [
      Positioned.fill(child: RTCVideoView(_remoteR)),
      Positioned(
        right: 16,
        top: 48,
        width: 120,
        height: 180,
        child: RTCVideoView(_localR, mirror: true),
      ),
    ]);
  }

  @override
  void dispose() {
    if (!_ended) endCall();
  }
}