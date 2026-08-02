import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:fake_x_post_maker/data/hive_boxes.dart';
import 'package:fake_x_post_maker/data/project_repository.dart';
import 'package:fake_x_post_maker/models/project.dart';

import '../hive_test_utils.dart';

void main() {
  setUp(() async {
    await setUpHiveForTest();
    await Hive.openBox<Project>(HiveBoxes.projectsBoxName);
  });
  tearDown(tearDownHiveForTest);

  test('プロジェクトを追加すると一覧取得で参照できる', () async {
    final repository = ProjectRepository();
    final project = Project(
      id: 'project-1',
      name: 'テストプロジェクト',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

    await repository.add(project);

    expect(repository.getAll(), hasLength(1));
    expect(repository.getAll().first.name, 'テストプロジェクト');
  });

  test('プロジェクトを更新するとupdatedAtが更新され内容が反映される', () async {
    final repository = ProjectRepository();
    final project = Project(
      id: 'project-1',
      name: '旧名称',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    await repository.add(project);

    project.name = '新名称';
    await repository.update(project);

    final reloaded = repository.getAll().first;
    expect(reloaded.name, '新名称');
    expect(reloaded.updatedAt.isAfter(DateTime(2026, 8, 1)), isTrue);
  });

  test('プロジェクトを削除すると一覧から取り除かれる', () async {
    final repository = ProjectRepository();
    final project = Project(
      id: 'project-1',
      name: 'テストプロジェクト',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    await repository.add(project);

    await repository.delete(project);

    expect(repository.getAll(), isEmpty);
  });
}
