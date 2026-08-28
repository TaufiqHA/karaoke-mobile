import 'package:flutter/material.dart';
import '../../../core/services/category_service.dart';
import '../../../core/services/dummy_category_service.dart';
import '../../../core/services/dummy_song_service.dart';
import '../../../core/services/song_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../models/song_model.dart';

class AdminSongScreen extends StatefulWidget {
  final SongService? songService;
  final CategoryService? categoryService;

  const AdminSongScreen({
    super.key,
    this.songService,
    this.categoryService,
  });

  @override
  State<AdminSongScreen> createState() => _AdminSongScreenState();
}

class _AdminSongScreenState extends State<AdminSongScreen> {
  late final SongService _songService;
  late final CategoryService _categoryService;

  List<SongModel> _allSongs = [];
  List<SongModel> _filteredSongs = [];
  List<CategoryModel> _categories = [];
  int? _selectedCategoryFilter; // null = Semua
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _songService = widget.songService ?? DummySongService();
    _categoryService = widget.categoryService ?? DummyCategoryService();
    _searchController.addListener(_filterSongs);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _parseCategoryId(String id) {
    final numeric = id.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numeric) ?? 1;
  }

  String _getCategoryName(int categoryId) {
    final cat = _categories.firstWhere(
      (c) => _parseCategoryId(c.id) == categoryId,
      orElse: () => CategoryModel(
        id: 'cat_$categoryId',
        name: 'Kategori #$categoryId',
        createdAt: DateTime.now(),
      ),
    );
    return cat.name;
  }

  Future<void> _loadData() async {
    try {
      final categoriesList = await _categoryService.getCategories();
      final songsList = await _songService.getSongs();

      if (mounted) {
        setState(() {
          _categories = categoriesList;
          _allSongs = songsList;
          _filterSongs();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterSongs() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredSongs = _allSongs.where((song) {
        final matchQuery = query.isEmpty ||
            song.songtitle.toLowerCase().contains(query) ||
            song.songsinger.toLowerCase().contains(query);

        final matchCategory = _selectedCategoryFilter == null ||
            song.songcategory == _selectedCategoryFilter;

        return matchQuery && matchCategory;
      }).toList();
    });
  }

  Future<void> _showSongFormDialog({SongModel? song}) async {
    final isEditing = song != null;
    final titleController = TextEditingController(text: song?.songtitle ?? '');
    final singerController = TextEditingController(text: song?.songsinger ?? '');
    final urlController = TextEditingController(text: song?.songurl ?? '');
    final durationController = TextEditingController(text: song?.songduration ?? '');
    
    // Ensure default category is valid
    int selectedCategory = song?.songcategory ??
        (_categories.isNotEmpty ? _parseCategoryId(_categories.first.id) : 1);
    
    // Sanitize selectedNada to prevent crashes with legacy values like "C", "Am", etc.
    String? selectedNada;
    if (song?.songnada != null) {
      final lower = song!.songnada!.trim().toLowerCase();
      if (lower == 'pria') {
        selectedNada = 'Pria';
      } else if (lower == 'wanita') {
        selectedNada = 'Wanita';
      } else {
        selectedNada = null;
      }
    }

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.cardGlassBorder, width: 1.2),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryElectric.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.library_add_rounded,
                      color: AppColors.accentCyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Ubah Lagu' : 'Tambah Lagu Baru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    tooltip: 'Tutup',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul Lagu
                          const Text(
                            'Judul Lagu *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: titleController,
                            autofocus: !isEditing,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration(
                              hint: 'Contoh: Sial, Rungkad, dll.',
                              icon: Icons.music_note_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Judul lagu wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Artis / Penyanyi
                          const Text(
                            'Artis / Penyanyi *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: singerController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration(
                              hint: 'Contoh: Mahalini, Dewa 19, dll.',
                              icon: Icons.person_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama penyanyi wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Kategori Lagu
                          const Text(
                            'Kategori Lagu *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            initialValue: _categories.any((c) => _parseCategoryId(c.id) == selectedCategory)
                                ? selectedCategory
                                : (_categories.isNotEmpty ? _parseCategoryId(_categories.first.id) : 1),
                            dropdownColor: AppColors.surfaceDark,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration(
                              hint: 'Pilih Kategori',
                              icon: Icons.category_rounded,
                            ),
                            items: _categories.map((cat) {
                              final catId = _parseCategoryId(cat.id);
                              return DropdownMenuItem<int>(
                                value: catId,
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedCategory = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // URL Lagu / Media
                          const Text(
                            'URL Lagu / Media *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: urlController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration(
                              hint: 'Contoh: https://example.com/audio/lagu.mp3',
                              icon: Icons.link_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'URL lagu wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Nada Lagu (Full-Width Selector: Pria / Wanita)
                          const Text(
                            'Nada Lagu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: Row(
                              children: [
                                // Tombol Pria
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      setDialogState(() {
                                        selectedNada = selectedNada == 'Pria' ? null : 'Pria';
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      decoration: BoxDecoration(
                                        color: selectedNada == 'Pria'
                                            ? AppColors.primaryElectric
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.male_rounded,
                                              size: 18,
                                              color: selectedNada == 'Pria'
                                                  ? Colors.white
                                                  : AppColors.accentSky,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Nada Pria',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: selectedNada == 'Pria'
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: selectedNada == 'Pria'
                                                    ? Colors.white
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Tombol Wanita
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      setDialogState(() {
                                        selectedNada = selectedNada == 'Wanita' ? null : 'Wanita';
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      decoration: BoxDecoration(
                                        color: selectedNada == 'Wanita'
                                            ? const Color(0xFFD81B60)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.female_rounded,
                                              size: 18,
                                              color: selectedNada == 'Wanita'
                                                  ? Colors.white
                                                  : const Color(0xFFFF80AB),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Nada Wanita',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: selectedNada == 'Wanita'
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: selectedNada == 'Wanita'
                                                    ? Colors.white
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Durasi Lagu (mm:ss)
                          const Text(
                            'Durasi Lagu (mm:ss)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: durationController,
                            maxLength: 5,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDecoration(
                              hint: 'Contoh: 03:45',
                              icon: Icons.timer_outlined,
                            ),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value.trim())) {
                                  return 'Format: mm:ss';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (isEditing) {
                        final updated = song.copyWith(
                          songtitle: titleController.text.trim(),
                          songsinger: singerController.text.trim(),
                          songurl: urlController.text.trim(),
                          songcategory: selectedCategory,
                          songnada: selectedNada?.trim().isNotEmpty == true ? selectedNada : null,
                          songduration: durationController.text.trim().isNotEmpty ? durationController.text.trim() : null,
                        );
                        await _songService.updateSong(updated);
                      } else {
                        await _songService.createSong(
                          songtitle: titleController.text.trim(),
                          songsinger: singerController.text.trim(),
                          songurl: urlController.text.trim(),
                          songcategory: selectedCategory,
                          songnada: selectedNada?.trim().isNotEmpty == true ? selectedNada : null,
                          songduration: durationController.text.trim().isNotEmpty ? durationController.text.trim() : null,
                        );
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryElectric,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _loadData();
      _showSnackbar(
        isEditing ? 'Lagu berhasil diperbarui' : 'Lagu berhasil ditambahkan',
        AppColors.primaryElectric,
      );
    }
  }

  Future<void> _showDeleteDialog(SongModel song) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardGlassBorder, width: 1.2),
        ),
        title: const Text(
          'Hapus Lagu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apakah Anda yakin ingin menghapus lagu "${song.songtitle}" oleh ${song.songsinger}?',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tindakan ini tidak dapat dibatalkan.',
                  style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Batal', style: TextStyle(color: AppColors.accentSky)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _songService.deleteSong(song.songid);
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (deleted == true) {
      await _loadData();
      _showSnackbar('Lagu berhasil dihapus', AppColors.error);
    }
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.accentSky, size: 18),
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputFocusedBorder, width: 1.5),
      ),
    );
  }

  void _showSnackbar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accentCyan,
          backgroundColor: AppColors.surfaceDark,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul & Tombol Tambah
                      Row(
                        children: [
                          const Text(
                            'Kelola Lagu',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryElectric.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_allSongs.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentSky,
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _showSongFormDialog(),
                            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Tambah Lagu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryElectric,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Search Bar
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Cari judul lagu atau nama penyanyi...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.cardGlass,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.cardGlassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.cardGlassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.accentCyan, width: 1.2),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Filter Kategori Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Semua'),
                              selected: _selectedCategoryFilter == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategoryFilter = null;
                                    _filterSongs();
                                  });
                                }
                              },
                              selectedColor: AppColors.primaryElectric,
                              backgroundColor: AppColors.cardGlass,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: _selectedCategoryFilter == null ? FontWeight.bold : FontWeight.normal,
                                color: _selectedCategoryFilter == null ? Colors.white : AppColors.textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: _selectedCategoryFilter == null
                                      ? AppColors.accentCyan
                                      : AppColors.cardGlassBorder,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ..._categories.map((cat) {
                              final catId = _parseCategoryId(cat.id);
                              final isSelected = _selectedCategoryFilter == catId;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(cat.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategoryFilter = selected ? catId : null;
                                      _filterSongs();
                                    });
                                  },
                                  selectedColor: AppColors.primaryElectric,
                                  backgroundColor: AppColors.cardGlass,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.accentCyan
                                          : AppColors.cardGlassBorder,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Songs List
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                    ),
                  ),
                )
              else if (_filteredSongs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          size: 48,
                          color: AppColors.accentSky.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tidak ada lagu ditemukan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Coba kata kunci lain atau tambah lagu baru',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = _filteredSongs[index];
                        final categoryName = _getCategoryName(song.songcategory);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardGlass,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.cardGlassBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Song Leading Icon / Number
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.cardGradient,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.accentCyan.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      color: AppColors.accentCyan,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Song Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title & Singer
                                      Text(
                                        song.songtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        song.songsinger,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.accentSky,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Badges: Category, Key/Nada, Duration
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          // Category Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryElectric.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppColors.accentCyan.withValues(alpha: 0.3),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              categoryName,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.accentLight,
                                              ),
                                            ),
                                          ),

                                          // Nada Badge (Pria / Wanita / Custom)
                                          if (song.songnada != null && song.songnada!.isNotEmpty)
                                            Builder(
                                              builder: (context) {
                                                final isWanita = song.songnada!.toLowerCase() == 'wanita';
                                                final isPria = song.songnada!.toLowerCase() == 'pria';
                                                final Color badgeColor = isWanita
                                                    ? const Color(0xFFFF69B4)
                                                    : isPria
                                                        ? AppColors.accentNeon
                                                        : Colors.amberAccent;
                                                final IconData icon = isWanita
                                                    ? Icons.female_rounded
                                                    : isPria
                                                        ? Icons.male_rounded
                                                        : Icons.tune_rounded;

                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: badgeColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: badgeColor.withValues(alpha: 0.4),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(icon, size: 12, color: badgeColor),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        'Nada: ${song.songnada}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                          color: badgeColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),

                                          // Duration Badge (if present)
                                          if (song.songduration != null && song.songduration!.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.timer_outlined, size: 10, color: AppColors.textSecondary),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    song.songduration!,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Action Buttons
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.accentCyan,
                                    size: 20,
                                  ),
                                  tooltip: 'Ubah',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _showSongFormDialog(song: song),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  tooltip: 'Hapus',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _showDeleteDialog(song),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _filteredSongs.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
