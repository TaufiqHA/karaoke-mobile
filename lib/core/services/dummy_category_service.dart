import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/category_model.dart';
import 'category_service.dart';

class DummyCategoryService implements CategoryService {
  static const String _keyCategories = 'app_categories_data';

  final List<CategoryModel> _defaultCategories = [
    CategoryModel(
      id: 'cat_1',
      name: 'Pop Indonesia',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    CategoryModel(
      id: 'cat_2',
      name: 'Dangdut & Koplo',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    CategoryModel(
      id: 'cat_3',
      name: 'Rock & Metal',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    CategoryModel(
      id: 'cat_4',
      name: 'Barat / International',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    CategoryModel(
      id: 'cat_5',
      name: 'K-Pop',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    CategoryModel(
      id: 'cat_6',
      name: 'Anime & J-Pop',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_keyCategories);

    if (jsonString == null || jsonString.isEmpty) {
      // Inisialisasi data default
      await _saveAll(_defaultCategories);
      return List.from(_defaultCategories);
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List.from(_defaultCategories);
    }
  }

  @override
  Future<CategoryModel> createCategory(String name) async {
    final categories = await getCategories();
    final newCategory = CategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    categories.insert(0, newCategory);
    await _saveAll(categories);
    return newCategory;
  }

  @override
  Future<CategoryModel> updateCategory(String id, String newName) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == id);

    if (index == -1) {
      throw Exception('Kategori tidak ditemukan');
    }

    final updated = categories[index].copyWith(name: newName.trim());
    categories[index] = updated;
    await _saveAll(categories);
    return updated;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    final categories = await getCategories();
    final initialLength = categories.length;
    categories.removeWhere((c) => c.id == id);

    if (categories.length < initialLength) {
      await _saveAll(categories);
      return true;
    }
    return false;
  }

  Future<void> _saveAll(List<CategoryModel> categories) async {
    final prefs = await _getPrefs();
    final jsonList = categories.map((c) => c.toJson()).toList();
    await prefs.setString(_keyCategories, jsonEncode(jsonList));
  }
}
