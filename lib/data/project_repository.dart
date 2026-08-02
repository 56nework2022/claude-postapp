import '../models/project.dart';
import 'hive_boxes.dart';

class ProjectRepository {
  List<Project> getAll() {
    return HiveBoxes.projectsBox.values.toList();
  }

  Future<void> add(Project project) async {
    await HiveBoxes.projectsBox.add(project);
  }

  Future<void> update(Project project) async {
    project.updatedAt = DateTime.now();
    await project.save();
  }

  Future<void> delete(Project project) async {
    await project.delete();
  }
}
