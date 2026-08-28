import '../../models/category_model.dart';

abstract class CategoryService {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory(String name);
  Future<CategoryModel> updateCategory(String id, String newName);
  Future<bool> deleteCategory(String id);
}
