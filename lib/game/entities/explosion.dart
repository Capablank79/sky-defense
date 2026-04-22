class Explosion {
  const Explosion({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.lifetime,
    required this.maxLifetime,
    required this.isActive,
  });

  final String id;
  final double x;
  final double y;
  final double radius;
  final double lifetime;
  final double maxLifetime;
  final bool isActive;

  Explosion copyWith({
    String? id,
    double? x,
    double? y,
    double? radius,
    double? lifetime,
    double? maxLifetime,
    bool? isActive,
  }) {
    return Explosion(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius ?? this.radius,
      lifetime: lifetime ?? this.lifetime,
      maxLifetime: maxLifetime ?? this.maxLifetime,
      isActive: isActive ?? this.isActive,
    );
  }
}
