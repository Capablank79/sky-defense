class Explosion {
  const Explosion({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.lifetime,
    required this.isActive,
  });

  final String id;
  final double x;
  final double y;
  final double radius;
  final double lifetime;
  final bool isActive;

  Explosion copyWith({
    String? id,
    double? x,
    double? y,
    double? radius,
    double? lifetime,
    bool? isActive,
  }) {
    return Explosion(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius ?? this.radius,
      lifetime: lifetime ?? this.lifetime,
      isActive: isActive ?? this.isActive,
    );
  }
}
