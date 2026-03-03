import 'package:flutter/material.dart';

typedef TorchCallback = Future<void> Function();
typedef SwitchCameraCallback = Future<void> Function();
typedef CaptureCallback = Future<void> Function();

class VoiceCommandHandler {
  static TorchCallback? onToggleTorch;
  static SwitchCameraCallback? onSwitchCamera;
  static CaptureCallback? onCapture;

  static Future<void> handle(String command) async {
    print("Command received: $command");

    command = command.toLowerCase();

    if (command.contains("torch")) {
      print("Trigger torch");
      await onToggleTorch?.call();
    }
    else if (command.contains("switch camera")) {
      print("Trigger switch camera");
      await onSwitchCamera?.call();
    }
    else if (command.contains("capture")) {
      print("Trigger capture");
      await onCapture?.call();
    }
  }
}