import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbukids/core/storage_service.dart';
import 'package:qalbukids/data/materi_data.dart';
import 'package:qalbukids/screens/belajar_detail_screen.dart';
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
    await _pumpDetail(tester, MateriData.dataBabBelajar[3]);
    await tester.tap(find.byKey(const ValueKey('next-material-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-material-button')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('point-button-3')),
      200,
      scrollable: _materialScrollable(),
    );
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

  test('Bab 5 contains ten structured daily prayer cards', () {
    final items = _itemsForChapter(5);

    expect(items, hasLength(10));
    expect(
      items.map((item) => item['judulKartu']),
      [
        'Doa Sebelum Makan',
        'Doa Sesudah Makan',
        'Doa Sebelum Tidur',
        'Doa Bangun Tidur',
        'Doa untuk Kedua Orang Tua',
        'Doa Sebelum Belajar',
        'Doa Masuk Kamar Mandi (WC)',
        'Doa Keluar Kamar Mandi (WC)',
        'Doa Keluar Rumah',
        'Doa Masuk Masjid',
      ],
    );
    expect(
      items.map((item) => MateriData.getPoinPenjelasan(item).length),
      List.filled(10, 2),
    );
    expect(
      items.map((item) => item['teksArab']),
      [
        'اَللّٰهُمَّ بَارِكْ لَنَا فِيْمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ',
        'اَلْحَمْدُ لِلّٰهِ الَّذِيْ اَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِيْنَ',
        'بِسْمِكَ اللّٰهُمَّ اَحْيَا وَبِسْمِكَ اَمُوْتُ',
        'اَلْحَمْدُ لِلّٰهِ الَّذِيْ اَحْيَانَا بَعْدَ مَا اَمَاتَنَا وَاِلَيْهِ النُّشُوْرُ',
        'رَبِّ اغْفِرْ لِيْ وَلِوَالِدَيَّ وَارْحَمْهُمَا كَمَا رَبَّيَانِيْ صَغِيْرًا',
        'رَبِّ زِدْنِيْ عِلْمًا وَارْزُقْنِيْ فَهْمًا',
        'اَللّٰهُمَّ اِنِّيْ اَعُوْذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ',
        'غُفْرَانَكَ اَلْحَمْدُ لِلّٰهِ الَّذِيْ اَذْهَبَ عَنِّي الْاَذَى وَعَافَانِيْ',
        'بِسْمِ اللّٰهِ تَوَكَّلْتُ عَلَى اللّٰهِ لَا حَوْلَ وَلَا قُوَّةَ اِلَّا بِاللّٰهِ',
        'اَللّٰهُمَّ افْتَحْ لِيْ اَبْوَابَ رَحْمَتِكَ',
      ],
    );
    expect(
      items.map((item) => item['teksLatin']),
      [
        "Allaahumma baarik lanaa fiimaa razaqtanaa wa qinaa 'adzaaban naar.",
        "Alhamdulillaahil ladzii ath'amanaa wa saqaanaa wa ja'alanaa muslimiin.",
        'Bismikallaahumma ahyaa wa bismika amuut.',
        "Alhamdulillaahil ladzii ahyaanaa ba'da maa amaatanaa wa ilaihin nusyuur.",
        'Rabbighfir lii wa liwaalidayya warhamhumaa kamaa rabbayaanii shaghiiraa.',
        "Rabbi zidnii 'ilmaa warzuqnii fahmaa.",
        "Allaahumma innii a'uudzu bika minal khubutsi wal khabaa'its.",
        "Ghufraanaka alhamdulillaahil ladzii adzhaba 'annil adzaa wa 'aafaanii.",
        "Bismillaahi tawakkaltu 'alallaahi laa haula wa laa quwwata illaa billaah.",
        'Allaahummaftah lii abwaaba rahmatik.',
      ],
    );
    expect(
      items.map((item) => item['arti']),
      [
        'Ya Allah, berkahilah kami dalam rezeki yang telah Engkau berikan kepada kami dan peliharalah kami dari siksa api neraka.',
        'Segala puji bagi Allah yang telah memberi kami makan dan minum serta menjadikan kami orang-orang muslim.',
        'Dengan menyebut nama-Mu ya Allah aku hidup, dan dengan menyebut nama-Mu aku mati.',
        'Segala puji bagi Allah yang telah menghidupkan kami kembali setelah mematikan kami, dan hanya kepada-Nya kami dibangkitkan.',
        'Ya Tuhanku, ampunilah dosaku dan dosa kedua orang tuaku, serta sayangilah keduanya sebagaimana mereka menyayangiku di waktu kecil.',
        'Ya Tuhanku, tambahkanlah ilmu kepadaku dan berilah aku pemahaman yang baik.',
        'Ya Allah, sesungguhnya aku berlindung kepada-Mu dari godaan setan laki-laki dan setan perempuan.',
        'Aku memohon ampunan-Mu ya Allah, segala puji bagi Allah yang telah menghilangkan kotoran dariku dan menyehatkanku.',
        'Dengan menyebut nama Allah aku bertawakal kepada Allah, tiada daya dan kekuatan melainkan dengan pertolongan Allah.',
        'Ya Allah, bukakanlah untukku pintu-pintu rahmat-Mu.',
      ],
    );
    expect(
      items.map(_pointTitles),
      [
        ['Waktu Membaca', 'Adab Makan'],
        ['Bersyukur Setelah Kenyang', 'Adab Selesai Makan'],
        ['Perlindungan Saat Tidur', 'Adab Sebelum Tidur'],
        ['Syukur di Pagi Hari', 'Adab Bangun Tidur'],
        ['Bakti Anak Shalih', 'Adab kepada Orang Tua'],
        ['Memohon Ilmu Bermanfaat', 'Adab Menuntut Ilmu'],
        ['Adab Masuk Kamar Mandi', 'Larangan di Kamar Mandi'],
        ['Adab Keluar Kamar Mandi', 'Menjaga Kebersihan'],
        ['Perlindungan di Perjalanan', 'Adab Keluar Rumah'],
        ['Adab Masuk Masjid', 'Menjaga Ketenangan'],
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
          'Dibaca tepat sebelum mulai menyuap makanan atau minuman.',
          'Mencuci tangan, duduk tenang, memakai tangan kanan, dan tidak mencela makanan.',
        ],
        [
          'Bentuk rasa terima kasih kepada Allah atas nikmat makanan dan minuman.',
          'Menghabiskan makanan tanpa bersisa, mencuci tangan, dan membantu merapikan piring.',
        ],
        [
          'Menyerahkan diri kepada Allah agar dijaga dari gangguan mimpi buruk.',
          'Berwudhu terlebih dahulu, membersihkan tempat tidur, dan berbaring miring ke kanan.',
        ],
        [
          'Bersyukur kepada Allah karena masih diberi kesempatan bangun dan beribadah.',
          'Mengusap wajah, merapikan bantal dan selimut sendiri, lalu segera berwudhu untuk shalat Subuh.',
        ],
        [
          'Doa ini sangat dianjurkan dibaca setiap selesai shalat fardhu 5 waktu.',
          'Berbicara lembut, mematuhi nasihat baik ayah dan ibu, serta membantu di rumah.',
        ],
        [
          'Dibaca sebelum mulai belajar di sekolah, TPQ, maupun di rumah.',
          'Duduk rapi, mendengarkan guru atau ustadz dengan tenang, dan rajin mengulang pelajaran.',
        ],
        [
          'Dibaca sebelum masuk ke dalam WC dan melangkah mendahulukan kaki kiri.',
          "Tidak membawa tulisan ayat Al-Qur'an dan tidak berbicara di dalam kamar mandi.",
        ],
        [
          'Melangkah keluar mendahulukan kaki kanan lalu membaca doa ini.',
          'Pastikan WC sudah disiram bersih dan air keran ditutup rapat sebelum keluar.',
        ],
        [
          'Allah menjaga langkah anak muslim yang membaca doa ini saat berangkat sekolah atau mengaji.',
          'Berpamitan dan mencium tangan orang tua serta melangkah dengan kaki kanan.',
        ],
        [
          'Mendahulukan kaki kanan saat masuk ke masjid sambil membaca doa ini.',
          'Menjaga kebersihan masjid, tidak berlarian, dan menunaikan shalat tahiyatul masjid.',
        ],
      ],
    );
    for (final item in items) {
      expect(item['poinPenjelasan'], isA<List>());
      expect(item['penjelasanAnak'], isNull);
    }
  });

  testWidgets('Bab 5 navigates to the tenth prayer and opens its second point',
      (tester) async {
    await _pumpDetail(tester, MateriData.dataBabBelajar[4]);

    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byKey(const ValueKey('next-material-button')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Doa Masuk Masjid'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('point-button-1')),
      200,
      scrollable: _materialScrollable(),
    );
    await tester.tap(find.byKey(const ValueKey('point-button-1')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-panel')),
        matching: find.text('Menjaga Ketenangan'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-panel')),
        matching: find.text(
          'Menjaga kebersihan masjid, tidak berlarian, dan menunaikan shalat tahiyatul masjid.',
        ),
      ),
      findsOneWidget,
    );
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

    await tester.tap(find.byKey(const ValueKey('tts-speaker-button')));
    await tester.pumpAndSettle();

    final speakCall = ttsCalls.lastWhere((call) => call.method == 'speak');
    expect(
      speakCall.arguments,
      'Syahadat adalah kalimat persaksian dan janji setia seorang muslim, sekaligus pintu gerbang pertama masuk ke dalam agama Islam.',
    );

    await tester.tap(find.byKey(const ValueKey('close-character-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('character-panel')), findsNothing);
  });

  testWidgets('uses Aisyah when the saved profile selects her', (tester) async {
    SharedPreferences.setMockInitialValues({
      StorageService.keyAvatar: 'aisyah',
    });

    await _pumpDetail(tester, MateriData.dataBabBelajar.first);
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

  testWidgets('navigates all three Bab 1 cards', (tester) async {
    await _pumpDetail(tester, MateriData.dataBabBelajar.first);

    await tester.tap(find.byKey(const ValueKey('next-material-button')));
    await tester.pumpAndSettle();
    expect(find.text('5 Rukun Islam (Safinatun Najah)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('point-button-4')),
      200,
      scrollable: _materialScrollable(),
    );

    await tester.tap(find.byKey(const ValueKey('point-button-4')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-panel')),
        matching: find.text('5. Ibadah Haji bagi yang Mampu'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('next-material-button')));
    await tester.pumpAndSettle();
    expect(find.text('6 Rukun Iman (Safinatun Najah)'), findsOneWidget);
    expect(find.byKey(const ValueKey('point-button-5')), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets('Bab 1 point panel fits a narrow phone screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpDetail(tester, MateriData.dataBabBelajar.first);
    await tester.tap(find.byKey(const ValueKey('next-material-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-material-button')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('point-button-5')),
      200,
      scrollable: _materialScrollable(),
    );
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
    await _pumpDetail(tester, MateriData.dataBabBelajar[1]);
    await tester.tap(find.byKey(const ValueKey('next-material-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-material-button')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('point-button-5')),
      200,
      scrollable: _materialScrollable(),
    );
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
    await _pumpDetail(tester, MateriData.dataBabBelajar[2]);
    await tester.tap(find.byKey(const ValueKey('next-material-button')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('point-button-4')),
      200,
      scrollable: _materialScrollable(),
    );
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
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('point-button-0')),
        200,
        scrollable: _materialScrollable(),
      );
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

Future<void> _pumpDetail(
  WidgetTester tester,
  Map<String, dynamic> bab,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BelajarDetailScreen(
        babIndex: (bab['bab'] as int) - 1,
        bab: bab,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
