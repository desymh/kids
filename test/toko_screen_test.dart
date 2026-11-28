import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/screens/belajar_screen.dart';
import 'package:qalbukids/screens/home_screen.dart';
import 'package:qalbukids/screens/lencana_screen.dart';
import 'package:qalbukids/screens/peta_screen.dart';
import 'package:qalbukids/screens/settings_screen.dart';
import 'package:qalbukids/screens/toko_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpAnimatedFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

void expectWalletValue(WidgetTester tester, String key, String value) {
  expect(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.text(value),
    ),
    findsOneWidget,
  );
}

Container walletContainer(WidgetTester tester, String key) {
  return tester.widget<Container>(
    find
        .descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(Container),
        )
        .first,
  );
}

void expectMatchingWalletStyle(
  Container reference,
  Container candidate,
) {
  final referenceDecoration = reference.decoration! as BoxDecoration;
  final candidateDecoration = candidate.decoration! as BoxDecoration;

  expect(candidate.padding, reference.padding);
  expect(candidateDecoration.color, referenceDecoration.color);
  expect(candidateDecoration.borderRadius, referenceDecoration.borderRadius);
  expect(candidateDecoration.boxShadow, hasLength(1));
  expect(candidateDecoration.boxShadow!.single.color,
      referenceDecoration.boxShadow!.single.color);
  expect(candidateDecoration.boxShadow!.single.blurRadius,
      referenceDecoration.boxShadow!.single.blurRadius);
  expect(candidateDecoration.boxShadow!.single.offset,
      referenceDecoration.boxShadow!.single.offset);
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

    final background = tester.widget<Image>(
      find.byKey(const ValueKey('shop-background')),
    );
    expect(
      (background.image as AssetImage).assetName,
      'assets/images/bg_menu_utama.png',
    );
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

  testWidgets('shop uses compact left-locked packages without mascot',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(const MaterialApp(home: TokoScreen()));
    await pumpAnimatedFrames(tester);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/mascot_berdua.png',
      ),
      findsNothing,
    );
    final packageList = find.byKey(const ValueKey('shop-package-list'));
    expect(
      tester.widget<ListView>(packageList).scrollDirection,
      Axis.horizontal,
    );
    final backButton = find.byKey(const ValueKey('shop-back'));
    expect(backButton, findsOneWidget);
    expect(
      find.ancestor(
        of: backButton,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
      findsNothing,
    );
    final firstPackage = find.byKey(const ValueKey('shop-package-1'));
    final packageListRect = tester.getRect(packageList);
    final firstPackageRect = tester.getRect(firstPackage);
    final titleRect = tester.getRect(find.text('Toko Nyawa'));
    expect(
      firstPackageRect.left,
      closeTo(packageListRect.left + 20, 0.01),
    );
    expect(firstPackageRect.top, greaterThan(titleRect.bottom));
    expect(
      firstPackageRect.center.dy,
      closeTo(packageListRect.center.dy, 0.01),
    );
    final firstPackageSize = tester.getSize(firstPackage);
    expect(firstPackageSize.width, lessThanOrEqualTo(190));
    expect(firstPackageSize.height, lessThanOrEqualTo(270));

    final scrollable = find.descendant(
      of: packageList,
      matching: find.byType(Scrollable),
    );
    final scrollPosition = tester.state<ScrollableState>(scrollable).position;
    expect(scrollPosition.minScrollExtent, 0);
    expect(scrollPosition.pixels, 0);
    expect(scrollPosition.maxScrollExtent, greaterThan(0));
    await tester.drag(packageList, const Offset(300, 0));
    await pumpAnimatedFrames(tester);
    expect(scrollPosition.pixels, 0);

    await tester.drag(packageList, const Offset(-700, 0));
    await pumpAnimatedFrames(tester);

    expect(scrollPosition.pixels, greaterThan(0));
    expect(find.byKey(const ValueKey('shop-package-6')), findsOneWidget);
    expect(find.text('+20 ❤️ Nyawa'), findsOneWidget);
    expect(find.text('380 🪙 Koin'), findsOneWidget);
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

  testWidgets('all main menus show matching coin and life capsules',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      StorageService.keyKoin: 75,
      StorageService.keyNyawa: 2,
    });
    final storage = StorageService();
    await storage.init();

    final menus = <String, Widget>{
      'home': const HomeScreen(),
      'shop': const TokoScreen(),
      'belajar': const BelajarScreen(),
      'peta': const PetaScreen(),
      'lencana': const LencanaScreen(),
      'settings': const SettingsScreen(),
    };
    late Container homeCoins;
    late Container homeLives;

    for (final menu in menus.entries) {
      await tester.pumpWidget(MaterialApp(home: menu.value));
      await pumpAnimatedFrames(tester);

      final coinsKey = '${menu.key}-coins';
      final livesKey = '${menu.key}-lives';
      expectWalletValue(tester, coinsKey, '75');
      expectWalletValue(tester, livesKey, '2');
      expect(
        find.descendant(
          of: find.byKey(ValueKey(coinsKey)),
          matching: find.text('🪙'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey(livesKey)),
          matching: find.text('❤️'),
        ),
        findsOneWidget,
      );
      if (menu.key == 'home') {
        homeCoins = walletContainer(tester, coinsKey);
        homeLives = walletContainer(tester, livesKey);
      } else {
        expectMatchingWalletStyle(
          homeCoins,
          walletContainer(tester, coinsKey),
        );
        expectMatchingWalletStyle(
          homeLives,
          walletContainer(tester, livesKey),
        );
      }
      expect(tester.takeException(), isNull);
    }
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
