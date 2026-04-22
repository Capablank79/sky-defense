import 'package:flame/components.dart';

class City {
  const City({
    required this.id,
    required this.position,
    required this.isAlive,
  });

  final String id;
  final Vector2 position;
  final bool isAlive;
  double get x => position.x;
  double get y => position.y;

  City copyWith({
    String? id,
    Vector2? position,
    bool? isAlive,
  }) {
    return City(
      id: id ?? this.id,
      position: position ?? this.position.clone(),
      isAlive: isAlive ?? this.isAlive,
    );
  }
}
