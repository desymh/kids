import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/fsm/adventure_fsm.dart';
import 'package:qalbukids/core/fsm_controller.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/data/bank_soal.dart';
import 'package:qalbukids/game/qalbukids_adventure_game.dart';
import 'package:qalbukids/screens/adventure_screen.dart';
import 'package:qalbukids/screens/daily_quiz_screen.dart';
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

  await tester.tap(find.widgetWithText(ElevatedButton, answer));
  await tester.pump();
}

Future<void> openScreenFromLauncher(
  WidgetTester tester,
  Widget screen,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screen),
            ),
            child: const Text('Buka Aktivitas'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka Aktivitas'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> pumpHomeFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> openAdventureExam(WidgetTester tester) async {
  late QalbuKidsAdventureGame game;
  await tester.tap(find.text('Pulau 1: Pondasi Islam'));
  await tester.runAsync(() async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AdventureScreen), findsOneWidget);

    final gameFinder = find.byWidgetPredicate((widget) => widget is GameWidget);
    final gameWidget = tester.widget<GameWidget>(gameFinder);
    game = gameWidget.game as QalbuKidsAdventureGame;
    await Future<void>.sync(() => game.toBeLoaded())
        .timeout(const Duration(seconds: 5));
    await tester.pump();
  });
  expect(game.isLoaded, isTrue);

  game.pauseEngine();
  game.player.position.x = game.guardian.position.x -
      QalbuKidsAdventureGame.guardianCollisionDistance;
  game.update(0);
  expect(game.fsm.gateState, GateState.quizActive);

  tester.binding.scheduleFrame();
  await tester.pumpAndSettle(
    const Duration(milliseconds: 16),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 2),
  );
  expect(find.byType(AdventureQuizDialog), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StorageService storage;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            SystemChannels.platform, (call) async => null);
    SharedPreferences.setMockInitialValues({
      StorageService.keyNama: 'Naya',
      StorageService.keyAvatar: 'aisyah',
    });
    storage = StorageService();
    await storage.init();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('Pulau 1 is playable from home through Badge 1 unlock',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await pumpHomeFrames(tester);

    expect(find.text('Hai, Naya!'), findsOneWidget);
    expect(find.text('Ayo belajar & bertualang!'), findsOneWidget);
    expect(find.text('🏅 0 / 6 Lencana'), findsNothing);
    expect(find.textContaining('bintang'), findsNothing);
    expect(find.byKey(const ValueKey('menu-bermain')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('menu-bermain')));
    await pumpHomeFrames(tester);
    await tester.tap(find.byKey(const ValueKey('menu-bermain')));
    await tester.pumpAndSettle();

    expect(find.text('Peta Petualangan'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(5));
    await openAdventureExam(tester);

    for (var question = 0; question < 9; question++) {
      await tapCurrentAnswer(tester, correct: true);
      await tester.pumpAndSettle();
      expect(find.text('✨ MasyaAllah, Benar! +1 ❤️ Nyawa'), findsOneWidget);
      await tester.tap(find.text(question == 8 ? 'Lihat Hasil' : 'Lanjut'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Bintang Pulau: 3/3'), findsOneWidget);
    expect(
      find.text(
          '🏆 LUAR BIASA! 9/9 Benar Sempurna! Piala Penghargaan Pulau 1 Terbuka!'),
      findsOneWidget,
    );
    await tester.tap(find.text('Buka Gerbang'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('adventure-perfect-trophy-dialog')),
        findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('adventure-island-success-notification')),
      findsOneWidget,
    );
    expect(find.text('Berhasil! Pulau 1 selesai!'), findsOneWidget);
    expect(find.textContaining('Duta Pondasi Islam terbuka.'), findsOneWidget);
    expect(find.textContaining('Gerbang terbuka! Masuk ke Pulau 2'),
        findsOneWidget);
    expect(
        find.widgetWithText(ElevatedButton, 'Lanjut ke Pulau 2'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final nextAdventure =
        tester.widget<AdventureScreen>(find.byType(AdventureScreen));
    expect(nextAdventure.pulauId, 2);
    expect(nextAdventure.namaPulau, 'Thaharah');
    expect(
      await storage.getLevelState(ProgressionFSM.islandKey(1)),
      LevelState.completed,
    );
    expect(
      await storage.getLevelState(ProgressionFSM.islandKey(2)),
      LevelState.unlocked,
    );

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Peta Petualangan'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(4));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await pumpHomeFrames(tester);

    expect(find.text('Hai, Naya!'), findsOneWidget);
    expect(find.text('Ayo belajar & bertualang!'), findsOneWidget);
    expect(find.text('🏅 1 / 6 Lencana'), findsNothing);
    expect(find.textContaining('bintang'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-lives')),
        matching: find.text('14'),
      ),
      findsOneWidget,
    );
    expect(await storage.getNyawa(), 14);
    expect((await storage.getLencana()).first, isTrue);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('lencana_1'), isTrue);
    expect(preferences.getBool('pulau_2_unlocked'), isTrue);

    await tester.tap(find.byKey(const ValueKey('menu-koleksiku')));
    await pumpHomeFrames(tester);
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

  testWidgets('quiz rewards correct answers and persists cumulative lives',
      (tester) async {
    await storage.setTotalPoin(0);
    await tester.pumpWidget(
      const MaterialApp(
        home: KuisUjianScreen(pulauId: 1, tahap: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    const answers = [true, false, false, false, false];
    const expectedLives = [6, 5, 4, 3, 2];
    for (var answer = 0; answer < answers.length; answer++) {
      await tapCurrentAnswer(tester, correct: answers[answer]);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('quiz-lives')),
          matching: find.text('${expectedLives[answer]}'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          answers[answer]
              ? '✨ MasyaAllah, Benar! +1 ❤️ Nyawa'
              : '❌ Kurang Tepat! -1 ❤️ Nyawa',
        ),
        findsOneWidget,
      );
      expect(await storage.getNyawa(), expectedLives[answer]);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    expect(find.text('BELUM LULUS'), findsOneWidget);
    expect(find.textContaining('Nyawa: 2'), findsOneWidget);
    expect(find.textContaining('Bintang:'), findsNothing);
    expect(
      await storage.getLevelState(ProgressionFSM.stageKey(1, 2)),
      LevelState.locked,
    );
    expect(await storage.getTotalPoin(), 0);
    expect(await storage.getTotalBintang(), 0);
  });

  testWidgets('quiz fails immediately when the last life is lost',
      (tester) async {
    await storage.setNyawa(1);
    await tester.pumpWidget(
      const MaterialApp(
        home: KuisUjianScreen(pulauId: 1, tahap: 1),
      ),
    );
    await tester.pumpAndSettle();

    await tapCurrentAnswer(tester, correct: false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    const message =
        'Nyawamu habis (0 ❤️)! Yuk baca materi di Menu Belajar atau selesaikan Simulasi Praktik untuk menambah nyawa.';
    expect(find.text('BELUM LULUS'), findsOneWidget);
    expect(find.textContaining(message), findsOneWidget);
    expect(find.textContaining('Nyawa: 0'), findsOneWidget);
    expect(await storage.getNyawa(), 0);
    expect(
      await storage.getLevelState(ProgressionFSM.stageKey(1, 2)),
      LevelState.locked,
    );
  });

  testWidgets('quiz and daily mission block entry when lives are empty',
      (tester) async {
    await storage.setNyawa(0);
    const message =
        'Nyawamu habis (0 ❤️)! Yuk baca materi di Menu Belajar atau selesaikan Simulasi Praktik untuk menambah nyawa.';

    for (final screen in <Widget>[
      const KuisUjianScreen(pulauId: 1, tahap: 1),
      const DailyQuizScreen(),
    ]) {
      await openScreenFromLauncher(tester, screen);
      expect(find.text(message), findsOneWidget);
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Buka Aktivitas'), findsOneWidget);
      expect(await storage.getNyawa(), 0);
    }
  });

  testWidgets('daily mission deducts a shared life without awarding points',
      (tester) async {
    await storage.setTotalPoin(7);
    await storage.setNyawa(2);
    await tester.pumpWidget(const MaterialApp(home: DailyQuizScreen()));
    await tester.pumpAndSettle();

    await tapCurrentAnswer(tester, correct: false);
    await tester.pumpAndSettle();

    expect(find.text('❌ Jawaban kurang tepat! -1 ❤️ Nyawa'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('daily-lives')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(await storage.getNyawa(), 1);
    expect(await storage.getTotalPoin(), 7);
  });

  testWidgets('daily mission adds three cumulative lives without points',
      (tester) async {
    await storage.setTotalPoin(7);
    await storage.setNyawa(2);
    await tester.pumpWidget(const MaterialApp(home: DailyQuizScreen()));
    await tester.pumpAndSettle();

    await tapCurrentAnswer(tester, correct: true);
    await tester.pumpAndSettle();

    expect(find.text('🎉 Misi Harian Berhasil! +3 ❤️ Nyawa'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('daily-lives')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
    expect(await storage.getNyawa(), 5);
    expect(await storage.getTotalPoin(), 7);
  });

  testWidgets(
      'Home refreshes lives after learning and simulation routes return',
      (tester) async {
    await storage.setNyawa(1);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await pumpHomeFrames(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-lives')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('menu-belajar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SIMULASI PRAKTIK'));
    await tester.pumpAndSettle();
    await storage.tambahNyawa(2);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await pumpHomeFrames(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-lives')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('menu-belajar')));
    await tester.pumpAndSettle();
    await storage.tambahNyawa(2);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await pumpHomeFrames(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-lives')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
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
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
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
