import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/data/materi_data.dart';
import 'package:qalbukids/screens/belajar_detail_screen.dart';
import 'package:qalbukids/screens/belajar_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ttsChannel = MethodChannel('flutter_tts');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> ttsCalls;

  setUp(() {
    ttsCalls = [];
    SharedPreferences.setMockInitialValues({
      StorageService.keyAvatar: 'zaid',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_ttsChannel, (call) async {
      ttsCalls.add(call);
      return 1;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_ttsChannel, null);
  });

  test('Bab 1 contains the requested three cards and explanation points', () {
    final bab = MateriData.dataBabBelajar.first;
    final items = (bab['items'] as List).cast<Map<String, dynamic>>();

    expect(items, hasLength(3));
    expect(
      items.map((item) => item['judulKartu']),
      [
        'Dua Kalimat Syahadat & Maknanya',
        '5 Rukun Islam (Safinatun Najah)',
        '6 Rukun Iman (Safinatun Najah)',
      ],
    );
    expect(
      items.map((item) => MateriData.getPoinPenjelasan(item).length),
      [3, 5, 6],
    );
    expect(items.first['teksArab'],
        'أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللهِ');
    expect(
      items.first['teksLatin'],
      'Asyhadu an laa ilaaha illallaah, wa asyhadu anna Muhammadar Rasuulullaah.',
    );
    expect(
      items.first['arti'],
      'Aku bersaksi bahwa tidak ada Tuhan selain Allah, dan aku bersaksi bahwa Nabi Muhammad adalah utusan Allah.',
    );
  });

  test('Bab 2 contains four structured cards with 3/3/6/4 points', () {
    final items = _itemsForChapter(2);

    expect(items, hasLength(4));
    expect(
      items.map((item) => item['judulKartu']),
      [
        'Air Suci Menyucikan (Air Mutlak)',
        '3 Jenis Najis & Cara Menyucikannya (Safinatun Najah)',
        '6 Rukun Wudhu & Niatnya (Safinatun Najah)',
        '4 Hal yang Membatalkan Wudhu (Safinatun Najah)',
      ],
    );
    expect(
      items.map((item) => MateriData.getPoinPenjelasan(item).length),
      [3, 3, 6, 4],
    );
    expect(
      items.map((item) => item['teksArab']),
      [
        'الْمَاءُ الطَّهُورُ هُوَ الطَّاهِرُ فِي نَفْسِهِ الْمُطَهِّرُ لِغَيْرِهِ',
        'النَّجَاسَاتُ ثَلَاثٌ: مُغَلَّظَةٌ، وَمُخَفَّفَةٌ، وَمُتَوَسِّطَةٌ',
        'نَوَيْتُ الْوُضُوْءَ لِرَفْعِ الْحَدَثِ الْاَصْغَرِ فَرْضًا لِلّٰهِ تَعَالَى',
        'نَوَاقِضُ الْوُضُوْءِ أَرْبَعَةُ أَشْيَاءَ',
      ],
    );
    expect(
      items.map((item) => item['teksLatin']),
      [
        "Al-maa'uth thahuuru huwath thaahiru fii nafsihi al-muthahhiru lighairihi.",
        'An-najaasaatu tsalaatsun: mughallazhatun, wa mukhaffafatun, wa mutawassithatun.',
        "Nawaitul wudhuu'a liraf'il hadatsil ashghari fardhan lillaahi ta'aalaa.",
        "Nawaaqidhul wudhuu'i arba'atu asy-yaa'a.",
      ],
    );
    expect(
      items.map((item) => item['arti']),
      [
        'Air yang menyucikan (air mutlak) adalah air yang suci pada dirinya sendiri dan dapat menyucikan benda lain.',
        'Najis itu terbagi menjadi tiga jenis: najis berat (mughallazhah), najis ringan (mukhaffafah), dan najis sedang (mutawassithah).',
        "Saya niat berwudhu untuk menghilangkan hadas kecil fardhu karena Allah Ta'ala.",
        'Hal-hal yang membatalkan wudhu ada empat perkara.',
      ],
    );
    expect(
      _pointTitles(items[2]),
      [
        '1. Niat di Dalam Hati',
        '2. Membasuh Seluruh Wajah',
        '3. Membasuh Kedua Tangan sampai Siku',
        '4. Mengusap Sebagian Kepala',
        '5. Membasuh Kedua Kaki sampai Mata Kaki',
        '6. Tertib (Berurutan)',
      ],
    );
    expect(
      MateriData.getPoinPenjelasan(items[1]).last['isiPenjelasan'],
      'Contohnya air liur atau sentuhan basah anjing dan babi. Cara menyucikannya: wajib dibasuh air suci sebanyak 7 kali, dan salah satunya dicampur dengan tanah/debu suci.',
    );
  });

  test('Bab 3 contains four structured cards with 4/5/3/4 points', () {
    final items = _itemsForChapter(3);

    expect(items, hasLength(4));
    expect(
      items.map((item) => item['judulKartu']),
      [
        'Waktu & Syarat Sah Shalat (Safinatun Najah)',
        'Rukun Shalat Fardhu (Safinatun Najah)',
        'Bacaan Pokok dalam Shalat',
        'Hal yang Membatalkan Shalat (Safinatun Najah)',
      ],
    );
    expect(
      items.map((item) => MateriData.getPoinPenjelasan(item).length),
      [4, 5, 3, 4],
    );
    expect(
      items.map((item) => item['teksArab']),
      [
        'شُرُوطُ الصَّلَاةِ ثَمَانِيَةٌ: طَهَارَةُ الْحَدَثَيْنِ، وَالطَّهَارَةُ عَنِ النَّجَاسَةِ فِي الثَّوْبِ وَالْبَدَنِ وَالْمَكَانِ، وَسَتْرُ الْعَوْرَةِ، وَاسْتِقْبَالُ الْقِبْلَةِ، وَدُخُولُ الْوَقْتِ',
        'أَرْكَانُ الصَّلَاةِ سَبْعَةَ عَشَرَ: الْأَوَّلُ النِّيَّةُ، الثَّانِي تَكْبِيرَةُ الْإِحْرَامِ، الثَّالِثُ الْقِيَامُ عَلَى الْقَادِرِ فِي الْفَرْضِ، الرَّابِعُ قِرَاءَةُ الْفَاتِحَةِ',
        'سُبْحَانَ رَبِّيَ الْعَظِيْمِ وَبِحَمْدِهِ  —  سُبْحَانَ رَبِّيَ الْأَعْلَى وَبِحَمْدِهِ',
        'تَبْطُلُ الصَّلَاةُ بِأَرْبَعَ عَشَرَةَ خَصْلَةً: بِالْحَدَثِ، وَبِوُقُوعِ النَّجَاسَةِ إِنْ لَمْ تُلْقَ حَالًا، وَانْكِشَافِ الْعَوْرَةِ',
      ],
    );
    expect(
      items.map((item) => item['teksLatin']),
      [
        "Syuruuthush shalaati tsamaaniyatun: Thahaaratul hadatsaini, wath thahaaratu 'anin najaasati fits tsaubi wal badani wal makaani, wa satrul 'aurati, wastiqbaalul qiblati, wa dukhuulul waqti.",
        "Arkaanush shalaati sab'ata 'asyara: Al-awwalun niyyatu, ats-tsaanii takbiiratul ihraami, ats-tsaalitsul qiyaamu 'alal qaadiri fil fardhi, ar-raabi'u qiraa'atul Faatihah.",
        "Subhaana rabbiyal 'azhiimi wa bihamdih — Subhaana rabbiyal a'laa wa bihamdih.",
        "Tabthulush shalaatu bi arba'a 'asyrata khashlatan: bil hadatsi, wa biwuquu'in najaasati in lam tulqa haalan, wankisyaafil 'aurati.",
      ],
    );
    expect(
      items.map((item) => item['arti']),
      [
        'Syarat sah shalat di antaranya suci dari dua hadas, suci pakaian/badan/tempat dari najis, menutup aurat, menghadap kiblat, dan masuk waktu shalat.',
        'Rukun shalat menurut kitab Safinatun Najah ada 17 perkara yang wajib dilakukan berurutan dengan thuma\'ninah (tenang sejenak).',
        'Maha Suci Tuhanku Yang Maha Agung dan segala puji bagi-Nya — Maha Suci Tuhanku Yang Maha Tinggi dan segala puji bagi-Nya.',
        'Shalat batal apabila berhadas, terkena najis yang tidak langsung disingkirkan, terbuka aurat, berbicara sengaja, makan/minum, atau bergerak 3 kali berturut-turut.',
      ],
    );
    expect(
      _pointTitles(items[1]),
      [
        'Niat, Takbiratul Ihram & Berdiri Tegak',
        'Membaca Surat Al-Fatihah',
        "Rukuk & I'tidal dengan Thuma'ninah",
        'Sujud Dua Kali & Duduk Antara Dua Sujud',
        'Tahiyat Akhir, Shalawat & Salam',
      ],
    );
    expect(
      MateriData.getPoinPenjelasan(items[1])[2]['isiPenjelasan'],
      'Membungkukkan badan hingga punggung rata dan tangan memegang lutut dengan tenang sejenak, lalu bangun berdiri tegak kembali.',
    );
  });

  test('Bab 4 contains three structured cards with 3/3/4 points', () {
    final items = _itemsForChapter(4);

    expect(items, hasLength(3));
    expect(
      items.map((item) => item['judulKartu']),
      [
        'Pengertian, Syarat & Niat Puasa Ramadhan (Safinatun Najah)',
        'Sunnah Puasa & Doa Berbuka Puasa',
        'Hal yang Membatalkan Puasa (Safinatun Najah)',
      ],
    );
    expect(
      items.map((item) => MateriData.getPoinPenjelasan(item).length),
      [3, 3, 4],
    );
    expect(
      items.map((item) => item['teksArab']),
      [
        'نَوَيْتُ صَوْمَ غَدٍ عَنْ أَدَاءِ فَرْضِ شَهْرِ رَمَضَانَ هٰذِهِ السَّنَةِ لِلّٰهِ تَعَالَى',
        'اَللّٰهُمَّ لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ بِرَحْمَتِكَ يَا أَرْحَمَ الرَّاحِمِيْنَ',
        'يَبْطُلُ الصَّوْمُ بِالرِّدَّةِ، وَالْحَيْضِ، وَالنِّفَاسِ، وَالْجُنُونِ وَلَوْ لَحْظَةً، وَبِالْإِغْمَاءِ وَالسُّكْرِ',
      ],
    );
    expect(
      items.map((item) => item['teksLatin']),
      [
        "Nawaitu shauma ghadin 'an adaa'i fardhi syahri Ramadhaana haadzihis sanati lillaahi ta'aalaa.",
        "Allaahumma laka shumtu wa bika aamantu wa 'alaa rizqika afthartu birahmatika yaa arhamar raahimiin.",
        "Yabthulush shaumu birriddati, wal haidhi, wan nifaasi, wal junuuni walau lahzhatan, wa bil ighmaa'i was sukri.",
      ],
    );
    expect(
      items.map((item) => item['arti']),
      [
        "Saya niat berpuasa esok hari untuk menunaikan kewajiban bulan Ramadhan tahun ini karena Allah Ta'ala.",
        'Ya Allah, karena-Mu aku berpuasa, kepada-Mu aku beriman, dan dengan rezeki-Mu aku berbuka, dengan rahmat-Mu wahai Tuhan Yang Maha Penyayang.',
        'Puasa menjadi batal apabila melakukan perkara yang merusak puasa seperti makan/minum dengan sengaja, muntah dengan sengaja, atau hilang akal sepanjang hari.',
      ],
    );
    expect(
      _pointTitles(items[0]),
      [
        'Apa itu Ibadah Puasa?',
        'Syarat Wajib & Sah Puasa (Safinatun Najah)',
        'Rukun Puasa (Niat Malam Hari)',
      ],
    );
    expect(
      _pointTitles(items[1]),
      [
        'Mengakhirkan Makan Sahur',
        'Menyegerakan Berbuka Puasa',
        'Menjaga Lisan & Memperbanyak Kebaikan',
      ],
    );
    expect(
      _pointTitles(items[2]),
      [
        'Makan dan Minum dengan Sengaja',
        'Muntah dengan Sengaja',
        'Memasukkan Benda ke Lubang Tubuh Terbuka',
        'Hilang Akal / Pingsan Sepanjang Hari',
      ],
    );
    expect(
      items.map(
        (item) => MateriData.getPoinPenjelasan(item)
            .map((point) => point['isiPenjelasan'])
            .toList(),
      ),
      [
        [
          'Menahan diri dari makan, minum, dan segala hal yang membatalkan puasa mulai terbit fajar (waktu Subuh) sampai terbenam matahari (waktu Maghrib) disertai niat karena Allah SWT.',
          'Puasa Ramadhan wajib bagi muslim yang baligh, berakal sehat, dan kuat berpuasa. Anak-anak usia 6–12 tahun sangat dianjurkan berlatih berpuasa sejak dini.',
          'Menurut kitab Safinatun Najah, niat puasa wajib dilakukan di malam hari sebelum adzan Subuh (misalnya setelah shalat Tarawih atau saat makan sahur).',
        ],
        [
          'Makan sahur sebelum Subuh sangat dianjurkan karena penuh keberkahan dan memberi tenaga untuk beribadah di siang hari.',
          'Begitu adzan Maghrib berkumandang, sunnah segera berbuka dengan kurma atau air putih sebelum melaksanakan shalat Maghrib.',
          "Saat berpuasa kita menjaga lisan dari berkata kasar atau berbohong serta memperbanyak membaca Al-Qur'an dan bersedekah.",
        ],
        [
          'Memasukkan makanan atau minuman ke mulut dan menelannya dengan sengaja membatalkan puasa. Namun jika makan/minum karena benar-benar lupa, puasanya tetap sah dan langsung dilanjutkan.',
          'Membuat diri sendiri muntah dengan sengaja membatalkan puasa, sedangkan muntah tidak sengaja karena sakit atau mual tidak membatalkan puasa.',
          'Memasukkan sesuatu dengan sengaja ke lubang terbuka seperti mulut, hidung bagian dalam, atau telinga bagian dalam.',
          'Pingsan terus-menerus sejak terbit fajar hingga terbenam matahari menyebabkan puasa di hari itu tidak sah.',
        ],
      ],
    );
    for (final item in items) {
      expect(item['poinPenjelasan'], isA<List>());
      expect(item['penjelasanAnak'], isNull);
    }
  });

  testWidgets('Bab 4 exposes the fourth fasting invalidation point',
      (tester) async {
    await _pumpDetail(tester, MateriData.dataBabBelajar[3], itemIndex: 2);

    expect(find.text('Hal yang Membatalkan Puasa'), findsOneWidget);
    expect(find.textContaining('(Safinatun Najah)'), findsNothing);

    await _reveal(tester, find.byKey(const ValueKey('point-button-3')));
    await tester.tap(find.byKey(const ValueKey('point-button-3')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-panel')),
        matching: find.text('Hilang Akal / Pingsan Sepanjang Hari'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-panel')),
        matching: find.text(
          'Pingsan terus-menerus sejak terbit fajar hingga terbenam matahari menyebabkan puasa di hari itu tidak sah.',
        ),
      ),
      findsOneWidget,
    );
  });

  test('Bab 5 is temporarily excluded from active learning material', () {
    expect(
      MateriData.dataBabBelajar.map((bab) => bab['bab']),
      [1, 2, 3, 4],
    );
  });

  testWidgets('learning menu shows Bab 1-4 boards without Bab 5',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      StorageService.keyKoin: 75,
      StorageService.keyNyawa: 2,
    });

    await tester.pumpWidget(const MaterialApp(home: BelajarScreen()));
    await _pumpBelajarFrames(tester);

    final background = tester.widget<Image>(
      find.byKey(const ValueKey('belajar-background')),
    );
    expect(
      (background.image as AssetImage).assetName,
      'assets/images/bg_menu_utama.png',
    );
    expect(find.text('Pilih Bab Pelajaran'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('belajar-coins')),
        matching: find.text('75'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('belajar-lives')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    const firstBoardKey = ValueKey('bab-board-1');
    final firstBoard = find.byKey(firstBoardKey);
    final screenHeight = MediaQuery.sizeOf(tester.element(firstBoard)).height;
    expect(
        tester.getSize(firstBoard).height, closeTo(screenHeight * 0.48, 0.1));
    final boardStack = tester.widget<Stack>(
      find.descendant(of: firstBoard, matching: find.byType(Stack)).first,
    );
    expect(boardStack.alignment, Alignment.center);
    final boardImage = tester.widget<Image>(
      find.byKey(const ValueKey('bab-board-image-1')),
    );
    expect(
      (boardImage.image as AssetImage).assetName,
      'assets/images/icon_bab.png',
    );
    expect(boardImage.fit, BoxFit.contain);
    expect(boardImage.errorBuilder, isNull);
    final headingFinder = find.descendant(
      of: firstBoard,
      matching: find.text('BAB 1'),
    );
    final subtitleFinder = find.descendant(
      of: firstBoard,
      matching: find.text('pondasi islam'),
    );
    final heading = tester.widget<Text>(headingFinder);
    final subtitle = tester.widget<Text>(subtitleFinder);
    expect(heading.textAlign, TextAlign.center);
    expect(heading.maxLines, 1);
    expect(heading.style?.fontWeight, FontWeight.w800);
    expect(heading.style?.color, const Color(0xFF5A3B1B));
    expect(heading.style?.fontSize, greaterThan(20));
    expect(subtitle.textAlign, TextAlign.center);
    expect(subtitle.maxLines, 2);
    expect(subtitle.style?.fontWeight, FontWeight.w700);
    expect(subtitle.style?.color, const Color(0xFF5A3B1B));
    expect(
      subtitle.style?.fontSize,
      lessThan(heading.style!.fontSize!),
    );
    expect(
      tester.getCenter(headingFinder).dx,
      closeTo(tester.getCenter(firstBoard).dx, 0.1),
    );
    expect(
      tester.getCenter(subtitleFinder).dx,
      closeTo(tester.getCenter(firstBoard).dx, 0.1),
    );
    final titleColumn = find.descendant(
      of: firstBoard,
      matching: find.byType(Column),
    ).first;
    final firstImage = find.byKey(const ValueKey('bab-board-image-1'));
    final imageRect = tester.getRect(firstImage);
    expect(
      tester.getCenter(titleColumn).dy,
      closeTo(imageRect.top + imageRect.height * 0.38, 0.1),
    );

    final startY = tester.getCenter(firstImage).dy;
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      tester.getCenter(firstImage).dy,
      isNot(closeTo(startY, 0.01)),
    );

    final gesture = await tester.startGesture(tester.getCenter(firstBoard));
    await tester.pump(const Duration(milliseconds: 160));
    final scaleFinder = find.descendant(
      of: firstBoard,
      matching: find.byType(AnimatedScale),
    );
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 0.95);
    await gesture.cancel();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1);

    for (var bab = 1; bab <= 4; bab++) {
      final board = find.byKey(ValueKey('bab-board-$bab'));
      await tester.scrollUntilVisible(
        board,
        300,
        scrollable: _materialScrollable(),
      );
      expect(find.textContaining('BAB $bab'), findsOneWidget);
      final floatingBuilder = tester.widget<AnimatedBuilder>(
        find.descendant(
          of: board,
          matching: find.byType(AnimatedBuilder),
        ).first,
      );
      expect(
        (floatingBuilder.animation as AnimationController).isAnimating,
        isTrue,
      );
      final chapterTitle =
          MateriData.dataBabBelajar[bab - 1]['judul'] as String;
      final subtitle = chapterTitle
          .split(RegExp(r':\s*'))
          .skip(1)
          .join(' ')
          .toLowerCase();
      expect(find.text(subtitle), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('bab-board-5')), findsNothing);
    expect(find.textContaining('Doa Harian'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigates chapter board to material board to explanation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: BelajarScreen()));
    await _pumpBelajarFrames(tester);

    await tester.tap(find.byKey(const ValueKey('bab-board-1')));
    await _pumpBelajarFrames(tester);

    expect(find.byType(SubMateriListScreen), findsOneWidget);
    expect(find.text('Bab 1: Pondasi Islam'), findsOneWidget);
    expect(find.byKey(const ValueKey('submateri-list')), findsOneWidget);
    final materialListFinder = find.byKey(const ValueKey('submateri-list'));
    final materialList = tester.widget<ListView>(materialListFinder);
    final listPadding = materialList.padding! as EdgeInsets;
    expect(listPadding.left, closeTo(listPadding.right, 0.1));
    final listRect = tester.getRect(materialListFinder);
    final firstMaterialRect = tester.getRect(
      find.byKey(const ValueKey('materi-board-0')),
    );
    final lastMaterialRect = tester.getRect(
      find.byKey(const ValueKey('materi-board-2')),
    );
    expect(
      (firstMaterialRect.left + lastMaterialRect.right) / 2,
      closeTo(listRect.center.dx, 0.1),
    );
    expect(firstMaterialRect.left, greaterThanOrEqualTo(listRect.left));
    expect(lastMaterialRect.right, lessThanOrEqualTo(listRect.right));
    expect(find.textContaining('(Safinatun Najah)'), findsNothing);
    final materialBoard = find.byKey(const ValueKey('materi-board-1'));
    final screenHeight =
        MediaQuery.sizeOf(tester.element(materialBoard)).height;
    expect(
      tester.getSize(materialBoard).height,
      lessThanOrEqualTo(screenHeight * 0.44 + 0.1),
    );
    final materialStack = tester.widget<Stack>(
      find.descendant(of: materialBoard, matching: find.byType(Stack)).first,
    );
    expect(materialStack.alignment, Alignment.center);
    final materialFloatingBuilder = tester.widget<AnimatedBuilder>(
      find.descendant(
        of: materialBoard,
        matching: find.byType(AnimatedBuilder),
      ).first,
    );
    expect(
      (materialFloatingBuilder.animation as AnimationController).isAnimating,
      isTrue,
    );
    final materialImage = tester.widget<Image>(
      find.byKey(const ValueKey('materi-board-image-1')),
    );
    expect(
      (materialImage.image as AssetImage).assetName,
      'assets/images/icon_materi.png',
    );
    expect(materialImage.fit, BoxFit.contain);
    expect(materialImage.errorBuilder, isNull);
    final materialTitle = tester.widget<Text>(
      find.descendant(
        of: materialBoard,
        matching: find.text('5 Rukun Islam'),
      ),
    );
    expect(materialTitle.style?.color, const Color(0xFF5A3B1B));

    await tester.tap(materialBoard);
    await _pumpBelajarFrames(tester);

    expect(find.byType(BelajarDetailScreen), findsOneWidget);
    expect(find.text('5 Rukun Islam'), findsOneWidget);
    expect(find.textContaining('(Safinatun Najah)'), findsNothing);
    expect(find.byKey(const ValueKey('materi-detail-board')), findsOneWidget);
    expect(find.byKey(const ValueKey('next-material-button')), findsNothing);
    final board = tester.widget<Container>(
      find.byKey(const ValueKey('materi-detail-board')),
    );
    final decoration = board.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(28));
    expect(decoration.color, const Color(0xFFFFFDF2));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await _pumpBelajarFrames(tester);
    expect(find.byType(SubMateriListScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await _pumpBelajarFrames(tester);
    expect(find.byType(BelajarScreen), findsOneWidget);
  });

  testWidgets('round Matan speaker reads the selected bacaan', (tester) async {
    await _pumpDetail(tester, MateriData.dataBabBelajar.first);

    final speaker = find.byKey(const ValueKey('matan-speaker-button'));
    await _reveal(tester, speaker);
    final material = tester.widget<Material>(speaker);
    expect(material.shape, isA<CircleBorder>());
    expect(material.color, const Color(0xFF149E53));
    expect(
      find.descendant(
        of: speaker,
        matching: find.byIcon(Icons.volume_up_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(speaker);
    await tester.pumpAndSettle();

    final item = _itemsForChapter(1).first;
    final speakCall = ttsCalls.lastWhere((call) => call.method == 'speak');
    expect(speakCall.arguments, '${item['teksLatin']}. ${item['arti']}');
  });

  testWidgets('shows Matan and concise points, then opens Zaid and TTS',
      (tester) async {
    await _pumpDetail(tester, MateriData.dataBabBelajar.first);

    expect(find.text('MATAN'), findsOneWidget);
    expect(find.text('Pilih poin untuk belajar'), findsOneWidget);
    expect(find.byKey(const ValueKey('point-button-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('point-button-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('point-button-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('character-panel')), findsNothing);
    expect(find.text('Syahadat adalah kalimat persaksian'), findsNothing);

    await _reveal(tester, find.byKey(const ValueKey('point-button-0')));
    await tester.tap(find.byKey(const ValueKey('point-button-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('character-panel')), findsOneWidget);
    expect(find.text('Zaid'), findsOneWidget);
    final panel = find.byKey(const ValueKey('character-panel'));
    expect(
      find.descendant(of: panel, matching: find.text('Apa itu Syahadat?')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: panel,
        matching: find.text(
          'Syahadat adalah kalimat persaksian dan janji setia seorang muslim, sekaligus pintu gerbang pertama masuk ke dalam agama Islam.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Image>(find.byKey(const ValueKey('guide-avatar-zaid')))
          .image,
      const AssetImage('assets/images/avatar_zaid.png'),
    );

    final ttsButton = find.byKey(const ValueKey('tts-speaker-button'));
    await _reveal(tester, ttsButton);
    await tester.tap(ttsButton);
    await tester.pumpAndSettle();

    final speakCall = ttsCalls.lastWhere((call) => call.method == 'speak');
    expect(
      speakCall.arguments,
      'Syahadat adalah kalimat persaksian dan janji setia seorang muslim, sekaligus pintu gerbang pertama masuk ke dalam agama Islam.',
    );

    final closeButton = find.byKey(const ValueKey('close-character-panel'));
    await _reveal(tester, closeButton);
    await tester.tap(closeButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('character-panel')), findsNothing);
  });

  testWidgets('uses Aisyah when the saved profile selects her', (tester) async {
    SharedPreferences.setMockInitialValues({
      StorageService.keyAvatar: 'aisyah',
    });

    await _pumpDetail(tester, MateriData.dataBabBelajar.first);
    await _reveal(tester, find.byKey(const ValueKey('point-button-0')));
    await tester.tap(find.byKey(const ValueKey('point-button-0')));
    await tester.pumpAndSettle();

    expect(find.text('Aisyah'), findsOneWidget);
    expect(
      tester
          .widget<Image>(find.byKey(const ValueKey('guide-avatar-aisyah')))
          .image,
      const AssetImage('assets/images/avatar_aisyah.png'),
    );
  });

  testWidgets('opens the selected Bab 1 material directly', (tester) async {
    await _pumpDetail(tester, MateriData.dataBabBelajar.first, itemIndex: 1);

    expect(find.text('5 Rukun Islam'), findsOneWidget);
    expect(find.text('Dua Kalimat Syahadat & Maknanya'), findsNothing);
    expect(find.byKey(const ValueKey('point-button-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('next-material-button')), findsNothing);

    await _reveal(tester, find.byKey(const ValueKey('point-button-4')));
    await tester.tap(find.byKey(const ValueKey('point-button-4')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-panel')),
        matching: find.text('5. Ibadah Haji bagi yang Mampu'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('completing Bab 1 refills two lives and celebrates',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      StorageService.keyAvatar: 'zaid',
      StorageService.keyNyawa: 1,
    });
    final storage = StorageService();
    await storage.init();
    await _pumpDetail(tester, MateriData.dataBabBelajar.first, itemIndex: 2);

    final completeButton = find.byKey(
      const ValueKey('complete-material-button'),
    );
    await _reveal(tester, completeButton);
    expect(find.text('Selesai Belajar (+2 ❤️ Nyawa)'), findsOneWidget);

    await tester.tap(completeButton);
    await tester.pumpAndSettle();

    expect(
      find.text('🎉 Alhamdulillah! +2 ❤️ Nyawa ditambahkan!'),
      findsOneWidget,
    );
    expect(await storage.getNyawa(), 3);
    expect(await storage.getProgres('bab_1_selesai'), isTrue);
  });

  testWidgets('Bab 1 point panel fits a narrow phone screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpDetail(tester, MateriData.dataBabBelajar.first, itemIndex: 2);
    await _reveal(tester, find.byKey(const ValueKey('point-button-5')));
    await tester.tap(find.byKey(const ValueKey('point-button-5')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('character-panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-panel')),
        matching: find.text('6. Iman kepada Qadha dan Qadar'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bab 2 exposes all six wudhu points to the character panel',
      (tester) async {
    await _pumpDetail(tester, MateriData.dataBabBelajar[1], itemIndex: 2);

    await _reveal(tester, find.byKey(const ValueKey('point-button-5')));
    await tester.tap(find.byKey(const ValueKey('point-button-5')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-panel')),
        matching: find.text('6. Tertib (Berurutan)'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Bab 3 exposes all five rukun shalat points', (tester) async {
    await _pumpDetail(tester, MateriData.dataBabBelajar[2], itemIndex: 1);

    await _reveal(tester, find.byKey(const ValueKey('point-button-4')));
    await tester.tap(find.byKey(const ValueKey('point-button-4')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-panel')),
        matching: find.text('Tahiyat Akhir, Shalawat & Salam'),
      ),
      findsOneWidget,
    );
  });

  for (final bab in MateriData.dataBabBelajar.skip(1)) {
    testWidgets('Bab ${bab['bab']} renders and opens its first point',
        (tester) async {
      await _pumpDetail(tester, bab);

      expect(find.text('MATAN'), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('point-button-0')));
      await tester.tap(find.byKey(const ValueKey('point-button-0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('character-panel')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

List<Map<String, dynamic>> _itemsForChapter(int chapter) {
  final bab = MateriData.dataBabBelajar.firstWhere(
    (item) => item['bab'] == chapter,
  );
  return (bab['items'] as List).cast<Map<String, dynamic>>();
}

List<String> _pointTitles(Map<String, dynamic> item) {
  return MateriData.getPoinPenjelasan(item)
      .map((point) => point['judulPoin'] as String)
      .toList();
}

Finder _materialScrollable() {
  return find.byType(Scrollable).last;
}

Future<void> _pumpBelajarFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpDetail(
  WidgetTester tester,
  Map<String, dynamic> bab, {
  int itemIndex = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BelajarDetailScreen(
        babIndex: (bab['bab'] as int) - 1,
        bab: bab,
        itemIndex: itemIndex,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
