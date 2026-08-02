import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 3)
class Account {
  Account({
    required this.id,
    required this.displayName,
    required this.username,
    this.iconImagePath,
    this.isVerified = false,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String displayName;

  @HiveField(2)
  String username;

  @HiveField(3)
  String? iconImagePath;

  @HiveField(4)
  bool isVerified;
}
