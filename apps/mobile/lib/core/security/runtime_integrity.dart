import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class RuntimeIntegrityResult {
  const RuntimeIntegrityResult({
    required this.blocked,
    required this.reasons,
  });

  final bool blocked;
  final List<String> reasons;
}

class RuntimeIntegrityService {
  RuntimeIntegrityService(this._deviceInfo);

  final DeviceInfoPlugin _deviceInfo;

  Future<RuntimeIntegrityResult> evaluate({required bool enforce}) async {
    final reasons = <String>[];
    final jailbroken = await _safeJailbreakCheck();
    if (jailbroken) reasons.add('root_or_jailbreak_detected');

    final developerMode = await _safeDeveloperModeCheck();
    if (developerMode) reasons.add('developer_mode_enabled');

    final emulator = await _safeEmulatorCheck();
    if (emulator) reasons.add('emulator_or_virtual_device');

    return RuntimeIntegrityResult(
      blocked: enforce && reasons.isNotEmpty,
      reasons: reasons,
    );
  }

  Future<bool> _safeJailbreakCheck() async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeDeveloperModeCheck() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterJailbreakDetection.developerMode;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeEmulatorCheck() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        if (!info.isPhysicalDevice) return true;
        final fingerprint = info.fingerprint.toLowerCase();
        final model = info.model.toLowerCase();
        final brand = info.brand.toLowerCase();
        return fingerprint.contains('generic') ||
            fingerprint.contains('emulator') ||
            model.contains('sdk_gphone') ||
            model.contains('emulator') ||
            brand.contains('generic');
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        if (!info.isPhysicalDevice) return true;
        final machine = info.utsname.machine.toLowerCase();
        return machine.contains('x86_64') || machine.contains('arm64e-sim');
      }
    } catch (_) {
      return false;
    }
    return false;
  }
}

final runtimeIntegrityEnabledByDefault = kReleaseMode;
