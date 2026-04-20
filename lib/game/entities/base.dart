class Base {
  const Base({
    required this.id,
    required this.x,
    required this.y,
    this.healthMax = 3,
    this.health = 3,
    this.ammoMax = 10,
    this.ammoCurrent = 10,
    this.ammoRegenRate = 0.6,
    this.isDestroyed = false,
  });

  final String id;
  final double x;
  final double y;
  final int healthMax;
  final int health;
  final int ammoMax;
  final double ammoCurrent;
  final double ammoRegenRate;
  final bool isDestroyed;

  Base copyWith({
    String? id,
    double? x,
    double? y,
    int? healthMax,
    int? health,
    int? ammoMax,
    double? ammoCurrent,
    double? ammoRegenRate,
    bool? isDestroyed,
  }) {
    return Base(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      healthMax: healthMax ?? this.healthMax,
      health: health ?? this.health,
      ammoMax: ammoMax ?? this.ammoMax,
      ammoCurrent: ammoCurrent ?? this.ammoCurrent,
      ammoRegenRate: ammoRegenRate ?? this.ammoRegenRate,
      isDestroyed: isDestroyed ?? this.isDestroyed,
    );
  }
}
