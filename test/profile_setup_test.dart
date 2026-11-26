import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/fsm_controller.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/main.dart';
import 'package:qalbukids/screens/home_screen.dart';
import 'package:qalbukids/screens/profile_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder findAvatarAsset(String name) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image || widget.image is! AssetImage) return false;
    return (widget.image as AssetImage).assetName ==
        'assets/images/avatar_$name.png';
  });
}

Future<void> usePhoneSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> openProfileTab(WidgetTester tester) async {
  await tester.tap(find.text('Profil'));
  await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Putri  ');
    await tester.tap(find.text('Aisyah'));
    await tester.ensureVisible(find.text('Mulai Bertualang!'));
    await tester.tap(find.text('Mulai Bertualang!'));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hai, Naya!'), findsOneWidget);
    expect(findAvatarAsset('zaid'), findsOneWidget);
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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();
    await openProfileTab(tester);

    await tester.ensureVisible(find.text('Edit Nama & Karakter'));
    await tester.tap(find.text('Edit Nama & Karakter'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Naya');
    expect(findAvatarAsset('zaid'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Zahra');
    await tester.tap(find.text('Aisyah'));
    await tester.ensureVisible(find.text('Simpan Profil'));
    await tester.tap(find.text('Simpan Profil'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Zahra'), findsOneWidget);
    expect(findAvatarAsset('aisyah'), findsOneWidget);
    expect(await storage.getNama(), 'Zahra');
    expect(await storage.getAvatar(), 'aisyah');
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
    await storage.setStageStars(1, 1, 3);
    final states = await storage.getFsmStates();
    states[ProgressionFSM.stageKey(1, 1)] = LevelState.completed;
    states[ProgressionFSM.stageKey(1, 2)] = LevelState.unlocked;
    states[ProgressionFSM.badgeKey(1)] = LevelState.unlocked;
    await storage.saveFsmStates(states);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await openProfileTab(tester);

    await tester.ensureVisible(find.text('Reset Progres Tes'));
    await tester.tap(find.text('Reset Progres Tes'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Progres Tes'), findsNWidgets(2));

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(await storage.getNama(), 'Putri');
    expect(await storage.getAvatar(), 'aisyah');
    expect(await storage.isRegistered(), isTrue);
    expect(await storage.getTotalPoin(), 0);
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
    await tester.pumpAndSettle();
  });
}
