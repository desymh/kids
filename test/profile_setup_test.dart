import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/fsm_controller.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/main.dart';
import 'package:qalbukids/screens/belajar_screen.dart';
import 'package:qalbukids/screens/home_screen.dart';
import 'package:qalbukids/screens/lencana_screen.dart';
import 'package:qalbukids/screens/peta_screen.dart';
import 'package:qalbukids/screens/profile_setup_screen.dart';
import 'package:qalbukids/screens/toko_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder findImageAsset(String assetName) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image || widget.image is! AssetImage) return false;
    return (widget.image as AssetImage).assetName == assetName;
  });
}

Finder findAvatarAsset(String name) {
  return findImageAsset('assets/images/avatar_$name.png');
}

Future<void> usePhoneSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> useLandscapeSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(960, 540));
  tester.view.physicalSize = const Size(960, 540);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> openProfileTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('home-profile-capsule')));
  await pumpFrames(tester);
}

Future<void> pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('fresh users see setup and empty names are rejected',
      (tester) async {
    await usePhoneSize(tester);
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(
      QalbuKidsApp(initialRoute: await storage.isRegistered() ? '/home' : '/'),
    );
    await pumpFrames(tester);

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text("Assalamu'alaikum!"), findsOneWidget);
    expect(find.text('Kenalan dulu sebelum bertualang, yuk!'), findsOneWidget);
    expect(find.text('Pilih Karaktermu:'), findsOneWidget);

    await tester.ensureVisible(find.text('Mulai Bertualang!'));
    await tester.tap(find.text('Mulai Bertualang!'));
    await tester.pump();

    expect(find.text('Nama panggilan tidak boleh kosong.'), findsOneWidget);
    expect(await storage.isRegistered(), isFalse);
    expect(await storage.getNama(), isEmpty);
  });

  testWidgets('setup saves the profile and replaces itself with Home',
      (tester) async {
    await usePhoneSize(tester);
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(const MaterialApp(home: ProfileSetupScreen()));
    await pumpFrames(tester);

    await tester.enterText(find.byType(TextField), '  Putri  ');
    await tester.tap(find.text('Aisyah'));
    await tester.ensureVisible(find.text('Mulai Bertualang!'));
    await tester.tap(find.text('Mulai Bertualang!'));
    await pumpFrames(tester);

    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hai, Putri!'), findsOneWidget);
    expect(findAvatarAsset('aisyah'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(StorageService.keyNama), 'Putri');
    expect(preferences.getString(StorageService.keyAvatar), 'aisyah');
    expect(preferences.getBool(StorageService.keyRegistered), isTrue);
  });

  testWidgets('registered users start on Home', (tester) async {
    await usePhoneSize(tester);
    SharedPreferences.setMockInitialValues({
      StorageService.keyNama: 'Naya',
      StorageService.keyAvatar: 'zaid',
      StorageService.keyRegistered: true,
    });
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(
      QalbuKidsApp(initialRoute: await storage.isRegistered() ? '/home' : '/'),
    );
    await pumpFrames(tester);

    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hai, Naya!'), findsOneWidget);
    expect(findAvatarAsset('zaid'), findsOneWidget);
  });

  testWidgets('Home shows mosque background and four floating menu icons',
      (tester) async {
    await useLandscapeSize(tester);
    SharedPreferences.setMockInitialValues({
      StorageService.keyNama: 'Naya',
      StorageService.keyAvatar: 'zaid',
      StorageService.keyRegistered: true,
    });
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await pumpFrames(tester);

    expect(findAvatarAsset('zaid'), findsOneWidget);
    expect(
        findImageAsset('assets/images/bg_langit_masjid.png'), findsOneWidget);
    expect(
        findImageAsset('assets/images/icon_menu_belajar.png'), findsOneWidget);
    expect(
        findImageAsset('assets/images/icon_menu_bermain.png'), findsOneWidget);
    expect(findImageAsset('assets/images/icon_menu_koleksiku.png'),
        findsOneWidget);
    expect(findImageAsset('assets/images/icon_menu_toko.png'), findsOneWidget);
    expect(findImageAsset('assets/images/mascot_berdua.png'), findsNothing);
    expect(find.text("Assalamu'alaikum!"), findsNothing);
    expect(find.text('BELAJAR'), findsNothing);
    expect(find.text('BERMAIN'), findsNothing);
    expect(find.text('KOLEKSIKU'), findsNothing);
    expect(find.text('TOKO'), findsNothing);
    expect(find.text('Misi Harian'), findsNothing);
    expect(find.textContaining(RegExp(r'^Lanjut \d+%$')), findsNothing);
    expect(find.text('Beranda'), findsNothing);
    expect(find.text('Lencana'), findsNothing);
    expect(find.text('Profil'), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(Card), findsNothing);
    final menuRow = find.byKey(const ValueKey('home-menu-grid'));
    expect(
      tester.widget<Row>(menuRow).mainAxisAlignment,
      MainAxisAlignment.spaceEvenly,
    );
    expect(tester.getCenter(menuRow).dx, closeTo(480, 0.001));
    expect(
      tester.getSize(find.byKey(const ValueKey('menu-belajar'))).height,
      closeTo(216, 0.001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating menu icons preserve all four navigation destinations',
      (tester) async {
    await useLandscapeSize(tester);
    SharedPreferences.setMockInitialValues({
      StorageService.keyNama: 'Naya',
      StorageService.keyAvatar: 'zaid',
      StorageService.keyRegistered: true,
    });
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await pumpFrames(tester);

    final destinations = <String, Type>{
      'menu-belajar': BelajarScreen,
      'menu-bermain': PetaScreen,
      'menu-koleksiku': LencanaScreen,
      'menu-toko': TokoScreen,
    };
    for (final destination in destinations.entries) {
      await tester.tap(find.byKey(ValueKey(destination.key)));
      await pumpFrames(tester);
      expect(find.byType(destination.value), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await pumpFrames(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home and Profil display the same saved name and avatar',
      (tester) async {
    await usePhoneSize(tester);
    SharedPreferences.setMockInitialValues({
      StorageService.keyNama: 'Putri',
      StorageService.keyAvatar: 'aisyah',
      StorageService.keyRegistered: true,
    });
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await pumpFrames(tester);

    expect(find.text('Hai, Putri!'), findsOneWidget);
    expect(findAvatarAsset('aisyah'), findsOneWidget);

    await openProfileTab(tester);

    expect(find.text('Putri'), findsOneWidget);
    expect(findAvatarAsset('aisyah'), findsOneWidget);
    expect(find.text('Edit Nama & Karakter'), findsOneWidget);
    expect(find.text('Reset Progres Tes'), findsOneWidget);
  });

  testWidgets(
      'editing the profile refreshes Home without stacking another Home',
      (tester) async {
    await usePhoneSize(tester);
    SharedPreferences.setMockInitialValues({
      StorageService.keyNama: 'Naya',
      StorageService.keyAvatar: 'zaid',
      StorageService.keyRegistered: true,
    });
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await pumpFrames(tester);
    await openProfileTab(tester);

    await tester.ensureVisible(find.text('Edit Nama & Karakter'));
    await tester.tap(find.text('Edit Nama & Karakter'));
    await pumpFrames(tester);

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Naya');
    expect(findAvatarAsset('zaid'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Zahra');
    await tester.tap(find.text('Aisyah'));
    await tester.ensureVisible(find.text('Simpan Profil'));
    await tester.tap(find.text('Simpan Profil'));
    await pumpFrames(tester);

    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hai, Zahra!'), findsOneWidget);
    expect(findAvatarAsset('aisyah'), findsOneWidget);
    expect(await storage.getNama(), 'Zahra');
    expect(await storage.getAvatar(), 'aisyah');
  });

  testWidgets('profile setup uses two columns in landscape', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: ProfileSetupScreen()));
    await pumpFrames(tester);

    final welcome = find.text("Assalamu'alaikum!");
    final nameField = find.byType(TextField);
    expect(welcome, findsOneWidget);
    expect(nameField, findsOneWidget);
    expect(
        tester.getCenter(welcome).dx, lessThan(tester.getCenter(nameField).dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset clears test progress but preserves the profile',
      (tester) async {
    await usePhoneSize(tester);
    final storage = StorageService();
    await storage.init();
    await storage.setNama('Putri');
    await storage.setAvatar('aisyah');
    await storage.setRegistered(true);
    await storage.setTotalPoin(160);
    await storage.setNyawa(0);
    await storage.setStageStars(1, 1, 3);
    final states = await storage.getFsmStates();
    states[ProgressionFSM.stageKey(1, 1)] = LevelState.completed;
    states[ProgressionFSM.stageKey(1, 2)] = LevelState.unlocked;
    states[ProgressionFSM.badgeKey(1)] = LevelState.unlocked;
    await storage.saveFsmStates(states);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await pumpFrames(tester);
    await openProfileTab(tester);

    await tester.ensureVisible(find.text('Reset Progres Tes'));
    await tester.tap(find.text('Reset Progres Tes'));
    await pumpFrames(tester);
    expect(find.text('Reset Progres Tes'), findsNWidgets(2));

    await tester.tap(find.text('Reset'));
    await pumpFrames(tester);

    expect(await storage.getNama(), 'Putri');
    expect(await storage.getAvatar(), 'aisyah');
    expect(await storage.isRegistered(), isTrue);
    expect(await storage.getTotalPoin(), 0);
    expect(await storage.getNyawa(), StorageService.defaultNyawa);
    expect(await storage.getTotalBintang(), 0);
    expect(await storage.getStageStars(1, 1), 0);
    expect(
      await storage.getLevelState(ProgressionFSM.stageKey(1, 1)),
      LevelState.unlocked,
    );
    expect(
      await storage.getLevelState(ProgressionFSM.stageKey(1, 2)),
      LevelState.locked,
    );
    expect((await storage.getLencana()).first, isFalse);
    expect(find.text('Putri'), findsOneWidget);
    expect(findAvatarAsset('aisyah'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await pumpFrames(tester);
  });
}
