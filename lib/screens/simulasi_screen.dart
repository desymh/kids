import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/fisher_yates_shuffle.dart';
import '../core/fsm_controller.dart';
import '../core/storage_service.dart';

class SimulasiScreen extends StatefulWidget {
  const SimulasiScreen({super.key});
  @override
  State<SimulasiScreen> createState() => _SimulasiScreenState();
}

enum _SimulationMode { wudhu, shalat }

class _PracticeStep {
  final int order;
  final String id;
  final String title;
  final String category;
  final String imageAsset;
  final String arabic;
  final String latin;
  final String meaning;
  const _PracticeStep(
    this.order,
    this.id,
    this.title,
    this.category,
    this.imageAsset,
    this.meaning, {
    this.arabic = '',
    this.latin = '',
  });
  String get speechText => [
        title,
        if (latin.isNotEmpty) latin,
        meaning,
      ].join('. ');
}

const _mint = Color(0xFFE6F5EE);
const _emerald = Color(0xFF178B63);
const _darkEmerald = Color(0xFF075E45);
const _softEmerald = Color(0xFFD9F3E7);
const _gold = Color(0xFFF2B84B);
const _wudhuSteps = <_PracticeStep>[
  _PracticeStep(
      0,
      'niat',
      'Niat Wudhu',
      'Rukun',
      'assets/images/wudhu_1_niat.png',
      'Niat bersaksi di hadapan Allah dan malaikat.',
      arabic:
          'أُشْهِدُ اللَّهَ لِوُجُوْدِيْ وَشُهُوْدِيْ مَنْ حَضَرَنِيْ مِنَ الْمَلَائِكَةِ وَجِبْرِيْلَ وَمِيْكَالَ',
      latin:
          'Ushhidu llaaha liwujuudii wa syuhuudii man hadloronii minal malaa-ikati wa jibriila wa miikaala.'),
  _PracticeStep(
      1,
      'telapak_tangan',
      'Mencuci Telapak Tangan',
      'Sunnah',
      'assets/images/wudhu_2_telapak_tangan.png',
      'Cuci kedua telapak tangan sambil membaca basmalah.',
      arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      latin: 'Bismillahirrahmanirrahim.'),
  _PracticeStep(
      2,
      'berkumur',
      'Berkumur-kumur',
      'Sunnah',
      'assets/images/wudhu_3_kumur.png',
      'Berkumur dengan air suci sampai seluruh rongga mulut.'),
  _PracticeStep(
      3,
      'hidung',
      'Membersihkan Hidung',
      'Sunnah',
      'assets/images/wudhu_4_hidung.png',
      'Masukkan air ke hidung lalu istinsyaq dengan lembut.'),
  _PracticeStep(
      4,
      'muka',
      'Membasuh Seluruh Wajah',
      'Rukun',
      'assets/images/wudhu_5_muka.png',
      'Basuh seluruh wajah dari rambut sampai dagu.'),
  _PracticeStep(
      5,
      'tangan',
      'Membasuh Tangan sampai Siku',
      'Rukun',
      'assets/images/wudhu_6_tangan.png',
      'Basuh tangan kanan lalu kiri sampai siku.'),
  _PracticeStep(6, 'kepala', 'Mengusap Sebagian Kepala', 'Rukun',
      'assets/images/wudhu_7_kepala.png', 'Usap sebagian kepala dengan air.'),
  _PracticeStep(
      7,
      'telinga',
      'Mengusap Kedua Telinga',
      'Sunnah',
      'assets/images/wudhu_8_telinga.png',
      'Usap kedua telinga dengan jari yang dibasahi air.'),
  _PracticeStep(
      8,
      'kaki',
      'Membasuh Kaki sampai Mata Kaki',
      'Rukun',
      'assets/images/wudhu_9_kaki.png',
      'Basuh kaki kanan lalu kiri sampai mata kaki.'),
];
const _shalatSteps = <_PracticeStep>[
  _PracticeStep(
      0,
      'takbir',
      'Takbiratul Ihram',
      'Rukun',
      'assets/images/shalat_1_takbir.png',
      'Angkat kedua tangan dan ucapkan takbiratul ihram.',
      arabic: 'اللَّهُ أَكْبَرُ',
      latin: 'Allahu Akbar.'),
  _PracticeStep(
      1,
      'sedekap',
      'Berdiri Bersedekap & Al-Fatihah',
      'Rukun',
      'assets/images/shalat_2_sedekap.png',
      'Berdiri tegak, sedekap, dan membaca Al-Fatihah.',
      arabic: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
      latin: 'Al-Fatihah, diawali Bismillahirrahmanirrahim.'),
  _PracticeStep(2, 'rukuk', "Rukuk dengan Thuma'ninah", 'Rukun',
      'assets/images/shalat_3_rukuk.png', 'Rukuk dengan tenang dan tumakninah.',
      arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
      latin: "Subhaana rabbiyal 'adhiim."),
  _PracticeStep(
      3,
      'itidal',
      "Bangun I'tidal",
      'Rukun',
      'assets/images/shalat_4_itidal.png',
      'Bangun dari rukuk dengan tumakninah.',
      arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَ',
      latin: "Sami'allahu liman hamidah."),
  _PracticeStep(4, 'sujud', "Sujud dengan Thuma'ninah", 'Rukun',
      'assets/images/shalat_5_sujud.png', 'Sujud dengan tenang dan tumakninah.',
      arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
      latin: "Subhaana rabbiyal a'laa."),
  _PracticeStep(
      5,
      'duduk_sujud',
      'Duduk di Antara Dua Sujud',
      'Sunnah',
      'assets/images/shalat_6_duduk_sujud.png',
      'Duduk tenang di antara dua sujud.',
      arabic: 'رَبِّ اغْفِرْ لِي',
      latin: 'Rabbighfirli.'),
  _PracticeStep(
      6,
      'tahiyat',
      'Duduk Tasyahud / Tahiyat Akhir',
      'Rukun',
      'assets/images/shalat_7_tahiyat.png',
      'Duduk tasyahud akhir dengan tartil.',
      arabic: 'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ',
      latin: 'At-tahiyyatu lillahi was-shalatu wat-thayyibat.'),
  _PracticeStep(
      7,
      'salam',
      'Mengucapkan Salam ke Kanan',
      'Rukun',
      'assets/images/shalat_8_salam.png',
      'Menoleh ke kanan dan mengucapkan salam.',
      arabic: 'السَّلَامُ عَلَيْكُمْ',
      latin: "Assalamu'alaikum."),
];

class _SimulasiScreenState extends State<SimulasiScreen> {
  final StorageService _storage = StorageService();
  final FlutterTts _tts = FlutterTts();
  late final Future<void> _ttsSetup;
  _SimulationMode _mode = _SimulationMode.wudhu;
  late IbadahSimulationFSM _fsm;
  late List<_PracticeStep> _shuffledSteps;
  _PracticeStep? _activeStep;
  Timer? _feedbackTimer;
  String? _feedbackMessage;
  bool _feedbackCorrect = true;
  bool _finishing = false;
  bool _rewardGranted = false;
  List<_PracticeStep> get _steps =>
      _mode == _SimulationMode.wudhu ? _wudhuSteps : _shalatSteps;
  ButtonStyle get _primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: _emerald,
        foregroundColor: Colors.white,
        elevation: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );
  @override
  void initState() {
    super.initState();
    _initializePractice();
    _ttsSetup = _configureTts();
  }

  Future<void> _runTts(Future<dynamic> Function() action) async {
    try {
      await action();
    } on PlatformException {
      // Visual instructions remain available without a TTS engine.
    } on MissingPluginException {
      // Widget tests and unsupported platforms do not provide TTS.
    }
  }

  Future<void> _configureTts() => _runTts(() async {
        await _tts.setLanguage('id-ID');
        await _tts.setSpeechRate(0.90);
        await _tts.setPitch(1.0);
      });
  Future<void> _stopSpeaking() => _runTts(_tts.stop);
  Future<void> _readStep(_PracticeStep step) async {
    await _ttsSetup;
    await _runTts(() => _tts.speak(step.speechText));
  }

  void _initializePractice() {
    _fsm = IbadahSimulationFSM(
      steps: _steps.map((step) => step.id).toList(),
    );
    _shuffledSteps = FisherYatesShuffler.shuffle(_steps);
    _activeStep = null;
    _finishing = false;
    _rewardGranted = false;
    _clearFeedback();
  }

  void _switchMode(_SimulationMode mode) {
    if (mode == _mode || _finishing) return;
    unawaited(_stopSpeaking());
    setState(() {
      _mode = mode;
      _initializePractice();
    });
  }

  void _resetPractice() {
    unawaited(_stopSpeaking());
    setState(_initializePractice);
  }

  void _clearFeedback() {
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    _feedbackMessage = null;
  }

  void _showFeedback(String message, {required bool correct}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackMessage = message;
      _feedbackCorrect = correct;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _feedbackMessage = null);
    });
  }

  void _onStepTap(_PracticeStep step) {
    if (_finishing || _fsm.isComplete || step.order < _fsm.currentState) {
      return;
    }
    if (!_fsm.validasiLangkah(step.order)) {
      _showFeedback(
        '❌ Urutan keliru! Ibadah harus dilakukan secara tertib (berurutan).',
        correct: false,
      );
      return;
    }
    setState(() => _activeStep = step);
    _showFeedback(
      '✅ Tepat! Langkah ke-${_fsm.currentState} benar!',
      correct: true,
    );
    unawaited(_readStep(step));
    if (_fsm.isComplete) {
      unawaited(_completePractice());
    }
  }

  Future<void> _completePractice() async {
    if (_rewardGranted) return;
    setState(() => _finishing = true);
    await _storage.tambahNyawa(2);
    if (!mounted) return;
    setState(() {
      _rewardGranted = true;
      _finishing = false;
    });
    await _showCelebrationDialog();
  }

  Future<void> _showCelebrationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          '🎉 Alhamdulillah! +2 ❤️ Nyawa ditambahkan!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _darkEmerald,
          ),
        ),
        content: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.75, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF4D5),
                  border: Border.all(color: _gold, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33F2B84B),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/icon_trophy.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.emoji_events, color: _gold, size: 44),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _mode == _SimulationMode.wudhu
                    ? 'Wudhu selesai dengan urutan yang tepat.'
                    : 'Shalat selesai dengan urutan yang tepat.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, height: 1.2),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Nanti'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _resetPractice();
            },
            icon: const Icon(Icons.replay),
            label: const Text('Ulangi Praktik'),
            style: _primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    unawaited(_stopSpeaking());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 6),
                  _buildModeSelector(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                        children: [
                          SizedBox(
                              width: constraints.maxWidth * 0.42,
                              child: _buildStageCard()),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildPracticeArea(constraints.maxHeight)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_feedbackMessage != null)
                Positioned(
                  top: 88,
                  left: 20,
                  right: 20,
                  child: IgnorePointer(
                    child: _FeedbackBanner(
                      key: const ValueKey('simulasi-feedback'),
                      message: _feedbackMessage!,
                      correct: _feedbackCorrect,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _darkEmerald,
              elevation: 3,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Simulasi Praktik',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _darkEmerald,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1410B981),
                    blurRadius: 8,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              '${_fsm.currentState} / ${_steps.length} langkah',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _darkEmerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              key: const ValueKey('simulasi-mode-wudhu'),
              label: const Text('Simulasi Wudhu (9 Langkah)'),
              selected: _mode == _SimulationMode.wudhu,
              onSelected: (_) => _switchMode(_SimulationMode.wudhu),
              selectedColor: _emerald,
              backgroundColor: Colors.white,
              showCheckmark: false,
              elevation: _mode == _SimulationMode.wudhu ? 5 : 2,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _mode == _SimulationMode.wudhu
                    ? Colors.white
                    : _darkEmerald,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: _mode == _SimulationMode.wudhu
                      ? _emerald
                      : const Color(0xFFD5EEE4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ChoiceChip(
              key: const ValueKey('simulasi-mode-shalat'),
              label: const Text('Simulasi Shalat (8 Langkah)'),
              selected: _mode == _SimulationMode.shalat,
              onSelected: (_) => _switchMode(_SimulationMode.shalat),
              selectedColor: _emerald,
              backgroundColor: Colors.white,
              showCheckmark: false,
              elevation: _mode == _SimulationMode.shalat ? 5 : 2,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _mode == _SimulationMode.shalat
                    ? Colors.white
                    : _darkEmerald,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: _mode == _SimulationMode.shalat
                      ? _emerald
                      : const Color(0xFFD5EEE4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard() {
    final step = _activeStep;
    return Container(
      key: const ValueKey('simulasi-stage'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFC8EBDD), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2210B981),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step == null
                      ? 'Siap Berpraktik?'
                      : 'Langkah ${step.order + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _darkEmerald,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _CategoryPill(
                label: step?.category ?? 'Mulai',
                sunnah: step?.category == 'Sunnah',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: ClipRRect(
                key: ValueKey(step?.imageAsset ?? 'mascot'),
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      step?.imageAsset ?? 'assets/images/mascot_berdua.png',
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.self_improvement,
                          size: 54,
                          color: _emerald,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 7,
                      right: 7,
                      bottom: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xD9084F3B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          step?.title ??
                              'Ketuk kartu langkah ke-1 untuk memulai!',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: step == null
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Pilih gerakan yang tepat sesuai urutan. Setiap langkah '
                        'yang benar akan dibacakan otomatis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: Color(0xFF527064),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        if (step.arabic.isNotEmpty)
                          Text(
                            step.arabic,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              color: _darkEmerald,
                            ),
                          ),
                        if (step.latin.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              step.latin,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF476658),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            step.meaning,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              height: 1.25,
                              color: Color(0xFF527064),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: _fsm.isComplete
                ? ElevatedButton.icon(
                    key: const ValueKey('simulasi-replay'),
                    onPressed: _resetPractice,
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('Ulangi Praktik'),
                    style: _primaryButtonStyle,
                  )
                : ElevatedButton.icon(
                    key: const ValueKey('simulasi-speaker'),
                    onPressed: () {
                      final current = _activeStep;
                      if (current != null) {
                        unawaited(_readStep(current));
                      } else {
                        unawaited(_readIntroduction());
                      }
                    },
                    icon: const Icon(Icons.volume_up_rounded, size: 18),
                    label: const Text('Dengarkan'),
                    style: _primaryButtonStyle,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _readIntroduction() async {
    await _ttsSetup;
    await _runTts(() => _tts.speak(
          'Ketuk kartu langkah ke-1 untuk memulai. Pilih gerakan yang tepat '
          'sesuai urutan.',
        ));
  }

  Widget _buildPracticeArea(double availableHeight) {
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [
              const Text(
                'Urutan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _darkEmerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: _steps.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 5),
                  itemBuilder: (context, index) {
                    final completed = index < _fsm.currentState;
                    final current =
                        index == _fsm.currentState && !_fsm.isComplete;
                    return Container(
                      key: ValueKey('simulasi-indicator-$index'),
                      width: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: completed
                            ? _emerald
                            : current
                                ? const Color(0xFFFFE3A3)
                                : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: completed
                              ? _emerald
                              : current
                                  ? _gold
                                  : const Color(0xFFC8EBDD),
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: completed
                              ? Colors.white
                              : current
                                  ? const Color(0xFF76520C)
                                  : const Color(0xFF779084),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final cardWidth = (constraints.maxWidth - spacing * 2) / 3;
              final cardHeight = (availableHeight - 38 - spacing * 2) / 3;
              return GridView.count(
                crossAxisCount: 3,
                padding: EdgeInsets.zero,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: cardWidth / cardHeight,
                children: _shuffledSteps.map((step) {
                  final completed = step.order < _fsm.currentState;
                  return _StepCard(
                    key: ValueKey('simulasi-card-${step.id}'),
                    step: step,
                    completed: completed,
                    enabled: !_finishing && !_fsm.isComplete,
                    onTap: () => _onStepTap(step),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool sunnah;
  const _CategoryPill({required this.label, this.sunnah = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: sunnah ? const Color(0xFFFFF0C7) : _softEmerald,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: sunnah ? const Color(0xFF8A5B08) : _darkEmerald,
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _PracticeStep step;
  final bool completed;
  final bool enabled;
  final VoidCallback onTap;
  const _StepCard(
      {super.key,
      required this.step,
      required this.completed,
      required this.enabled,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled && !completed,
      label: 'Langkah ${step.order + 1}: ${step.title}',
      child: Material(
        color: completed ? const Color(0xFFE5F6ED) : Colors.white,
        elevation: completed ? 1 : 4,
        shadowColor: const Color(0x2210B981),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: enabled && !completed ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: completed ? _emerald : const Color(0xFFD5EEE4),
                width: completed ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(5),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          step.imageAsset,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.self_improvement,
                              color: _emerald,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color:
                            completed ? _darkEmerald : const Color(0xFF35594B),
                      ),
                    ),
                  ],
                ),
                if (completed)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _emerald,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String message;
  final bool correct;
  const _FeedbackBanner(
      {super.key, required this.message, required this.correct});
  @override
  Widget build(BuildContext context) {
    final background = correct ? _emerald : const Color(0xFFD96842);
    return Material(
      color: background,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
