import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/project_repository.dart';
import '../models/project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

final projectListProvider =
    NotifierProvider<ProjectListNotifier, List<Project>>(
      ProjectListNotifier.new,
    );

class ProjectListNotifier extends Notifier<List<Project>> {
  @override
  List<Project> build() {
    return ref.read(projectRepositoryProvider).getAll();
  }

  Future<void> createProject(String name) async {
    final repository = ref.read(projectRepositoryProvider);
    final now = DateTime.now();
    final project = Project(
      id: _generateId(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await repository.add(project);
    state = repository.getAll();
  }

  Future<void> renameProject(Project project, String name) async {
    final repository = ref.read(projectRepositoryProvider);
    project.name = name;
    await repository.update(project);
    state = repository.getAll();
  }

  Future<void> deleteProject(Project project) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.delete(project);
    state = repository.getAll();
  }

  String _generateId() {
    final randomSuffix = Random().nextInt(1 << 32).toRadixString(16);
    return '${DateTime.now().microsecondsSinceEpoch}-$randomSuffix';
  }
}
