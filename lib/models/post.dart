import 'package:hive/hive.dart';

part 'post.g.dart';

@HiveType(typeId: 4)
class Post {
  Post({
    required this.id,
    required this.accountId,
    required this.body,
    required this.likeCountLabel,
    required this.repostCountLabel,
    required this.replyCountLabel,
    required this.postedAt,
    required this.order,
    this.quotedPostId,
    this.imagePath,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String accountId;

  @HiveField(2)
  String body;

  @HiveField(3)
  String likeCountLabel;

  @HiveField(4)
  String repostCountLabel;

  @HiveField(5)
  String replyCountLabel;

  @HiveField(6)
  DateTime postedAt;

  @HiveField(7)
  String? quotedPostId;

  @HiveField(8)
  int order;

  @HiveField(9)
  String? imagePath;
}
