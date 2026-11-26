import 'dart:math';

class FisherYatesShuffler {
  static List<T> shuffle<T>(List<T> items, {Random? random}) {
    final result = List<T>.from(items);
    final activeRandom = random ?? Random();
    for (int i = result.length - 1; i > 0; i--) {
      final j = activeRandom.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result;
  }

  static Map<String, dynamic> acakSoalDanOpsi(
    Map<String, dynamic> soal, {
    Random? random,
  }) {
    final result = Map<String, dynamic>.from(soal);
    final rawOptions = (result['opsi'] as List)
        .map((option) => option.toString().trim())
        .where((option) => option.isNotEmpty)
        .toList();
    final correctIndex = result['jawabanBenar'] as int;
    if (correctIndex < 0 || correctIndex >= rawOptions.length) {
      throw ArgumentError('Indeks jawaban benar tidak valid.');
    }

    final correctAnswer = rawOptions[correctIndex];
    final options = <String>[];
    for (final option in rawOptions) {
      if (!options.contains(option)) {
        options.add(option);
      }
    }
    if (options.length != 4 || !options.contains(correctAnswer)) {
      throw ArgumentError('Setiap soal harus memiliki 4 opsi unik.');
    }

    final indices = shuffle<int>(List<int>.generate(options.length, (i) => i),
        random: random);
    final shuffledOptions = indices.map((i) => options[i]).toList();
    result['opsi'] = shuffledOptions;
    result['jawabanBenar'] = shuffledOptions.indexOf(correctAnswer);
    return result;
  }

  static List<Map<String, dynamic>> acakDaftarSoal(
    List<Map<String, dynamic>> questions, {
    Random? random,
  }) {
    final activeRandom = random ?? Random();
    final uniqueQuestions = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (final question in questions) {
      final id = question['id']?.toString().trim() ??
          question['pertanyaan']?.toString().trim() ??
          '';
      if (id.isNotEmpty && seenIds.add(id)) {
        uniqueQuestions.add(Map<String, dynamic>.from(question));
      }
    }

    final shuffled = shuffle<Map<String, dynamic>>(uniqueQuestions,
        random: activeRandom);
    return shuffled
        .map((question) => acakSoalDanOpsi(question, random: activeRandom))
        .toList();
  }
}