import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:fake_post_maker/models/account.dart';
import 'package:fake_post_maker/models/post.dart';
import 'package:fake_post_maker/models/project.dart';
import 'package:fake_post_maker/models/scene.dart';
import 'package:fake_post_maker/models/status_bar_config.dart';

import '../hive_test_utils.dart';

void main() {
  setUp(setUpHiveForTest);
  tearDown(tearDownHiveForTest);

  test('Projectをboxに保存して読み込むと、ネストしたScene/Account/Postを含めて内容が一致する', () async {
    final box = await Hive.openBox<Project>('projects_test');

    final account = Account(
      id: 'account-1',
      displayName: '表示名',
      username: 'user1',
      isVerified: true,
    );
    final post = Post(
      id: 'post-1',
      accountId: account.id,
      body: '本文',
      likeCountLabel: '1.2万',
      repostCountLabel: '100',
      replyCountLabel: '10',
      viewCountLabel: '9999',
      postedAt: DateTime(2026, 8, 1, 12, 0),
      order: 0,
    );
    final statusBarConfig = StatusBarConfig(
      platform: StatusBarPlatform.ios,
      timeMode: TimeMode.manual,
      manualTime: '12:00',
      signalLevel: 4,
      batteryLevel: 80,
      isCharging: false,
    );
    final scene = Scene(
      id: 'scene-1',
      projectId: 'project-1',
      type: SceneType.timeline,
      title: 'タイムライン',
      order: 0,
      statusBarConfig: statusBarConfig,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
      accounts: [account],
      posts: [post],
    );
    final project = Project(
      id: 'project-1',
      name: 'テストプロジェクト',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
      scenes: [scene],
    );

    await box.put('project-1', project);
    await box.close();

    final reopened = await Hive.openBox<Project>('projects_test');
    final loaded = reopened.get('project-1')!;

    expect(loaded.name, 'テストプロジェクト');
    expect(loaded.scenes, hasLength(1));
    expect(loaded.scenes.first.type, SceneType.timeline);
    expect(loaded.scenes.first.accounts.first.username, 'user1');
    expect(loaded.scenes.first.posts.first.likeCountLabel, '1.2万');
    expect(loaded.scenes.first.posts.first.viewCountLabel, '9999');
    expect(
      loaded.scenes.first.statusBarConfig.platform,
      StatusBarPlatform.ios,
    );
  });
}
