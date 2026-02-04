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

  final Set<String> _seenCandidates = {};
  final List<RTCIceCandidate> _pending = [];

  bool _answering = false;

  // ================= INIT =================

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

    await Helper.setSpeakerphoneOn(false);

    if (_isCaller) {
      await _createOffer();
      _listenAnswer();
    } else {
      _listenOfferAndAnswer();
    }

    _listenCandidates();
    _listenCallStatus();
    
    
  }
 
  // ================= MEDIA =================

  Future<void> _initMedia() async {
    _local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    });

    if (isVideo) {
      _localR.srcObject = _local;
    }
  }

  // ================= PEER =================

  Future<void> _initPeer() async {
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });

    // add ONLY existing tracks
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

      // 🔥 VERY IMPORTANT: enable remote audio
      for (final t in _remote!.getAudioTracks()) {
        t.enabled = true;
      }

      if (isVideo) {
        _remoteR.srcObject = _remote;
      }
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
    };
  }

  // ================= OFFER =================

  Future<void> _createOffer() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    await _db.collection('calls').doc(_callId).set({
      'offer': offer.toMap(),
      'callType': callType,
    }, SetOptions(merge: true));
  }

  // ================= ANSWER =================

  void _listenOfferAndAnswer() {
    _docSub?.cancel();

    _docSub = _db.collection('calls').doc(_callId).snapshots().listen((d) async {
      final offer = d.data()?['offer'];
      if (offer == null) return;

      if (_answering) return;
      if (await _pc!.getRemoteDescription() != null) return;

      _answering = true;

      await _pc!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);

      await _db.collection('calls').doc(_callId).set({
        'answer': answer.toMap(),
      }, SetOptions(merge: true));

      _answering = false;
    });
  }

  void _listenAnswer() {
    _docSub?.cancel();

    _docSub = _db.collection('calls').doc(_callId).snapshots().listen((d) async {
      final ans = d.data()?['answer'];
      if (ans == null) return;

      if (await _pc!.getRemoteDescription() != null) return;

      await _pc!.setRemoteDescription(
        RTCSessionDescription(ans['sdp'], ans['type']),
      );

      await _flushPending();
    });
  }

  // ================= ICE RECEIVE =================

  void _listenCandidates() {
    final other = _isCaller ? 'callee' : 'caller';

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

        if (await _pc!.getRemoteDescription() == null) {
          _pending.add(ice);
        } else {
          await _pc!.addCandidate(ice);
        }
      }
    });
  }

  Future<void> _flushPending() async {
    for (final c in _pending) {
      await _pc!.addCandidate(c);
    }
    _pending.clear();
  }

  // ================= STATUS =================

  void _listenCallStatus() {
    _statusSub =
        _db.collection('calls').doc(_callId).snapshots().listen((d) async {
      final s = d.data()?['status'];
      if (_ended) return;

      if (s == 'ended' ||
          s == 'missed' ||
          s == 'declined' ||
          s == 'cancelled') {
        _ended = true;
        await _cleanup();
      }
    });
  }

  // ================= END =================

  @override
  Future<void> endCall() async {
    if (_ended) return;
    _ended = true;

    await CallService().endCall(_callId);
    await _cleanup();
  }

  Future<void> _cleanup() async {
    await _docSub?.cancel();
    await _candSub?.cancel();
    await _statusSub?.cancel();

    await _pc?.close();

    for (final t in _local?.getTracks() ?? []) {
      t.stop();
    }

    await _local?.dispose();
    await _remote?.dispose();

    if (isVideo) {
      await _localR.dispose();
      await _remoteR.dispose();
    }
  }

  // ================= CONTROLS =================

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

  // ================= UI =================

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