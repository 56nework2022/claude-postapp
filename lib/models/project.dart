import 'package:hive/hive.dart';

import 'scene.dart';

part 'project.g.dart';

@HiveType(typeId: 0)
class Project extends HiveObject {
  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    List<Scene>? scenes,
  }) : scenes = scenes ?? [];

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  List<Scene> scenes;
}
