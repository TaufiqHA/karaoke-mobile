import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:karaoke_app/core/services/auth_service.dart';
import 'package:karaoke_app/core/services/dummy_category_service.dart';
import 'package:karaoke_app/core/services/dummy_song_service.dart';
import 'package:karaoke_app/models/user_model.dart';
import 'package:karaoke_app/screens/admin/admin_main_layout.dart';
import 'package:karaoke_app/screens/login_screen.dart';
import 'package:karaoke_app/screens/profile/profile_screen.dart';
import 'package:karaoke_app/screens/user/user_main_layout.dart';
import 'package:karaoke_app/screens/user/widgets/player_controls.dart';
import 'package:karaoke_app/screens/user/widgets/player_display.dart';
import 'package:karaoke_app/screens/user/widgets/song_catalog_playlist_section.dart';
import 'package:karaoke_app/screens/user/widgets/youtube_video_player.dart';
import 'package:karaoke_app/services/cast/smart_tv_cast_service.dart';

class MockRoleAuthService implements AuthService {
  final UserModel returnUser;

  MockRoleAuthService(this.returnUser);

  @override
  Future<AuthResponse> login(String username, String password) async {
    return AuthResponse.success(
      token: 'fake_token',
      user: returnUser,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<String?> getToken() async => 'fake_token';

  @override
  Future<UserModel?> getProfile() async => returnUser;

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String username,
    required String email,
  }) async => returnUser;

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('UserMainLayout renders header, player display, player controls, and embedded song catalog & playlist', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final dummySongService = DummySongService();
    final dummyCatService = DummyCategoryService();

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: dummySongService,
          categoryService: dummyCatService,
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verifikasi Header (Minimalis tanpa subteks & tanpa tombol cari)
    expect(find.text('Karaoke App'), findsOneWidget);
    expect(find.text('Ruang Bernyanyi'), findsNothing);
    expect(find.byTooltip('Cari Lagu'), findsNothing);
    expect(find.byTooltip('Manajemen Profil'), findsOneWidget);
    expect(find.byTooltip('Keluar'), findsOneWidget);

    // 2. Verifikasi Sub-widget Utama
    expect(find.byType(PlayerDisplay), findsOneWidget);
    expect(find.byType(PlayerControls), findsOneWidget);
    expect(find.byType(SongCatalogPlaylistSection), findsOneWidget);

    // 3. Verifikasi Bagian Cari Lagu & Playlist langsung di layar utama
    expect(find.text('Cari lagu...'), findsOneWidget);
    expect(find.text('hasil pencarian'), findsOneWidget);
    expect(find.text('playlist'), findsOneWidget);
    expect(find.text('Filter Lagu'), findsOneWidget);
    expect(find.text('judul lagu'), findsNothing);
    expect(find.text('pencipta'), findsNothing);
    expect(find.text('nada'), findsNothing);

    // 4. Verifikasi Status Awal Player Kosong
    expect(find.text('Player'), findsWidgets);
    expect(find.text('STANDBY'), findsNothing);
    expect(find.byType(YoutubeVideoPlayerWidget), findsNothing);

    // 5. Pilih lagu dari hasil pencarian (menambahkan ke playlist) lalu tekan tombol Putar di playlist
    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();

    expect(find.text('Playlist masih kosong'), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Putar'));
    await tester.pumpAndSettle();

    // 6. Verifikasi Lagu dan Video YouTube muncul setelah dipilih
    expect(find.textContaining('Sial'), findsWidgets);
    expect(find.textContaining('Mahalini'), findsWidgets);
    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);
    expect(find.text('Video'), findsNothing);
    expect(find.text('Visualizer'), findsNothing);
  });

  testWidgets('UserMainLayout search, filter category, and play song test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi katalog memuat lagu di layar
    expect(find.text('Rungkad'), findsOneWidget);
    expect(find.text('Happy Asmara'), findsOneWidget);

    // Filter pencarian
    await tester.enterText(find.byType(TextField).first, 'Rungkad');
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Rungkad'), findsOneWidget);
    expect(find.text('Kemesraan'), findsNothing);

    // Klik pada lagu 'Rungkad' untuk memasukkan ke playlist lalu putar
    await tester.tap(find.byWidgetPredicate((w) => w is Text && w.data == 'Rungkad'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Putar'));
    await tester.pumpAndSettle();

    // Verifikasi lagu yang diputar di Player berubah menjadi 'Rungkad'
    expect(find.textContaining('Rungkad'), findsWidgets);

    // Bersihkan filter pencarian agar seluruh katalog muncul kembali
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Putar'));
    await tester.pumpAndSettle();

    // Verifikasi lagu baru berikutnya berhasil ter-load di player
    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);
  });

  testWidgets('UserMainLayout queue management test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi awal: playlist kosong
    expect(find.text('Playlist masih kosong'), findsOneWidget);

    // Tambah lagu ke playlist via tombol (+)
    final queueButtons = find.byTooltip('Tambah ke Playlist');
    expect(queueButtons, findsWidgets);

    // Klik tombol tambah ke playlist untuk lagu pertama
    await tester.tap(queueButtons.first);
    await tester.pumpAndSettle();

    // Verifikasi playlist memuat 1 lagu dan memiliki tombol hapus
    expect(find.byTooltip('Hapus dari Playlist'), findsOneWidget);
    expect(find.text('Playlist masih kosong'), findsNothing);

    // Hapus dari playlist
    await tester.tap(find.byTooltip('Hapus dari Playlist'));
    await tester.pumpAndSettle();

    expect(find.text('Playlist masih kosong'), findsOneWidget);
  });

  testWidgets('UserMainLayout playback controls and volume test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tambah lagu ke playlist dan putar
    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Putar'));
    await tester.pumpAndSettle();

    // Tombol Berhenti (Stop)
    final stopBtn = find.byIcon(Icons.stop_rounded);
    expect(stopBtn, findsOneWidget);
    await tester.tap(stopBtn);
    await tester.pump(const Duration(milliseconds: 200));

    // Tombol Putar (Play) untuk melanjutkan
    final playBtn = find.byIcon(Icons.play_arrow_rounded);
    expect(playBtn, findsWidgets);
    await tester.tap(playBtn.first);
    await tester.pump(const Duration(milliseconds: 200));

    // Tombol Jeda (Pause)
    final pauseBtn = find.byIcon(Icons.pause_rounded);
    expect(pauseBtn, findsWidgets);
    await tester.tap(pauseBtn.first);
    await tester.pump(const Duration(milliseconds: 200));

    // Kontrol Bisukan (Mute)
    final muteBtn = find.byIcon(Icons.volume_up_rounded).first;
    await tester.tap(muteBtn);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.volume_off_rounded), findsWidgets);

    // Batal Bisukan (Unmute)
    final unMuteBtn = find.byIcon(Icons.volume_off_rounded).first;
    await tester.tap(unMuteBtn);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);

    // Tombol Layar Penuh (Fullscreen)
    final fsBtn = find.byIcon(Icons.fullscreen_rounded);
    if (fsBtn.evaluate().isNotEmpty) {
      await tester.tap(fsBtn.first);
      await tester.pump(const Duration(milliseconds: 200));
    }
  });

  testWidgets('UserMainLayout cinema player display test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Masukkan lagu ke playlist dan putar
    await tester.tap(find.textContaining('Sial').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Putar'));
    await tester.pumpAndSettle();

    // Video player langsung aktif di layar panggung tanpa tombol visualizer
    expect(find.byType(YoutubeVideoPlayerWidget), findsOneWidget);
    expect(find.text('Visualizer'), findsNothing);
    expect(find.text('Video'), findsNothing);
  });

  testWidgets('UserMainLayout responsive mobile layout test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 680);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('FLUTTER_ERROR_CONTEXT: ${details.context?.toDescription()}');
      if (details.informationCollector != null) {
        for (final node in details.informationCollector!()) {
          debugPrint('COLLECTOR: ${node.toDescription()}');
        }
      }
      oldHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldHandler);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi tetap menampilkan komponen utama secara vertikal tanpa overflow awal
    expect(find.byType(PlayerDisplay), findsOneWidget);
    expect(find.byType(PlayerControls), findsOneWidget);
    expect(find.text('Player'), findsWidgets);

    // Pastikan tidak ada exception overflow sama sekali
    expect(tester.takeException(), isNull);
  });

  testWidgets('UserMainLayout navigates to ProfileScreen via profile button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final profileBtn = find.byTooltip('Manajemen Profil');
    await tester.tap(profileBtn);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Manajemen Profil'), findsOneWidget);
  });

  testWidgets('LoginScreen routes user role to UserMainLayout', (WidgetTester tester) async {
    const regularUser = UserModel(
      id: 'usr_reg_1',
      username: 'karaoke_lover',
      displayName: 'Karaoke Lover',
      role: 'user',
    );

    final userAuthService = MockRoleAuthService(regularUser);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: userAuthService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'karaoke_lover');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Verifikasi diarahkan ke UserMainLayout
    expect(find.byType(UserMainLayout), findsOneWidget);
    expect(find.byType(AdminMainLayout), findsNothing);
  });

  testWidgets('LoginScreen routes admin role to AdminMainLayout', (WidgetTester tester) async {
    const adminUser = UserModel(
      id: 'usr_adm_1',
      username: 'admin',
      displayName: 'Administrator',
      role: 'admin',
    );

    final adminAuthService = MockRoleAuthService(adminUser);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: adminAuthService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Verifikasi diarahkan ke AdminMainLayout
    expect(find.byType(AdminMainLayout), findsOneWidget);
    expect(find.byType(UserMainLayout), findsNothing);
  });

  testWidgets('UserMainLayout cast to Smart TV modal and connection test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final castService = SmartTvCastService(isTestMode: true);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          castService: castService,
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi tombol Cast ada pada kontroler
    final castBtn = find.byIcon(Icons.cast_rounded);
    expect(castBtn, findsOneWidget);

    // Buka modal Cast ke TV
    await tester.tap(castBtn);
    await tester.pumpAndSettle();

    // Verifikasi modal terbuka dan menampilkan 'Perangkat tidak ditemukan' (tanpa data dummy)
    expect(find.text('Cast ke TV'), findsOneWidget);
    expect(find.text('Perangkat tidak ditemukan'), findsOneWidget);
    expect(find.text('Samsung Smart TV'), findsNothing);
    expect(find.text('Chromecast'), findsNothing);

    // Hubungkan menggunakan Kode TV
    await tester.enterText(find.byType(TextField).last, 'TV-ROOM-99');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hubungkan'));
    await tester.pumpAndSettle();

    // Modal tertutup dan status berubah menjadi terhubung (Icons.cast_connected_rounded)
    expect(find.byIcon(Icons.cast_connected_rounded), findsOneWidget);

    // Buka modal lagi untuk memverifikasi opsi Putus
    await tester.tap(find.byIcon(Icons.cast_connected_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Putus'), findsOneWidget);
    await tester.tap(find.text('Putus'));
    await tester.pumpAndSettle();

    // Kembali ke status tidak terhubung
    expect(find.byIcon(Icons.cast_rounded), findsOneWidget);
  });

  testWidgets('UserMainLayout song filter expand and collapse toggle test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Kondisi awal: Filter Lagu tertutup secara default (collapsed)
    expect(find.text('Filter Lagu'), findsOneWidget);
    expect(find.text('judul lagu'), findsNothing);
    expect(find.text('pencipta'), findsNothing);
    expect(find.text('nada'), findsNothing);

    // 2. Ketuk header 'Filter Lagu' untuk expand
    await tester.tap(find.text('Filter Lagu'));
    await tester.pumpAndSettle();

    // Dropdown tampil setelah dibuka
    expect(find.text('Filter Lagu'), findsOneWidget);
    expect(find.text('judul lagu'), findsOneWidget);
    expect(find.text('pencipta'), findsOneWidget);
    expect(find.text('nada'), findsOneWidget);

    // 3. Ketuk header 'Filter Lagu' lagi untuk collapse kembali
    await tester.tap(find.text('Filter Lagu'));
    await tester.pumpAndSettle();

    // Dropdown kembali tertutup
    expect(find.text('Filter Lagu'), findsOneWidget);
    expect(find.text('judul lagu'), findsNothing);
    expect(find.text('pencipta'), findsNothing);
    expect(find.text('nada'), findsNothing);
  });

  testWidgets('UserMainLayout tablet mode: player on left, search top-right, playlist bottom-right', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi SongCatalogPlaylistSection menggunakan axis: Axis.vertical pada tablet
    final catalogFinder = find.byType(SongCatalogPlaylistSection);
    expect(catalogFinder, findsOneWidget);
    final catalogWidget = tester.widget<SongCatalogPlaylistSection>(catalogFinder);
    expect(catalogWidget.axis, Axis.vertical);

    // 2. Verifikasi Posisi Horizontal: Player berada di kiri, Search & Playlist di kanan
    final playerCenter = tester.getCenter(find.byType(PlayerDisplay));
    final searchCenter = tester.getCenter(find.text('hasil pencarian'));
    final playlistCenter = tester.getCenter(find.text('playlist'));

    expect(playerCenter.dx, lessThan(searchCenter.dx));
    expect(playerCenter.dx, lessThan(playlistCenter.dx));

    // 3. Verifikasi Posisi Vertikal pada kolom kanan: Cari lagu di atas, Playlist di bawah
    expect(searchCenter.dy, lessThan(playlistCenter.dy));

    // 4. Verifikasi tidak ada error overflow pada mode tablet (PlayerControls bebas overflow)
    expect(tester.takeException(), isNull);
  });

  testWidgets('UserMainLayout tablet and desktop resolutions overflow-free verification', (WidgetTester tester) async {
    const resolutions = [
      Size(800, 600),
      Size(1024, 768),
      Size(1280, 800),
      Size(1366, 768),
      Size(1920, 1080),
    ];

    for (final res in resolutions) {
      tester.view.physicalSize = res;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: UserMainLayout(
            songService: DummySongService(),
            categoryService: DummyCategoryService(),
            isTestMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlayerControls), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
  });

  testWidgets('UserMainLayout smartphone mode: vertical stack with side-by-side search and playlist', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: UserMainLayout(
          songService: DummySongService(),
          categoryService: DummyCategoryService(),
          isTestMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi SongCatalogPlaylistSection menggunakan axis: Axis.horizontal pada smartphone
    final catalogFinder = find.byType(SongCatalogPlaylistSection);
    expect(catalogFinder, findsOneWidget);
    final catalogWidget = tester.widget<SongCatalogPlaylistSection>(catalogFinder);
    expect(catalogWidget.axis, Axis.horizontal);

    // 2. Verifikasi Posisi Vertikal: Player di bagian atas layar
    final playerCenter = tester.getCenter(find.byType(PlayerDisplay));
    final searchCenter = tester.getCenter(find.text('hasil pencarian'));
    final playlistCenter = tester.getCenter(find.text('playlist'));

    expect(playerCenter.dy, lessThan(searchCenter.dy));
    expect(playerCenter.dy, lessThan(playlistCenter.dy));

    // 3. Verifikasi Posisi Horizontal pada bagian bawah: Cari lagu di kiri, Playlist di kanan
    expect(searchCenter.dx, lessThan(playlistCenter.dx));
  });
}
