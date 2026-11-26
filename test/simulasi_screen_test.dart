import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/screens/simulasi_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wudhuIds = [
  'niat',
  'telapak_tangan',
  'berkumur',
  'hidung',
  'muka',
  'tangan',
  'kepala',
  'telinga',
  'kaki',
];

const _shalatIds = [
  'takbir',
  'sedekap',
  'rukuk',
  'itidal',
  'sujud',
  'duduk_sujud',
  'tahiyat',
  'salam',
];

Future<void> _setLandscapeSize(
  WidgetTester tester, {
  required Size size,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpSimulator(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SimulasiScreen()));
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byKey(ValueKey('simulasi-card-$id'));

Future<void> _completeSequence(WidgetTester tester, List<String> ids) async {
  for (final id in ids) {
    await tester.tap(_card(id));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rejects an incorrect Wudhu order without consuming a life',
      (tester) async {
    SharedPreferences.setMockInitialValues({StorageService.keyNyawa: 3});
    await _setLandscapeSize(tester, size: const Size(640, 360));
    await _pumpSimulator(tester);

    expect(find.text('Simulasi Wudhu (9 Langkah)'), findsOneWidget);
    expect(find.text('Simulasi Shalat (8 Langkah)'), findsOneWidget);
    expect(
      find.text('Ketuk kartu langkah ke-1 untuk memulai!'),
      findsOneWidget,
    );
    for (final id in _wudhuIds) {
      expect(_card(id), findsOneWidget);
    }

    await tester.tap(_card('telapak_tangan'));
    await tester.pump();

    expect(
      find.text(
          '❌ Urutan keliru! Ibadah harus dilakukan secara tertib (berurutan).'),
      findsOneWidget,
    );
    expect(find.text('0 / 9 langkah'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt(StorageService.keyNyawa), 3);

    await tester.tap(_card('niat'));
    await tester.pump();

    expect(find.text('✅ Tepat! Langkah ke-1 benar!'), findsOneWidget);
    expect(find.text('1 / 9 langkah'), findsOneWidget);
    expect(
      find.descendant(of: _card('niat'), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(preferences.getInt(StorageService.keyNyawa), 3);
  });

  testWidgets('completes Wudhu, refills two lives once per run, and replays',
      (tester) async {
    SharedPreferences.setMockInitialValues({StorageService.keyNyawa: 2});
    await _setLandscapeSize(tester, size: const Size(640, 360));
    await _pumpSimulator(tester);

    await _completeSequence(tester, _wudhuIds);

    expect(
      find.text('🎉 Alhamdulillah! +2 ❤️ Nyawa ditambahkan!'),
      findsOneWidget,
    );
    expect(find.text('Ulangi Praktik'), findsWidgets);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt(StorageService.keyNyawa), 4);

    await tester.tap(find.text('Ulangi Praktik').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Ketuk kartu langkah ke-1 untuk memulai!'),
      findsOneWidget,
    );
    expect(find.text('0 / 9 langkah'), findsOneWidget);
    expect(preferences.getInt(StorageService.keyNyawa), 4);

    await _completeSequence(tester, _wudhuIds);
    expect(
      find.text('🎉 Alhamdulillah! +2 ❤️ Nyawa ditambahkan!'),
      findsOneWidget,
    );
    expect(preferences.getInt(StorageService.keyNyawa), 6);
  });

  testWidgets('switches to Shalat and completes all eight ordered steps',
      (tester) async {
    SharedPreferences.setMockInitialValues({StorageService.keyNyawa: 1});
    await _setLandscapeSize(tester, size: const Size(854, 412));
    await _pumpSimulator(tester);

    await tester.tap(find.byKey(const ValueKey('simulasi-mode-shalat')));
    await tester.pumpAndSettle();

    expect(find.text('0 / 8 langkah'), findsOneWidget);
    expect(_card('niat'), findsNothing);
    for (final id in _shalatIds) {
      expect(_card(id), findsOneWidget);
    }

    await _completeSequence(tester, _shalatIds);

    expect(
      find.text('🎉 Alhamdulillah! +2 ❤️ Nyawa ditambahkan!'),
      findsOneWidget,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt(StorageService.keyNyawa), 3);
  });
}
