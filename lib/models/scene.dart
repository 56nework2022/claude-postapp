import 'package:hive/hive.dart';

import 'account.dart';
import 'post.dart';
import 'status_bar_config.dart';

part 'scene.g.dart';

@HiveType(typeId: 2)
enum SceneType {
  @HiveField(0)
  timeline,
  @HiveField(1)
  postDetail,
  @HiveField(2)
  profile,
  @HiveField(3)
  dm,
}

@HiveType(typeId: 1)
class Scene {
  Scene({
    required this.id,
    required this.projectId,
    required this.type,
    required this.title,
    required this.order,
    required this.statusBarConfig,
    required this.createdAt,
    required this.updatedAt,
    List<Account>? accounts,
    List<Post>? posts,
  })  : accounts = accounts ?? [],
        posts = posts ?? [];

  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  SceneType type;

  @HiveField(3)
  String title;

  @HiveField(4)
  int order;

  @HiveField(5)
  StatusBarConfig statusBarConfig;

  @HiveField(6)
  List<Account> accounts;

  @HiveField(7)
  List<Post> posts;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;
}
