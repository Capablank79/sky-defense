import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class GameAudioController {
  GameAudioController();

  final AudioPlayer _launchPlayer = AudioPlayer(playerId: 'sfx_launch');
  final AudioPlayer _explosionPlayer = AudioPlayer(playerId: 'sfx_explosion');
  final AudioPlayer _baseHitPlayer = AudioPlayer(playerId: 'sfx_base_hit');
  final AudioPlayer _countdownPlayer = AudioPlayer(playerId: 'sfx_countdown');
  bool _initialized = false;

  static final Uint8List _launchBytes = _generateToneWav(
    frequencyHz: 760,
    durationMs: 95,
    volume: 0.4,
    type: _WaveType.triangle,
  );
  static final Uint8List _explosionBytes = _generateToneWav(
    frequencyHz: 110,
    durationMs: 220,
    volume: 0.8,
    type: _WaveType.square,
  );
  static final Uint8List _baseHitBytes = _generateToneWav(
    frequencyHz: 170,
    durationMs: 180,
    volume: 0.65,
    type: _WaveType.sine,
  );
  static final Uint8List _countdownBytes = _generateToneWav(
    frequencyHz: 920,
    durationMs: 75,
    volume: 0.35,
    type: _WaveType.sine,
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await Future.wait(<Future<void>>[
      _configurePlayer(_launchPlayer),
      _configurePlayer(_explosionPlayer),
      _configurePlayer(_baseHitPlayer),
      _configurePlayer(_countdownPlayer),
    ]);
    _initialized = true;
  }

  Future<void> playLaunch() async {
    await _play(_launchPlayer, _launchBytes, volume: 0.55);
  }

  Future<void> playExplosion() async {
    await _play(_explosionPlayer, _explosionBytes, volume: 0.7);
  }

  Future<void> playBaseHit() async {
    await _play(_baseHitPlayer, _baseHitBytes, volume: 0.65);
  }

  Future<void> playCountdownBeep() async {
    await _play(_countdownPlayer, _countdownBytes, volume: 0.45);
  }

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      _launchPlayer.dispose(),
      _explosionPlayer.dispose(),
      _baseHitPlayer.dispose(),
      _countdownPlayer.dispose(),
    ]);
  }

  Future<void> _configurePlayer(AudioPlayer player) async {
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _play(
    AudioPlayer player,
    Uint8List bytes, {
    required double volume,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }
      await player.play(BytesSource(bytes), volume: volume);
    } catch (_) {
      // Keep gameplay resilient if audio is unavailable on a platform.
    }
  }

  static Uint8List _generateToneWav({
    required double frequencyHz,
    required int durationMs,
    required double volume,
    required _WaveType type,
  }) {
    const int sampleRate = 44100;
    final int sampleCount = ((sampleRate * durationMs) / 1000).round();
    final ByteData data = ByteData(44 + (sampleCount * 2));

    void writeString(int offset, String value) {
      for (int i = 0; i < value.length; i += 1) {
        data.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    data.setUint32(4, 36 + (sampleCount * 2), Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    data.setUint32(40, sampleCount * 2, Endian.little);

    final double clampedVolume = volume.clamp(0, 1);
    for (int i = 0; i < sampleCount; i += 1) {
      final double t = i / sampleRate;
      final double envelope = 1.0 - (i / sampleCount);
      final double phase = 2 * pi * frequencyHz * t;
      final double signal;
      switch (type) {
        case _WaveType.triangle:
          signal = (2 / pi) * asin(sin(phase));
          break;
        case _WaveType.square:
          signal = sin(phase) >= 0 ? 1 : -1;
          break;
        case _WaveType.sine:
          signal = sin(phase);
          break;
      }
      final int sample = (signal * 32767 * clampedVolume * envelope).round();
      data.setInt16(44 + (i * 2), sample, Endian.little);
    }

    return data.buffer.asUint8List();
  }
}

enum _WaveType {
  sine,
  square,
  triangle,
}
