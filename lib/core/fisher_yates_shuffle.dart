import 'dart:math';

class FisherYatesShuffler {
  static List<T> shuffle<T>(List<T> items) {
    final result = List<T>.from(items);
    final random = Random();
    for (int i = result.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result;
  }

  static Map<String, dynamic> acakSoalDanOpsi(Map<String, dynamic> soal) {
    final result = Map<String, dynamic>.from(soal);
    final opsi = List<String>.from(result['opsi'] as List);
    final jawabanBenar = result['jawabanBenar'] as int;

    // Fisher-Yates on opsi indices
    final indices = List<int>.generate(opsi.length, (i) => i);
    final random = Random();
    for (int i = indices.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = indices[i];
      indices[i] = indices[j];
      indices[j] = temp;
    }

    // Reorder opsi
    final newOpsi = List<String>.generate(opsi.length, (i) => opsi[indices[i]]);

    // Find new jawabanBenar index
    int newJawabanBenar = 0;
    for (int i = 0; i < indices.length; i++) {
      if (indices[i] == jawabanBenar) {
        newJawabanBenar = i;
        break;
      }
    }

    result['opsi'] = newOpsi;
    result['jawabanBenar'] = newJawabanBenar;
    return result;
  }
}