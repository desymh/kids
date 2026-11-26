import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/fisher_yates_shuffle.dart';
import 'package:qalbukids/core/fsm_controller.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/data/bank_soal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FisherYatesShuffler', () {
    test('deduplicates questions and options while preserving correct answers',
        () {
      final source = <Map<String, dynamic>>[
        {
          'id': 'a',
          'pertanyaan': 'Pertanyaan A',
          'opsi': ['Benar', 'Salah', 'Benar', 'Lain', 'Lain 2'],
          'jawabanBenar': 0,
        },
        {
          'id': 'a',
          'pertanyaan': 'Duplikat',
          'opsi': ['1', '2', '3', '4'],
          'jawabanBenar': 1,
        },
        {
          'id': 'b',
          'pertanyaan': 'Pertanyaan B',
          'opsi': ['1', '2', '3', '4'],
          'jawabanBenar': 2,
        },
      ];

      final result =
          FisherYatesShuffler.acakDaftarSoal(source, random: Random(7));

      expect(result, hasLength(2));
      expect(result.map((question) => question['id']),
          unorderedEquals(['a', 'b']));
      for (final question in result) {
        final original =
            source.firstWhere((item) => item['id'] == question['id']);
        final options = (question['opsi'] as List).cast<String>();
        expect(options, hasLength(4));
        expect(options.toSet(), hasLength(4));
        expect(
          options[question['jawabanBenar'] as int],
          (original['opsi'] as List)[original['jawabanBenar'] as int],
        );
      }
      expect(
          source.first['opsi'], ['Benar', 'Salah', 'Benar', 'Lain', 'Lain 2']);
    });

    test('all six islands provide valid shuffled question pools', () {
      for (var pulau = 1; pulau <= StorageService.totalIslands; pulau++) {
        final expectedStageCount = pulau == 6 ? 8 : 5;
        for (var tahap = 1; tahap <= StorageService.stagesPerIsland; tahap++) {
          final questions = BankSoal.getSoalTahap(pulau, tahap);
          expect(questions, hasLength(expectedStageCount));
          expect(
            questions.map((question) => question['id'].toString()).toSet(),
            hasLength(expectedStageCount),
          );
          for (final question in questions) {
            final options = (question['opsi'] as List).cast<String>();
            expect(options, hasLength(4));
            expect(options.toSet(), hasLength(4));
            expect(question['jawabanBenar'], inInclusiveRange(0, 3));
            if (pulau == 6) {
              expect(question['pulauId'], inInclusiveRange(1, 5));
            } else {
              expect(question['pulauId'], pulau);
              expect(question['tahap'], tahap);
            }
          }
        }

        final islandQuestions = BankSoal.getSoalPulau(pulau);
        expect(islandQuestions, hasLength(pulau == 6 ? 8 : 6));
        expect(
          islandQuestions.map((question) => question['id'].toString()).toSet(),
          hasLength(islandQuestions.length),
        );
      }
    });

    test('badge labels match the six island awards', () {
      expect(
        BankSoal.badgeNames.map((name) => name.replaceAll('\n', ' ')),
        [
          'Duta Pondasi Islam',
          'Ahli Thaharah & Bersuci',
          'Santri Taat Shalat',
          'Pejuang Puasa Ramadhan',
          'Anak Shalih & Beradab',
          'Santri Cilik Teladan',
        ],
      );
    });
  });

  group('ProgressionFSM', () {
    test('requires score 60 and at least one life', () {
      final fsm = ProgressionFSM(initialStates: {
        ProgressionFSM.islandKey(1): LevelState.unlocked,
        ProgressionFSM.stageKey(1, 1): LevelState.unlocked,
      });

      expect(
        fsm.completeStage(pulauId: 1, tahap: 1, skor: 59, nyawa: 3).passed,
        isFalse,
      );
      expect(
        fsm.completeStage(pulauId: 1, tahap: 1, skor: 60, nyawa: 0).passed,
        isFalse,
      );
      expect(fsm.getState(ProgressionFSM.stageKey(1, 2)), LevelState.locked);
    });

    test('completes Pulau 1 and unlocks Pulau 2 with Badge 1', () {
      final fsm = ProgressionFSM(initialStates: {
        ProgressionFSM.islandKey(1): LevelState.unlocked,
        ProgressionFSM.stageKey(1, 1): LevelState.unlocked,
      });

      for (var tahap = 1; tahap <= 4; tahap++) {
        final result = fsm.completeStage(
          pulauId: 1,
          tahap: tahap,
          skor: 75,
          nyawa: 3,
        );
        expect(result.passed, isTrue);
        expect(fsm.getState(ProgressionFSM.stageKey(1, tahap)),
            LevelState.completed);
        if (tahap < 4) {
          expect(result.nextStageUnlocked, isTrue);
          expect(fsm.getState(ProgressionFSM.stageKey(1, tahap + 1)),
              LevelState.unlocked);
        }
      }

      expect(fsm.getState(ProgressionFSM.islandKey(1)), LevelState.completed);
      expect(fsm.getState(ProgressionFSM.islandKey(2)), LevelState.unlocked);
      expect(fsm.getState(ProgressionFSM.stageKey(2, 1)), LevelState.unlocked);
      expect(fsm.getState(ProgressionFSM.badgeKey(1)), LevelState.unlocked);
      expect(fsm.getState(ProgressionFSM.badgeKey(2)), LevelState.locked);
    });

    test('does not complete a locked stage', () {
      final fsm = ProgressionFSM(initialStates: {
        ProgressionFSM.islandKey(1): LevelState.unlocked,
      });

      final result = fsm.completeStage(
        pulauId: 1,
        tahap: 1,
        skor: 100,
        nyawa: 3,
      );

      expect(result.passed, isFalse);
      expect(fsm.getState(ProgressionFSM.stageKey(1, 1)), LevelState.locked);
    });
  });

  group('StorageService', () {
    test('migrates legacy profile, points, stars, states, and badges',
        () async {
      SharedPreferences.setMockInitialValues({
        'nama': 'Naya',
        'avatar': 'Aisyah',
        'poin': 40,
        'bintang': 7,
        'lencana_1': true,
        'pulau_1_tahap_1_completed': true,
        'pulau_1_tahap_2_unlocked': true,
      });
      final storage = StorageService();

      await storage.init();

      expect(await storage.getNama(), 'Naya');
      expect(await storage.getAvatar(), 'aisyah');
      expect(await storage.getTotalPoin(), 40);
      expect(await storage.getTotalBintang(), 7);
      expect(await storage.getLevelState(ProgressionFSM.stageKey(1, 1)),
          LevelState.completed);
      expect(await storage.getLevelState(ProgressionFSM.stageKey(1, 2)),
          LevelState.unlocked);
      expect((await storage.getLencana()).first, isTrue);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(StorageService.keyNama), 'Naya');
      expect(preferences.getString(StorageService.keyAvatar), 'aisyah');
      expect(await storage.isRegistered(), isTrue);
      expect(preferences.getBool(StorageService.keyRegistered), isTrue);
      expect(preferences.getInt(StorageService.keyTotalPoin), 40);
      expect(preferences.getInt(StorageService.keyTotalBintang), 7);
    });

    test('migrates boolean progression keys without type cast crashes',
        () async {
      SharedPreferences.setMockInitialValues({
        ProgressionFSM.islandKey(1): true,
        ProgressionFSM.stageKey(1, 1): true,
        ProgressionFSM.islandKey(2): false,
        ProgressionFSM.badgeKey(1): true,
        ProgressionFSM.badgeKey(2): false,
      });
      final storage = StorageService();

      await storage.init();

      expect(await storage.getLevelState(ProgressionFSM.islandKey(1)),
          LevelState.unlocked);
      expect(await storage.getLevelState(ProgressionFSM.stageKey(1, 1)),
          LevelState.unlocked);
      expect(await storage.getLevelState(ProgressionFSM.islandKey(2)),
          LevelState.locked);
      expect(await storage.getLevelState(ProgressionFSM.badgeKey(1)),
          LevelState.unlocked);
      expect(await storage.getLevelState(ProgressionFSM.badgeKey(2)),
          LevelState.locked);
      expect((await storage.getLencana()).first, isTrue);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(ProgressionFSM.islandKey(1)), 'unlocked');
      expect(preferences.getString(ProgressionFSM.stageKey(1, 1)), 'unlocked');
      expect(preferences.getString(ProgressionFSM.islandKey(2)), 'locked');
      expect(preferences.getString(ProgressionFSM.badgeKey(1)), 'unlocked');
      expect(preferences.getString(ProgressionFSM.badgeKey(2)), 'locked');
    });

    test('requires setup for fresh profiles and respects explicit registration',
        () async {
      SharedPreferences.setMockInitialValues({});
      var storage = StorageService();
      await storage.init();
      expect(await storage.isRegistered(), isFalse);

      SharedPreferences.setMockInitialValues({
        StorageService.keyNama: 'Putri',
        StorageService.keyRegistered: false,
      });
      storage = StorageService();
      await storage.init();
      expect(await storage.isRegistered(), isFalse);

      await storage.setRegistered(true);
      expect(await storage.isRegistered(), isTrue);
    });

    test('normalizes avatars, synchronizes badges, and recalculates best stars',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();

      await storage.setNama('  Naya  ');
      await storage.setAvatar('AISYAH');
      expect(await storage.getNama(), 'Naya');
      expect(await storage.getAvatar(), 'aisyah');

      final states = await storage.getFsmStates();
      states[ProgressionFSM.badgeKey(1)] = LevelState.unlocked;
      await storage.saveFsmStates(states);
      expect(await storage.getLencana(),
          [true, false, false, false, false, false]);

      await storage.setStageStars(1, 1, 3);
      await storage.setStageStars(1, 2, 2);
      expect(await storage.recalculateTotalStars(), 5);
      expect(await storage.getTotalBintang(), 5);

      await storage.setStageStars(1, 1, 1);
      expect(await storage.recalculateTotalStars(), 3);
      expect(await storage.getTotalBintang(), 3);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool('lencana_1'), isTrue);
      expect(preferences.getString(ProgressionFSM.badgeKey(1)), 'unlocked');
    });

    test('synchronizes legacy unlock keys when FSM states are saved', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final states = await storage.getFsmStates();
      states[ProgressionFSM.islandKey(2)] = LevelState.unlocked;
      states[ProgressionFSM.stageKey(2, 1)] = LevelState.unlocked;
      states[ProgressionFSM.badgeKey(1)] = LevelState.unlocked;

      await storage.saveFsmStates(states);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool('pulau_2_unlocked'), isTrue);
      expect(preferences.getBool('pulau_2_completed'), isFalse);
      expect(preferences.getBool('pulau_2_tahap_1_unlocked'), isTrue);
      expect(preferences.getBool('lencana_1'), isTrue);
    });

    test('adds session points and clamps the persisted total at zero',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();

      expect(await storage.addTotalPoin(10), 10);
      expect(await storage.addTotalPoin(-5), 5);
      expect(await storage.addTotalPoin(-20), 0);
      expect(await storage.getTotalPoin(), 0);
    });
  });
}
