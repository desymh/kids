import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/fsm_controller.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/data/bank_soal.dart';
import 'package:qalbukids/screens/home_screen.dart';
import 'package:qalbukids/screens/kuis_ujian_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> answerCurrentQuestion(
  WidgetTester tester, {
  required bool correct,
}) async {
  final question = BankSoal.bank.firstWhere(
    (item) => find.text(item['pertanyaan'] as String).evaluate().isNotEmpty,
  );
  final options = (question['opsi'] as List).cast<String>();
  final correctAnswer = options[question['jawabanBenar'] as int];
  final answer = correct
      ? correctAnswer
      : options.firstWhere((option) => option != correctAnswer);

  await tester.tap(find.text(answer));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> finishPassedQuiz(WidgetTester tester) async {
  expect(find.text('LULUS!'), findsOneWidget);
  await tester.tap(find.text('Lihat Pembukaan'));
  await tester.pumpAndSettle();
  expect(find.text('Pembukaan Baru!'), findsOneWidget);
  await tester.tap(find.text('Kembali ke Tahapan'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      StorageService.keyNama: 'Naya',
      StorageService.keyAvatar: 'aisyah',
    });
    storage = StorageService();
    await storage.init();
  });

  testWidgets('Pulau 1 is playable from home through Badge 1 unlock', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Hai, Naya!'), findsOneWidget);
    expect(find.text('Lanjutkan: Pulau 1 - Tahap 1 (Pondasi Islam)'), findsOneWidget);

    await tester.ensureVisible(find.text('GAME UJIAN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GAME UJIAN'));
    await tester.pumpAndSettle();

    expect(find.text('Peta Petualangan'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(5));
    await tester.tap(find.text('Pulau 1: Pondasi Islam'));
    await tester.pumpAndSettle();

    for (var tahap = 1; tahap <= 4; tahap++) {
      await tester.tap(find.text('Tahap $tahap: ${[
        'Pemula',
        'Dasar',
        'Lanjutan',
        'Ujian Pulau',
      ][tahap - 1]}'));
      await tester.pumpAndSettle();

      expect(find.text('Kuis Pulau 1 - Tahap $tahap'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNWidgets(3));
      expect(find.text('30 s'), findsOneWidget);

      for (var question = 0; question < 4; question++) {
        await answerCurrentQuestion(tester, correct: true);
      }

      if (tahap == 4) {
        expect(find.text('LULUS!'), findsOneWidget);
        await tester.tap(find.text('Lihat Pembukaan'));
        await tester.pumpAndSettle();
        expect(find.text('Pulau 2 (Thaharah) telah terbuka.'), findsOneWidget);
        expect(find.text('Lencana Duta Rukun Islam telah terbuka.'), findsOneWidget);
        await tester.tap(find.text('Kembali ke Tahapan'));
        await tester.pumpAndSettle();
      } else {
        await finishPassedQuiz(tester);
      }

      expect(
        await storage.getLevelState(ProgressionFSM.stageKey(1, tahap)),
        LevelState.completed,
      );
    }

    expect(find.textContaining('Selesai · 3/3 bintang'), findsNWidgets(4));
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Peta Petualangan'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(4));
    expect(
      await storage.getLevelState(ProgressionFSM.islandKey(1)),
      LevelState.completed,
    );
    expect(
      await storage.getLevelState(ProgressionFSM.islandKey(2)),
      LevelState.unlocked,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Hai, Naya!'), findsOneWidget);
    expect(find.text('160'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Lanjutkan: Pulau 2 - Tahap 1 (Thaharah)'), findsOneWidget);
    expect((await storage.getLencana()).first, isTrue);

    await tester.tap(find.text('Lencana'));
    await tester.pumpAndSettle();
    expect(find.text('1/6'), findsOneWidget);

    final firstBadge = find.text('Duta Rukun\nIslam');
    final firstBadgeOpacity = find.ancestor(
      of: firstBadge,
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(firstBadgeOpacity).opacity, 1.0);
  });

  testWidgets('wrong answers consume hearts and do not unlock the next stage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KuisUjianScreen(pulauId: 1, tahap: 1),
      ),
    );
    await tester.pumpAndSettle();

    for (var answer = 0; answer < 3; answer++) {
      await answerCurrentQuestion(tester, correct: false);
    }

    expect(find.text('BELUM LULUS'), findsOneWidget);
    expect(
      await storage.getLevelState(ProgressionFSM.stageKey(1, 2)),
      LevelState.locked,
    );
    expect(await storage.getTotalPoin(), 0);
    expect(await storage.getTotalBintang(), 0);
  });
}
