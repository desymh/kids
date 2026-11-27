import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/screens/belajar_screen.dart';
import 'package:qalbukids/screens/home_screen.dart';
import 'package:qalbukids/screens/toko_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpAnimatedFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shop displays packages and exchanges coins for lives',
      (tester) async {
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(const MaterialApp(home: TokoScreen()));
    await pumpAnimatedFrames(tester);

    expect(find.text('+1 ❤️ Nyawa'), findsOneWidget);
    expect(find.text('30 🪙 Koin'), findsOneWidget);
    expect(find.text('+3 ❤️ Nyawa'), findsOneWidget);
    expect(find.text('80 🪙 Koin'), findsOneWidget);
    expect(find.text('Hemat!'), findsOneWidget);
    expect(find.text('+5 ❤️ Nyawa'), findsOneWidget);
    expect(find.text('120 🪙 Koin'), findsOneWidget);
    expect(find.text('Favorit!'), findsOneWidget);

    final firstPackage = find.byKey(const ValueKey('shop-package-1'));
    await tester.tap(
      find.descendant(of: firstPackage, matching: find.text('Tukar')),
    );
    await pumpAnimatedFrames(tester);

    expect(find.text('🎉 Berhasil membeli Nyawa!'), findsOneWidget);
    expect(await storage.getKoin(), 20);
    expect(await storage.getNyawa(), 6);

    await tester.tap(find.text('Mantap!'));
    await pumpAnimatedFrames(tester);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('shop-coins')),
        matching: find.text('20'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('shop-lives')),
        matching: find.text('6'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shop rejects purchases when coins are insufficient',
      (tester) async {
    final storage = StorageService();
    await storage.init();
    await storage.setKoin(20);
    await storage.setNyawa(1);

    await tester.pumpWidget(const MaterialApp(home: TokoScreen()));
    await pumpAnimatedFrames(tester);

    final secondPackage = find.byKey(const ValueKey('shop-package-2'));
    await tester.tap(
      find.descendant(of: secondPackage, matching: find.text('Tukar')),
    );
    await pumpAnimatedFrames(tester);

    expect(
      find.text(
        'Koinmu belum cukup! Yuk main petualangan dan kumpulkan koin dulu 🪙',
      ),
      findsOneWidget,
    );
    expect(await storage.getKoin(), 20);
    expect(await storage.getNyawa(), 1);
  });

  testWidgets('floating lobby opens shop and learning with simulation',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      StorageService.keyNama: 'Naya',
      StorageService.keyAvatar: 'aisyah',
      StorageService.keyRegistered: true,
      StorageService.keyKoin: 75,
      StorageService.keyNyawa: 2,
    });
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await pumpAnimatedFrames(tester);

    expect(find.text('Hai, Naya!'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-belajar')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-bermain')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-koleksiku')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-toko')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-coins')),
        matching: find.text('75'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-lives')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('menu-toko')));
    await pumpAnimatedFrames(tester);
    expect(find.byType(TokoScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await pumpAnimatedFrames(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('menu-belajar')));
    await pumpAnimatedFrames(tester);
    expect(find.byType(BelajarScreen), findsOneWidget);
    expect(find.text('SIMULASI PRAKTIK'), findsOneWidget);
  });
}
