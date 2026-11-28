import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/storage_service.dart';
import '../data/materi_data.dart';

const _emerald = Color(0xFF149E53);
const _ink = Color(0xFF194D3B);
const _cream = Color(0xFFFFFDF2);
const _pointColors = [
  Color(0xFFFFB86B),
  Color(0xFF6EC5F5),
  Color(0xFFB39DF5),
  Color(0xFFFF8FA3),
  Color(0xFF62D2A2),
  Color(0xFFF4CE5C),
];

class BelajarDetailScreen extends StatefulWidget {
  final int babIndex;
  final Map<String, dynamic> bab;
  final int itemIndex;

  const BelajarDetailScreen({
    super.key,
    required this.babIndex,
    required this.bab,
    this.itemIndex = 0,
  });

  @override
  State<BelajarDetailScreen> createState() => _BelajarDetailScreenState();
}

class _BelajarDetailScreenState extends State<BelajarDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  final StorageService _storage = StorageService();
  int? _selectedPointIndex;
  String _avatar = 'zaid';
  bool _playing = false;
  bool _ttsReady = true;
  bool _completing = false;

  List<Map<String, dynamic>> get _items =>
      (widget.bab['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  Map<String, dynamic>? get _item {
    final items = _items;
    if (widget.itemIndex < 0 || widget.itemIndex >= items.length) return null;
    return items[widget.itemIndex];
  }

  List<Map<String, dynamic>> get _points {
    final item = _item;
    return item == null ? const [] : MateriData.getPoinPenjelasan(item);
  }

  String get _matanSpeech {
    final item = _item;
    if (item == null) return '';
    return [
      item['teksLatin']?.toString() ?? '',
      item['arti']?.toString() ?? '',
    ].where((text) => text.trim().isNotEmpty).join('. ');
  }

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _configureTts();
  }

  Future<void> _loadAvatar() async {
    final avatar = await _storage.getAvatar();
    if (!mounted) return;
    setState(() => _avatar = avatar);
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.90);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setStartHandler(() {
        if (mounted) setState(() => _playing = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _playing = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _playing = false);
      });
      _tts.setErrorHandler((dynamic message) {
        if (!mounted) return;
        setState(() {
          _playing = false;
          _ttsReady = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suara belum tersedia: $message')),
        );
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _ttsReady = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suara belum tersedia: ${error.message}')),
      );
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _ttsReady = false);
    }
  }

  @override
  void dispose() {
    _safeStopTts().ignore();
    super.dispose();
  }

  Future<void> _completeChapter() async {
    if (_completing || _item == null) return;
    setState(() => _completing = true);
    await _stopAudio();
    final key = 'bab_${widget.bab['bab']}_selesai';
    await _storage.setProgres(key, true);
    await _storage.tambahNyawa(2);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '🎉 Alhamdulillah! +2 ❤️ Nyawa ditambahkan!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _emerald,
          ),
        ),
        content: const Text(
          'Alhamdulillah, materi bab ini sudah selesai dibaca.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _safeStopTts() async {
    try {
      await _tts.stop();
    } on PlatformException {
      // The visual explanation remains usable without a TTS engine.
    } on MissingPluginException {
      // TTS is optional on unsupported devices and test hosts.
    }
  }

  Future<void> _stopAudio() async {
    await _safeStopTts();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _toggleAudio(String text) async {
    if (text.trim().isEmpty) return;
    if (_playing) {
      await _stopAudio();
      return;
    }
    if (!_ttsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suara belum tersedia di perangkat ini.')),
      );
      return;
    }

    try {
      setState(() => _playing = true);
      await _tts.speak(text);
      if (mounted) setState(() => _playing = false);
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _ttsReady = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suara belum tersedia: ${error.message}')),
      );
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _ttsReady = false;
      });
    }
  }

  void _selectPoint(int index) {
    if (_selectedPointIndex == index) {
      setState(() => _selectedPointIndex = null);
      _stopAudio();
      return;
    }
    _stopAudio();
    setState(() => _selectedPointIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      backgroundColor: const Color(0xFFDDF5E8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _emerald),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.bab['judul']?.toString() ?? 'Materi Belajar',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: _ink,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_menu_utama.png',
            key: const ValueKey('materi-detail-background'),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/bg_menu_utama.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: item == null
                ? const Center(child: Text('Materi belum tersedia.'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 640 &&
                          constraints.maxWidth > constraints.maxHeight * 1.2;
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1120),
                            child: Container(
                              key: const ValueKey('materi-detail-board'),
                              padding: EdgeInsets.all(wide ? 20 : 14),
                              decoration: BoxDecoration(
                                color: _cream,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFD7B65B),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D6657)
                                        .withValues(alpha: 0.20),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: wide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: _MatanPanel(
                                            item: item,
                                            playing: _playing,
                                            onPlay: () =>
                                                _toggleAudio(_matanSpeech),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          flex: 6,
                                          child: _ExplanationPanel(
                                            points: _points,
                                            selectedPointIndex:
                                                _selectedPointIndex,
                                            avatar: _avatar,
                                            playing: _playing,
                                            completing: _completing,
                                            onSelectPoint: _selectPoint,
                                            onPlayExplanation: () {
                                              final index = _selectedPointIndex;
                                              if (index == null ||
                                                  index >= _points.length) {
                                                return;
                                              }
                                              _toggleAudio(
                                                _points[index]['isiPenjelasan']
                                                        ?.toString() ??
                                                    '',
                                              );
                                            },
                                            onCloseExplanation: () {
                                              setState(
                                                () =>
                                                    _selectedPointIndex = null,
                                              );
                                              _stopAudio();
                                            },
                                            onComplete: _completeChapter,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _MatanPanel(
                                          item: item,
                                          playing: _playing,
                                          onPlay: () =>
                                              _toggleAudio(_matanSpeech),
                                        ),
                                        const SizedBox(height: 16),
                                        _ExplanationPanel(
                                          points: _points,
                                          selectedPointIndex:
                                              _selectedPointIndex,
                                          avatar: _avatar,
                                          playing: _playing,
                                          completing: _completing,
                                          onSelectPoint: _selectPoint,
                                          onPlayExplanation: () {
                                            final index = _selectedPointIndex;
                                            if (index == null ||
                                                index >= _points.length) {
                                              return;
                                            }
                                            _toggleAudio(
                                              _points[index]['isiPenjelasan']
                                                      ?.toString() ??
                                                  '',
                                            );
                                          },
                                          onCloseExplanation: () {
                                            setState(
                                              () => _selectedPointIndex = null,
                                            );
                                            _stopAudio();
                                          },
                                          onComplete: _completeChapter,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatanPanel extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool playing;
  final VoidCallback onPlay;

  const _MatanPanel({
    required this.item,
    required this.playing,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFB8E6D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _materiDisplayTitle(item['judulKartu']?.toString() ?? 'Materi'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF3E8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'MATAN',
                style: TextStyle(
                  color: _emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD8ECE2)),
            ),
            child: Text(
              item['teksArab']?.toString() ?? '',
              style: const TextStyle(
                color: Color(0xFF173F32),
                fontSize: 25,
                fontWeight: FontWeight.w700,
                height: 1.8,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: 12),
          _MatanSection(
            label: 'Bacaan Latin',
            text: item['teksLatin']?.toString() ?? '',
            italic: true,
          ),
          const SizedBox(height: 10),
          _MatanSection(
            label: 'Arti',
            text: item['arti']?.toString() ?? '',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text(
                    'Dengarkan bacaan',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _emerald,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Speaker suara bacaan',
                  child: Material(
                    key: const ValueKey('matan-speaker-button'),
                    color: _emerald,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onPlay,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(
                          playing
                              ? Icons.stop_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatanSection extends StatelessWidget {
  final String label;
  final String text;
  final bool italic;

  const _MatanSection({
    required this.label,
    required this.text,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _emerald,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          text,
          style: TextStyle(
            color: const Color(0xFF375A4D),
            fontSize: 13,
            height: 1.4,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

class _ExplanationPanel extends StatelessWidget {
  final List<Map<String, dynamic>> points;
  final int? selectedPointIndex;
  final String avatar;
  final bool playing;
  final bool completing;
  final ValueChanged<int> onSelectPoint;
  final VoidCallback onPlayExplanation;
  final VoidCallback onCloseExplanation;
  final VoidCallback onComplete;

  const _ExplanationPanel({
    required this.points,
    required this.selectedPointIndex,
    required this.avatar,
    required this.playing,
    required this.completing,
    required this.onSelectPoint,
    required this.onPlayExplanation,
    required this.onCloseExplanation,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7D9A8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app_outlined, color: _emerald, size: 20),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pilih poin untuk belajar',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (points.isEmpty)
            const _EmptyPointsCard()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < points.length; i++)
                      SizedBox(
                        width: buttonWidth,
                        child: _PointButton(
                          index: i,
                          title: _materiDisplayTitle(
                            points[i]['judulPoin']?.toString() ??
                                'Poin ${i + 1}',
                          ),
                          color: _pointColors[i % _pointColors.length],
                          selected: selectedPointIndex == i,
                          onTap: () => onSelectPoint(i),
                        ),
                      ),
                  ],
                );
              },
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: selectedPointIndex == null
                ? const SizedBox(width: double.infinity)
                : _CharacterPanel(
                    key: const ValueKey('character-panel'),
                    avatar: avatar,
                    point: points[selectedPointIndex!],
                    playing: playing,
                    onPlay: onPlayExplanation,
                    onClose: onCloseExplanation,
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const ValueKey('complete-material-button'),
            onPressed: completing ? null : onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: _emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 21),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Selesai Belajar (+2 ❤️ Nyawa)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointButton extends StatelessWidget {
  final int index;
  final String title;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PointButton({
    required this.index,
    required this.title,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : color.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('point-button-$index'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _ink : color,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterPanel extends StatelessWidget {
  final String avatar;
  final Map<String, dynamic> point;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onClose;

  const _CharacterPanel({
    super.key,
    required this.avatar,
    required this.point,
    required this.playing,
    required this.onPlay,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isAisyah = avatar == 'aisyah';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8E6D0), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _emerald, width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(
                    isAisyah
                        ? 'assets/images/avatar_aisyah.png'
                        : 'assets/images/avatar_zaid.png',
                    key: ValueKey('guide-avatar-$avatar'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAisyah ? 'Aisyah' : 'Zaid',
                style: const TextStyle(
                  color: _emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F5EE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _materiDisplayTitle(
                            point['judulPoin']?.toString() ?? 'Penjelasan',
                          ),
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('close-character-panel'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF527264),
                        ),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point['isiPenjelasan']?.toString() ?? '',
                    style: const TextStyle(
                      color: Color(0xFF375A4D),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      key: const ValueKey('tts-speaker-button'),
                      onPressed: onPlay,
                      icon: Icon(
                        playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        playing ? 'Hentikan' : 'Dengarkan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPointsCard extends StatelessWidget {
  const _EmptyPointsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Poin penjelasan untuk kartu ini belum tersedia.',
        style: TextStyle(color: Color(0xFF527264), fontSize: 13),
      ),
    );
  }
}

String _materiDisplayTitle(String title) {
  return title
      .replaceAll(
        RegExp(r'\s*\(\s*Safinatun\s*Najah\s*\)', caseSensitive: false),
        '',
      )
      .trim();
}
