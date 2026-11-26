import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/fsm_controller.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/data/bank_soal.dart';
import 'package:qalbukids/screens/home_screen.dart';
import 'package:qalbukids/screens/kuis_ujian_screen.dart';
import 'package:qalbukids/screens/lencana_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> tapCurrentAnswer(
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
}

Future<void> answerCurrentQuestion(
  WidgetTester tester, {
  required bool correct,
}) async {
  await tapCurrentAnswer(tester, correct: correct);
  expect(
    find.text(
      correct
          ? '✨ MasyaAllah, Benar! +10 Poin'
          : '❌ Kurang Tepat! -5 Poin & -1 Nyawa',
    ),
    findsOneWidget,
  );
  expect(find.byKey(const ValueKey('quiz-feedback-banner')), findsOneWidget);
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

  testWidgets('Pulau 1 is playable from home through Badge 1 unlock',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Hai, Naya!'), findsOneWidget);
    expect(find.text('Lanjutkan: Pulau 1 - Tahap 1 (Pondasi Islam)'),
        findsOneWidget);

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

      for (var question = 0; question < 5; question++) {
        await answerCurrentQuestion(tester, correct: true);
      }

      if (tahap == 4) {
        expect(find.text('LULUS!'), findsOneWidget);
        await tester.tap(find.text('Lihat Pembukaan'));
        await tester.pumpAndSettle();
        expect(
          find.text('🎉 SELAMAT! LENCANA BARU TERBUKA! 🎉'),
          findsOneWidget,
        );
        expect(find.text('Duta Pondasi Islam'), findsOneWidget);
        expect(
          find.text(
            'Hebat! Kamu telah menamatkan Pulau 1 dan membuka Pulau 2!',
          ),
          findsOneWidget,
        );
        expect(find.byType(Image), findsOneWidget);
        await tester.tap(find.text('Klaim Lencana & Lanjut'));
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
    expect(find.text('200'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(
        find.text('Lanjutkan: Pulau 2 - Tahap 1 (Thaharah)'), findsOneWidget);
    expect((await storage.getLencana()).first, isTrue);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('lencana_1'), isTrue);
    expect(preferences.getBool('pulau_2_unlocked'), isTrue);

    await tester.tap(find.text('Lencana'));
    await tester.pumpAndSettle();
    expect(find.text('1/6'), findsOneWidget);
    expect(find.text('TERBUKA'), findsOneWidget);

    final firstBadge = find.byKey(const ValueKey('badge-card-1'));
    final firstBadgeOpacity = find.ancestor(
      of: firstBadge,
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(firstBadgeOpacity).opacity, 1.0);
    expect(
      tester.widget<InkWell>(firstBadge).onTap,
      isNotNull,
    );
  });

  testWidgets('session points update instantly and never fall below zero',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KuisUjianScreen(pulauId: 1, tahap: 1),
      ),
    );
    await tester.pumpAndSettle();

    const answers = [true, false, false, false];
    const expectedPoints = [10, 5, 0, 0];
    for (var answer = 0; answer < answers.length; answer++) {
      await tapCurrentAnswer(tester, correct: answers[answer]);
      expect(find.text('${expectedPoints[answer]} Poin'), findsOneWidget);
      expect(
        find.text(
          answers[answer]
              ? '✨ MasyaAllah, Benar! +10 Poin'
              : '❌ Kurang Tepat! -5 Poin & -1 Nyawa',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    expect(find.text('BELUM LULUS'), findsOneWidget);
    expect(find.textContaining('Nyawa: 0'), findsOneWidget);
    expect(
      await storage.getLevelState(ProgressionFSM.stageKey(1, 2)),
      LevelState.locked,
    );
    expect(await storage.getTotalPoin(), 0);
    expect(await storage.getTotalBintang(), 0);
  });

  testWidgets('badge collection refreshes states and opens earned details',
      (tester) async {
    await storage.setLencana([true, false, true, false, false, false]);
    final lencanaKey = GlobalKey<LencanaScreenState>();
    await tester.pumpWidget(
      MaterialApp(home: LencanaScreen(key: lencanaKey)),
    );
    await tester.pumpAndSettle();

    expect(find.text('2/6'), findsOneWidget);
    expect(find.text('TERBUKA'), findsNWidgets(2));
    expect(find.text('Tamatkan Pulau 2 untuk membuka'), findsOneWidget);
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('badge-card-2'))).onTap,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('badge-card-1')));
    await tester.pumpAndSettle();
    expect(find.text('Penghargaan Pulau 1'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    await storage.setLencana([true, true, true, false, false, false]);
    await lencanaKey.currentState!.refresh();
    await tester.pumpAndSettle();

    expect(find.text('3/6'), findsOneWidget);
    expect(find.text('TERBUKA'), findsNWidgets(3));
    expect(find.text('Tamatkan Pulau 2 untuk membuka'), findsNothing);
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('badge-card-2'))).onTap,
      isNotNull,
    );
  });
}
