import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/category_model.dart';
import 'category_service.dart';

class DummyCategoryService implements CategoryService {
  static const String _keyCategories = 'app_categories_data';

  final List<CategoryModel> _defaultCategories = [
    CategoryModel(
      songcategoryid: 1,
      songcategoryname: 'Pop Indonesia',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    CategoryModel(
      songcategoryid: 2,
      songcategoryname: 'Dangdut & Koplo',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    CategoryModel(
      songcategoryid: 3,
      songcategoryname: 'Rock & Metal',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    CategoryModel(
      songcategoryid: 4,
      songcategoryname: 'Barat / International',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    CategoryModel(
      songcategoryid: 5,
      songcategoryname: 'K-Pop',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    CategoryModel(
      songcategoryid: 6,
      songcategoryname: 'Anime & J-Pop',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<List<CategoryModel>> getCategories({String? search}) async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_keyCategories);

    List<CategoryModel> list;
    if (jsonString == null || jsonString.isEmpty) {
      // Inisialisasi data default
      await _saveAll(_defaultCategories);
      list = List.from(_defaultCategories);
    } else {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        list = decoded
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        list = List.from(_defaultCategories);
      }
    }

    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(query)).toList();
    }

    return list;
  }

  @override
  Future<CategoryModel> getCategory(int id) async {
    final categories = await getCategories();
    return categories.firstWhere(
      (c) => c.songcategoryid == id || c.id == id.toString(),
      orElse: () => throw Exception('Kategori tidak ditemukan'),
    );
  }

  @override
  Future<CategoryModel> createCategory(String name) async {
    final categories = await getCategories();
    final newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newCategory = CategoryModel(
      songcategoryid: newId,
      songcategoryname: name.trim(),
      createdAt: DateTime.now(),
    );

    categories.insert(0, newCategory);
    await _saveAll(categories);
    return newCategory;
  }

  @override
  Future<CategoryModel> updateCategory(dynamic id, String newName) async {
    final strId = id.toString();
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == strId || c.songcategoryid.toString() == strId);

    if (index == -1) {
      throw Exception('Kategori tidak ditemukan');
    }

    final updated = categories[index].copyWith(name: newName.trim());
    categories[index] = updated;
    await _saveAll(categories);
    return updated;
  }

  @override
  Future<bool> deleteCategory(dynamic id) async {
    final strId = id.toString();
    final categories = await getCategories();
    final initialLength = categories.length;
    categories.removeWhere((c) => c.id == strId || c.songcategoryid.toString() == strId);

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
