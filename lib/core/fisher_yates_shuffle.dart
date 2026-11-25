import 'dart:math';

class FisherYatesShuffle {
  final Random _random = Random();

  List<T> shuffle<T>(List<T> input) {
    final list = List<T>.from(input);
    for (int i = list.length - 1; i > 0; i--) {
      int j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }

  List<T> stratifiedShuffle<T>(List<T> bank, String idPulau, int tahap) {
    final sub = bank.where((e) {
      final m = e as Map;
      return m['id_pulau'] == idPulau && m['tahap_kesulitan'] == tahap;
    }).toList();
    return shuffle(sub);
  }
}
