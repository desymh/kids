import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/storage_service.dart';
import '../data/materi_data.dart';

class BelajarDetailScreen extends StatefulWidget {
  final int babIndex;
  final Map<String, dynamic> bab;
  const BelajarDetailScreen(
      {super.key, required this.babIndex, required this.bab});

  @override
  State<BelajarDetailScreen> createState() => _BelajarDetailScreenState();
}

class _BelajarDetailScreenState extends State<BelajarDetailScreen> {
  static const _emerald = Color(0xFF149E53);
  static const _ink = Color(0xFF194D3B);
  static const _pointColors = [
    Color(0xFFFFB86B),
    Color(0xFF6EC5F5),
    Color(0xFFB39DF5),
    Color(0xFFFF8FA3),
    Color(0xFF62D2A2),
    Color(0xFFF4CE5C),
  ];

  final FlutterTts _tts = FlutterTts();
  final StorageService _storage = StorageService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
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

  List<Map<String, dynamic>> get _currentPoints =>
      MateriData.getPoinPenjelasan(_items[_currentPage]);

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
    _pageController.dispose();
    _safeStopTts().ignore();
    super.dispose();
  }

  Future<void> _completeChapter() async {
    if (_completing) return;
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

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _stopAudio();
      setState(() => _selectedPointIndex = null);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeChapter();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _stopAudio();
      setState(() => _selectedPointIndex = null);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDF5E8),
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
      body: SafeArea(
        child: _items.isEmpty
            ? const Center(child: Text('Materi belum tersedia.'))
            : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _items.length,
                      onPageChanged: (index) {
                        _stopAudio();
                        setState(() {
                          _currentPage = index;
                          _selectedPointIndex = null;
                        });
                      },
                      itemBuilder: (_, index) {
                        final item = _items[index];
                        final points = MateriData.getPoinPenjelasan(item);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CardHeader(
                                item: item,
                                cardNumber: index + 1,
                                totalCards: _items.length,
                              ),
                              const SizedBox(height: 12),
                              _MatanCard(item: item),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.touch_app_outlined,
                                    color: _emerald,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(
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
                              const SizedBox(height: 10),
                              if (points.isEmpty)
                                const _EmptyPointsCard()
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final buttonWidth =
                                        (constraints.maxWidth - 10) / 2;
                                    return Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        for (var i = 0; i < points.length; i++)
                                          SizedBox(
                                            width: buttonWidth,
                                            child: _PointButton(
                                              index: i,
                                              title: points[i]['judulPoin']
                                                      ?.toString() ??
                                                  'Poin ${i + 1}',
                                              color: _pointColors[
                                                  i % _pointColors.length],
                                              selected:
                                                  _selectedPointIndex == i,
                                              onTap: () => _selectPoint(i),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.bottomCenter,
                    child: _selectedPointIndex == null
                        ? const SizedBox(width: double.infinity)
                        : _CharacterPanel(
                            key: const ValueKey('character-panel'),
                            avatar: _avatar,
                            point: _currentPoints[_selectedPointIndex!],
                            playing: _playing,
                            onPlay: () => _toggleAudio(
                              _currentPoints[_selectedPointIndex!]
                                          ['isiPenjelasan']
                                      ?.toString() ??
                                  '',
                            ),
                            onClose: () {
                              setState(() => _selectedPointIndex = null);
                              _stopAudio();
                            },
                          ),
                  ),
                  _BottomNavigation(
                    currentPage: _currentPage,
                    totalPages: _items.length,
                    onPrevious: _prevPage,
                    onNext: _nextPage,
                  ),
                ],
              ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final Map<String, dynamic> item;
  final int cardNumber;
  final int totalCards;

  const _CardHeader({
    required this.item,
    required this.cardNumber,
    required this.totalCards,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF149E53),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              '$cardNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['judulKartu']?.toString() ?? 'Kartu Materi',
                style: const TextStyle(
                  color: Color(0xFF194D3B),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Kartu $cardNumber dari $totalCards',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatanCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _MatanCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB8E6D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF149E53).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'MATAN',
                  style: TextStyle(
                    color: Color(0xFF149E53),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF149E53),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1FAF6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item['teksArab']?.toString() ?? '',
              style: const TextStyle(
                color: Color(0xFF173F32),
                fontSize: 23,
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
            color: Color(0xFF149E53),
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
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFF194D3B) : color,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF194D3B),
                      fontSize: 13,
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
                    color: Color(0xFF194D3B),
                    fontSize: 12,
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB8E6D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF149E53).withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF149E53),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF149E53).withValues(alpha: 0.18),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
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
                  color: Color(0xFF149E53),
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
                          point['judulPoin']?.toString() ?? 'Penjelasan',
                          style: const TextStyle(
                            color: Color(0xFF194D3B),
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
                        backgroundColor: const Color(0xFF149E53),
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

class _BottomNavigation extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _BottomNavigation({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: currentPage > 0 ? onPrevious : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                side: const BorderSide(color: Color(0xFFB8E6D0)),
              ),
              child: const Text(
                'Sebelumnya',
                style: TextStyle(
                  color: Color(0xFF149E53),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              key: const ValueKey('next-material-button'),
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF149E53),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                currentPage == totalPages - 1 ? 'Selesai' : 'Lanjut',
                style: const TextStyle(fontWeight: FontWeight.w800),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Poin penjelasan untuk kartu ini belum tersedia.',
        style: TextStyle(color: Color(0xFF527264), fontSize: 13),
      ),
    );
  }
}
