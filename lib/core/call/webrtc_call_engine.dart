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

  bool get isVideo => callType == 'video';

  @override
  Future<void> init({
    required String callId,
    required String userId,
    required String userName,
  }) async {
    if (_initialized) return;
    _initialized = true;

    _callId = callId;

    if (isVideo) {
      await _localR.initialize();
      await _remoteR.initialize();
    }

    await _initMedia();
    await _initPeer();
    await setSpeaker(false);

    if (_isCaller) {
      await _createOffer();
      _listenAnswer();
    } else {
      _listenOfferAndAnswer();
    }

    _listenCandidates();
    _listenCallStatus();
  }

  Future<void> _initMedia() async {
    _local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    });

    if (isVideo) {
      _localR.srcObject = _local;
    }
  }

  Future<void> _initPeer() async {
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    for (final track in _local!.getTracks()) {
      await _pc!.addTrack(track, _local!);
    }

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remote = event.streams.first;
        if (isVideo) {
          _remoteR.srcObject = _remote;
        }
      }
    };

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;

      final role = _isCaller ? 'caller' : 'callee';

      _db
          .collection('calls')
          .doc(_callId)
          .collection('candidates')
          .doc(role)
          .collection('items')
          .add(candidate.toMap());
    };
  }

  Future<void> _createOffer() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    await _db.collection('calls').doc(_callId).set({
      'offer': offer.toMap(),
    }, SetOptions(merge: true));
  }

  void _listenOfferAndAnswer() {
    _docSub?.cancel();
    _docSub = _db.collection('calls').doc(_callId).snapshots().listen((doc) async {
      final data = doc.data();
      if (data == null || data['offer'] == null) return;
      if (_pc?.getRemoteDescription() != null) return;

      final offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );

      await _pc!.setRemoteDescription(offer);

      await _db.collection('calls').doc(_callId).set({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptedAtMs': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);

      await _db.collection('calls').doc(_callId).set({
        'answer': answer.toMap(),
      }, SetOptions(merge: true));
    });
  }

  void _listenAnswer() {
    _docSub?.cancel();
    _docSub = _db.collection('calls').doc(_callId).snapshots().listen((doc) async {
      final data = doc.data();
      if (data == null || data['answer'] == null) return;
      if (_pc?.getRemoteDescription() != null) return;

      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );

      await _pc!.setRemoteDescription(answer);
    });
  }

  void _listenCandidates() {
    final otherRole = _isCaller ? 'callee' : 'caller';

    _candSub = _db
        .collection('calls')
        .doc(_callId)
        .collection('candidates')
        .doc(otherRole)
        .collection('items')
        .snapshots()
        .listen((snap) async {
      for (final d in snap.docs) {
        if (_seenCandidates.contains(d.id)) continue;
        _seenCandidates.add(d.id);

        final m = d.data();
        final c = RTCIceCandidate(
          m['candidate'],
          m['sdpMid'],
          m['sdpMLineIndex'],
        );
        await _pc?.addCandidate(c);
      }
    });
  }

  void _listenCallStatus() {
    _statusSub = _db.collection('calls').doc(_callId).snapshots().listen((doc) async {
      final status = doc.data()?['status'];

      if (_ended) return;

      if (status == 'ended' ||
          status == 'missed' ||
          status == 'declined' ||
          status == 'cancelled') {
        _ended = true;
        await _cleanupOnly();
      }
    });
  }

  @override
  Future<void> endCall() async {
    if (_ended) return;
    _ended = true;

    try {
      await CallService().endCall(_callId);
    } catch (_) {}

    await _cleanupOnly();
  }

  Future<void> _cleanupOnly() async {
    try {
      await _docSub?.cancel();
      await _candSub?.cancel();
      await _statusSub?.cancel();
    } catch (_) {}

    try {
      await _pc?.close();
    } catch (_) {}

    try {
      for (final t in _local?.getTracks() ?? []) {
        t.stop();
      }
      for (final t in _remote?.getTracks() ?? []) {
        t.stop();
      }
      await _local?.dispose();
      await _remote?.dispose();
    } catch (_) {}

    try {
      if (isVideo) {
        await _localR.dispose();
        await _remoteR.dispose();
      }
    } catch (_) {}
  }

  // CONTROLS 

  @override
  void setMuted(bool muted) {
    _muted = muted;
    for (final track in _local?.getAudioTracks() ?? []) {
      track.enabled = !muted;
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

    // flutter_webrtc: MediaStreamTrack.switchCamera() is async
    await tracks.first.switchCamera();
  }

  @override
  void setVideoEnabled(bool enabled) {
    _videoEnabled = enabled;
    for (final track in _local?.getVideoTracks() ?? []) {
      track.enabled = enabled;
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