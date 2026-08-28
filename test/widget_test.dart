import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:karaoke_app/main.dart';
import 'package:karaoke_app/screens/admin/admin_home_screen.dart';
import 'package:karaoke_app/screens/admin/admin_main_layout.dart';
import 'package:karaoke_app/screens/admin/admin_sidebar.dart';
import 'package:karaoke_app/screens/admin/category/admin_category_screen.dart';
import 'package:karaoke_app/screens/admin/song/admin_song_screen.dart';
import 'package:karaoke_app/screens/admin/user/admin_user_screen.dart';
import 'package:karaoke_app/screens/login_screen.dart';
import 'package:karaoke_app/screens/splash_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash screen renders properly and transitions to LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const KaraokeApp());

    // Memverifikasi Splash Screen tampil dengan teks 'Karaoke App'
    expect(find.text('Karaoke App'), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Animasi pump
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Sing Your Heart Out'), findsOneWidget);

    // Advance timer splash screen (2.5s) dan animasi transisi (0.6s)
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // Verifikasi otomatis berpindah ke LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Login screen validation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Memverifikasi field Username & Password tersedia
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);

    // Memverifikasi TIDAK ADA lupa password atau register
    expect(find.textContaining('Lupa'), findsNothing);
    expect(find.textContaining('Daftar'), findsNothing);
    expect(find.textContaining('Register'), findsNothing);

    // Mencoba submit saat field kosong
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    // Verifikasi pesan validasi muncul
    expect(find.text('Username tidak boleh kosong'), findsOneWidget);
    expect(find.text('Password tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('Admin Home Screen renders summary of songs and users', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminHomeScreen(),
        ),
      ),
    );

    // Loading state awal
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump untuk menyelesaikan request dummy stats
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Verifikasi judul dan kartu ringkasan
    expect(find.text('Beranda Admin'), findsOneWidget);
    expect(find.text('Total Lagu Diinput'), findsOneWidget);
    expect(find.text('Total User Terdaftar'), findsOneWidget);
    expect(find.text('1.250'), findsOneWidget);
    expect(find.text('348'), findsOneWidget);
  });

  testWidgets('Admin Main Layout persistent sidebar and tab navigation test', (WidgetTester tester) async {
    // Set ukuran layar lebar (desktop/tablet)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminMainLayout(),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi Sidebar dan Beranda tampil
    expect(find.byType(AdminSidebar), findsOneWidget);
    expect(find.text('Beranda Admin'), findsOneWidget);

    // Tap menu 'Kategori' di sidebar
    await tester.tap(find.text('Kategori'));
    await tester.pumpAndSettle();

    // Verifikasi halaman 'AdminCategoryScreen' tampil tanpa menghapus AdminSidebar
    expect(find.byType(AdminSidebar), findsOneWidget);
    expect(find.byType(AdminCategoryScreen), findsOneWidget);

    // Tap menu 'Kelola Lagu' di sidebar
    await tester.tap(find.text('Kelola Lagu'));
    await tester.pumpAndSettle();

    // Verifikasi halaman 'AdminSongScreen' tampil tanpa menghapus AdminSidebar
    expect(find.byType(AdminSidebar), findsOneWidget);
    expect(find.byType(AdminSongScreen), findsOneWidget);
  });

  testWidgets('Admin Category Screen CRUD operations test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminCategoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. READ: Memverifikasi kategori bawaan tampil
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Pop Indonesia'), findsOneWidget);
    expect(find.text('Dangdut & Koplo'), findsOneWidget);

    // 2. CREATE: Menambah kategori baru 'Jazz & Blues' via tombol Tambah
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Kategori'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, ''), 'Jazz & Blues');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // Verifikasi kategori baru muncul
    expect(find.text('Jazz & Blues'), findsOneWidget);

    // 3. UPDATE: Mengubah kategori 'Jazz & Blues' menjadi 'Smooth Jazz'
    final editButtons = find.byTooltip('Ubah');
    await tester.tap(editButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Ubah Kategori'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Smooth Jazz');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Smooth Jazz'), findsOneWidget);

    // 4. DELETE: Menghapus kategori 'Smooth Jazz'
    final deleteButtons = find.byTooltip('Hapus');
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Hapus Kategori'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
    await tester.pumpAndSettle();

    // Verifikasi 'Smooth Jazz' sudah terhapus
    expect(find.text('Smooth Jazz'), findsNothing);
  });

  testWidgets('Admin Song Screen CRUD and search/filter test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminSongScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. READ: Memverifikasi lagu awal dan header tampil
    expect(find.text('Kelola Lagu'), findsOneWidget);
    expect(find.text('Sial'), findsOneWidget);
    expect(find.text('Mahalini'), findsOneWidget);
    expect(find.text('Rungkad'), findsOneWidget);
    expect(find.text('Nada: Wanita'), findsWidgets);

    // 2. SEARCH: Mencari berdasarkan judul lagu 'Sial'
    await tester.enterText(find.byType(TextField), 'Sial');
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Sial'), findsOneWidget);
    expect(find.text('Rungkad'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Rungkad'), findsOneWidget);

    // 3. CREATE: Menambahkan lagu baru
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Lagu'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Lagu Baru'), findsOneWidget);

    final formFields = find.byType(TextFormField);
    // formFields[0]: Judul Lagu
    // formFields[1]: Penyanyi
    // formFields[2]: URL Lagu
    // formFields[3]: Durasi
    await tester.enterText(formFields.at(0), 'Hampa');
    await tester.enterText(formFields.at(1), 'Ari Lasso');
    await tester.enterText(formFields.at(2), 'https://example.com/audio/hampa.mp3');
    await tester.enterText(formFields.at(3), '04:12');

    // Pilih Nada 'Pria' dari segmented button
    await tester.tap(find.text('Nada Pria'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // Verifikasi lagu baru muncul di list
    expect(find.text('Hampa'), findsOneWidget);
    expect(find.text('Ari Lasso'), findsOneWidget);
    expect(find.text('04:12'), findsOneWidget);

    // 4. UPDATE: Mengubah lagu 'Hampa'
    final editButtons = find.byTooltip('Ubah');
    await tester.tap(editButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Ubah Lagu'), findsOneWidget);
    final editFields = find.byType(TextFormField);
    await tester.enterText(editFields.at(0), 'Hampa (Akustik)');

    // Ubah Nada menjadi 'Wanita'
    await tester.tap(find.text('Nada Wanita'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Hampa (Akustik)'), findsOneWidget);

    // 5. DELETE: Menghapus lagu 'Hampa (Akustik)'
    final deleteButtons = find.byTooltip('Hapus');
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Hapus Lagu'), findsOneWidget);
    expect(find.textContaining('Apakah Anda yakin ingin menghapus lagu "Hampa (Akustik)"'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
    await tester.pumpAndSettle();

    // Verifikasi lagu terhapus
    expect(find.text('Hampa (Akustik)'), findsNothing);
  });

  testWidgets('Admin User Screen CRUD and search/filter test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminUserScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. READ: Memverifikasi user awal tampil
    expect(find.text('Kelola User'), findsOneWidget);
    expect(find.text('admin'), findsWidgets);
    expect(find.text('operator'), findsOneWidget);
    expect(find.text('karaoke_lover'), findsOneWidget);

    // 2. FILTER & SEARCH: Mencari berdasarkan username 'karaoke_lover'
    await tester.enterText(find.byType(TextField), 'karaoke_lover');
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && w.data == 'karaoke_lover'), findsOneWidget);
    expect(find.text('operator'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('operator'), findsOneWidget);

    // Filter by role chip 'Admin'
    await tester.tap(find.widgetWithText(ChoiceChip, 'Admin'));
    await tester.pumpAndSettle();
    expect(find.text('admin'), findsWidgets);
    expect(find.text('operator'), findsOneWidget);
    expect(find.text('karaoke_lover'), findsNothing);

    // Reset filter to 'Semua'
    await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
    await tester.pumpAndSettle();
    expect(find.text('karaoke_lover'), findsOneWidget);

    // 3. CREATE: Menambahkan user baru
    await tester.tap(find.text('Tambah User'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Pengguna Baru'), findsOneWidget);

    final formFields = find.byType(TextFormField);
    // formFields[0]: Username
    // formFields[1]: Password
    await tester.enterText(formFields.at(0), 'budi_santoso');
    await tester.enterText(formFields.at(1), 'budi1234');

    // Pilih role 'Administrator'
    await tester.tap(find.text('Administrator'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan Pengguna'));
    await tester.pumpAndSettle();

    // Verifikasi user baru muncul di list
    expect(find.text('budi_santoso'), findsOneWidget);

    // 4. UPDATE: Mengubah user 'budi_santoso'
    final editButtons = find.byTooltip('Ubah');
    await tester.tap(editButtons.last);
    await tester.pumpAndSettle();

    expect(find.text('Ubah Akun Pengguna'), findsOneWidget);
    final editFields = find.byType(TextFormField);
    await tester.enterText(editFields.at(0), 'budi_super');

    // Ubah role ke 'User Biasa'
    await tester.tap(find.text('User Biasa'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('budi_super'), findsOneWidget);

    // 5. DELETE: Menghapus user 'budi_super'
    final deleteButtons = find.byTooltip('Hapus');
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    expect(find.text('Hapus Pengguna'), findsOneWidget);
    expect(find.textContaining('Apakah Anda yakin ingin menghapus akun pengguna "budi_super"'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
    await tester.pumpAndSettle();

    // Verifikasi user terhapus
    expect(find.text('budi_super'), findsNothing);
  });
}
