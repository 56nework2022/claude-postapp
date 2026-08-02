import '../models/project.dart';
import '../models/scene.dart';

class SceneRepository {
  List<Scene> getAll(Project project) {
    return List<Scene>.from(project.scenes)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<void> add(Project project, Scene scene) async {
    project.scenes.add(scene);
    project.updatedAt = DateTime.now();
    await project.save();
  }

  Future<void> update(Project project, Scene scene) async {
    final index = project.scenes.indexWhere((s) => s.id == scene.id);
    if (index == -1) return;
    project.scenes[index] = scene;
    project.updatedAt = DateTime.now();
    await project.save();
  }

  Future<void> delete(Project project, String sceneId) async {
    project.scenes.removeWhere((scene) => scene.id == sceneId);
    project.updatedAt = DateTime.now();
    await project.save();
  }
}
