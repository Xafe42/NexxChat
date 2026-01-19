import 'package:flutter/material.dart';

abstract class CallEngine {
  void init({
    required String callId,
    required String userId,
    required String userName,
  });

  Widget buildView();

  Future<void> endCall();

  void dispose();
}