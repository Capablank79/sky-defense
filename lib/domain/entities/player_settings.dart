class PlayerSettings {
  const PlayerSettings({
    required this.soundEnabled,
    required this.hapticEnabled,
  });

  final bool soundEnabled;
  final bool hapticEnabled;

  PlayerSettings copyWith({
    bool? soundEnabled,
    bool? hapticEnabled,
  }) {
    return PlayerSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }
}
