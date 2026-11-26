import '../core/fisher_yates_shuffle.dart';

class BankSoal {
  static const List<String> islandNames = [
    'Pondasi Islam',
    'Thaharah',
    'Ibadah Shalat',
    'Ibadah Puasa',
    'Doa & Adab',
    'Ujian Akhir',
  ];

  static const List<List<String>> stageTitles = [
    ['Dua Kalimat Syahadat', 'Rukun Islam', 'Rukun Iman', 'Ujian Pulau 1'],
    ['Pengenalan Najis', 'Simulasi Wudhu', 'Studi Kasus Najis', 'Ujian Pulau 2'],
    ['Bacaan Dasar', 'Simulasi Shalat', 'Pembatal Shalat', 'Ujian Pulau 3'],
    ['Niat & Doa', 'Sunnah Puasa', 'Studi Kasus Puasa', 'Ujian Pulau 4'],
    ['Susun Doa', 'Tebak Arti', 'Adab Harian', 'Ujian Pulau 5'],
    ['Evaluasi Dasar', 'Evaluasi Lanjutan', 'Evaluasi Komprehensif', 'Ujian Akhir'],
  ];

  static const List<String> badgeNames = [
    'Duta Rukun\nIslam',
    'Ahli\nThaharah',
    'Santri Taat\nShalat',
    'Pejuang\nRamadhan',
    'Anak Shalih\n& Beradab',
    'Santri Cilik\nTeladan',
  ];

  static String islandName(int pulauId) =>
      islandNames[(pulauId - 1).clamp(0, islandNames.length - 1)];

  static String stageTitle(int pulauId, int tahap) =>
      stageTitles[(pulauId - 1).clamp(0, stageTitles.length - 1)]
          [(tahap - 1).clamp(0, 3)];

  static String badgeName(int pulauId) =>
      badgeNames[(pulauId - 1).clamp(0, badgeNames.length - 1)];

  static final List<Map<String, dynamic>> bank = [
    // Pulau 1 - Pondasi Islam
    {'id': 'p1_t1_q1', 'pulauId': 1, 'tahap': 1, 'pertanyaan': 'Apa rukun Islam pertama?', 'opsi': ['Syahadat', 'Shalat', 'Zakat', 'Puasa'], 'jawabanBenar': 0},
    {'id': 'p1_t1_q2', 'pulauId': 1, 'tahap': 1, 'pertanyaan': 'Berapa jumlah rukun iman?', 'opsi': ['5', '6', '7', '8'], 'jawabanBenar': 1},
    {'id': 'p1_t1_q3', 'pulauId': 1, 'tahap': 1, 'pertanyaan': 'Siapa nabi terakhir yang diutus Allah?', 'opsi': ['Isa', 'Musa', 'Muhammad', 'Ibrahim'], 'jawabanBenar': 2},
    {'id': 'p1_t1_q4', 'pulauId': 1, 'tahap': 1, 'pertanyaan': 'Apa rukun Islam kedua?', 'opsi': ['Zakat', 'Puasa', 'Shalat', 'Haji'], 'jawabanBenar': 2},
    {'id': 'p1_t2_q1', 'pulauId': 1, 'tahap': 2, 'pertanyaan': 'Apa arti kata syahadat?', 'opsi': ['Bersaksi', 'Berdoa', 'Bersedekah', 'Berpuasa'], 'jawabanBenar': 0},
    {'id': 'p1_t2_q2', 'pulauId': 1, 'tahap': 2, 'pertanyaan': 'Apa rukun Islam kelima?', 'opsi': ['Zakat', 'Puasa', 'Haji', 'Shalat'], 'jawabanBenar': 2},
    {'id': 'p1_t2_q3', 'pulauId': 1, 'tahap': 2, 'pertanyaan': 'Rukun iman pertama adalah iman kepada?', 'opsi': ['Malaikat', 'Allah', 'Kitab', 'Hari akhir'], 'jawabanBenar': 1},
    {'id': 'p1_t2_q4', 'pulauId': 1, 'tahap': 2, 'pertanyaan': 'Kitab Taurat diturunkan kepada nabi?', 'opsi': ['Isa', 'Musa', 'Daud', 'Ibrahim'], 'jawabanBenar': 1},
    {'id': 'p1_t3_q1', 'pulauId': 1, 'tahap': 3, 'pertanyaan': 'Malaikat Mikail dikenal sebagai malaikat yang?', 'opsi': ['Membawa wahyu', 'Mencabut nyawa', 'Membagi rezeki', 'Meniup sangkakala'], 'jawabanBenar': 2},
    {'id': 'p1_t3_q2', 'pulauId': 1, 'tahap': 3, 'pertanyaan': 'Malaikat Jibril bertugas utama?', 'opsi': ['Membawa rezeki', 'Membawa wahyu', 'Mencabut nyawa', 'Menjaga surga'], 'jawabanBenar': 1},
    {'id': 'p1_t3_q3', 'pulauId': 1, 'tahap': 3, 'pertanyaan': 'Iman kepada qada dan qadar termasuk iman kepada?', 'opsi': ['Takdir', 'Rasul', 'Kitab', 'Malaikat'], 'jawabanBenar': 0},
    {'id': 'p1_t3_q4', 'pulauId': 1, 'tahap': 3, 'pertanyaan': 'Berapa jumlah nabi dan rasul yang wajib kita ketahui?', 'opsi': ['10', '20', '25', '30'], 'jawabanBenar': 2},
    {'id': 'p1_t4_q1', 'pulauId': 1, 'tahap': 4, 'pertanyaan': 'Apa rukun Islam keempat?', 'opsi': ['Zakat', 'Puasa', 'Haji', 'Shalat'], 'jawabanBenar': 1},
    {'id': 'p1_t4_q2', 'pulauId': 1, 'tahap': 4, 'pertanyaan': 'Hari pembalasan amal manusia disebut?', 'opsi': ['Yaumul Hisab', 'Yaumul Jumat', 'Yaumul Arafah', 'Yaumul Tasyrik'], 'jawabanBenar': 0},
    {'id': 'p1_t4_q3', 'pulauId': 1, 'tahap': 4, 'pertanyaan': 'Iman kepada kitab Allah merupakan rukun iman ke?', 'opsi': ['Pertama', 'Kedua', 'Ketiga', 'Keempat'], 'jawabanBenar': 2},
    {'id': 'p1_t4_q4', 'pulauId': 1, 'tahap': 4, 'pertanyaan': 'Nabi yang menerima kitab Injil adalah?', 'opsi': ['Musa', 'Daud', 'Isa', 'Nuh'], 'jawabanBenar': 2},
    // Pulau 2 - Thaharah
    {'id': 9, 'pulauId': 2, 'tahap': 1, 'pertanyaan': 'Air suci disebut?', 'opsi': ['Ma thahur', 'Ma mutlaq', 'Ma mubah', 'Ma makruh'], 'jawabanBenar': 0},
    {'id': 10, 'pulauId': 2, 'tahap': 1, 'pertanyaan': 'Najis ringan (mukhaffafah) contohnya?', 'opsi': ['Air kencing bayi', 'Darah', 'Kotoran', 'Najis berat'], 'jawabanBenar': 0},
    {'id': 11, 'pulauId': 2, 'tahap': 1, 'pertanyaan': 'Rukun wudhu yang pertama adalah?', 'opsi': ['Niat', 'Membasuh muka', 'Membasuh tangan', 'Mengusap kepala'], 'jawabanBenar': 0},
    {'id': 12, 'pulauId': 2, 'tahap': 2, 'pertanyaan': 'Najis berat (mughallazhah) disucikan dengan?', 'opsi': ['Air 7 kali', 'Air 3 kali', 'Tanah', 'Api'], 'jawabanBenar': 0},
    {'id': 13, 'pulauId': 2, 'tahap': 2, 'pertanyaan': 'Wudhu batal jika?', 'opsi': ['Berkedip', 'Buang air kecil', 'Makan', 'Minum'], 'jawabanBenar': 1},
    {'id': 14, 'pulauId': 2, 'tahap': 3, 'pertanyaan': 'Najis sedang (mutawassithah) dibersihkan dengan?', 'opsi': ['Air 7 kali', 'Air hingga hilang warna/bau/rasa', 'Tanah', 'Api'], 'jawabanBenar': 1},
    {'id': 15, 'pulauId': 2, 'tahap': 3, 'pertanyaan': 'Air yang suci dan menyucikan disebut?', 'opsi': ['Ma mutlaq', 'Ma thahur', 'Ma mubah', 'Ma makruh'], 'jawabanBenar': 1},
    {'id': 16, 'pulauId': 2, 'tahap': 4, 'pertanyaan': 'Bersentuhan kulit laki-laki dan perempuan bukan mahram membatalkan wudhu?', 'opsi': ['Ya', 'Tidak', 'Kadang', 'Tergantung'], 'jawabanBenar': 0},
    // Pulau 3 - Shalat
    {'id': 17, 'pulauId': 3, 'tahap': 1, 'pertanyaan': 'Syarat sah shalat salah satunya?', 'opsi': ['Makan', 'Tidur', 'Suci', 'Bermain'], 'jawabanBenar': 2},
    {'id': 18, 'pulauId': 3, 'tahap': 1, 'pertanyaan': 'Gerakan setelah takbir adalah?', 'opsi': ['Rukuk', 'Sujud', 'Bacaan', 'Salam'], 'jawabanBenar': 2},
    {'id': 19, 'pulauId': 3, 'tahap': 2, 'pertanyaan': 'Shalat batal jika?', 'opsi': ['Khusyuk', 'Berbicara', 'Niat', 'Tuma\'ninah'], 'jawabanBenar': 1},
    {'id': 20, 'pulauId': 3, 'tahap': 2, 'pertanyaan': 'Jumlah rakaat shalat Maghrib?', 'opsi': ['2', '3', '4', '5'], 'jawabanBenar': 1},
    {'id': 21, 'pulauId': 3, 'tahap': 3, 'pertanyaan': 'Shalat fardhu wajib berapa kali sehari?', 'opsi': ['3', '4', '5', '6'], 'jawabanBenar': 2},
    {'id': 22, 'pulauId': 3, 'tahap': 3, 'pertanyaan': 'Takbiratul Ihram dilakukan dengan?', 'opsi': ['Mengangkat tangan', 'Menunduk', 'Duduk', 'Sujud'], 'jawabanBenar': 0},
    {'id': 23, 'pulauId': 3, 'tahap': 4, 'pertanyaan': 'Rukuk dilakukan dengan?', 'opsi': ['Berdiri', 'Menunduk', 'Duduk', 'Sujud'], 'jawabanBenar': 1},
    {'id': 24, 'pulauId': 3, 'tahap': 4, 'pertanyaan': 'Sujud dilakukan berapa kali dalam satu rakaat?', 'opsi': ['1', '2', '3', '4'], 'jawabanBenar': 1},
    // Pulau 4 - Puasa
    {'id': 25, 'pulauId': 4, 'tahap': 1, 'pertanyaan': 'Niat puasa dilakukan?', 'opsi': ['Saat berbuka', 'Sebelum fajar', 'Saat sahur', 'Saat siang'], 'jawabanBenar': 1},
    {'id': 26, 'pulauId': 4, 'tahap': 1, 'pertanyaan': 'Doa berbuka dimulai dengan?', 'opsi': ['Bismillah', 'Allahumma', 'Subhanallah', 'Alhamdulillah'], 'jawabanBenar': 1},
    {'id': 27, 'pulauId': 4, 'tahap': 2, 'pertanyaan': 'Sunnah puasa adalah?', 'opsi': ['Makan siang', 'Sahur', 'Tidur', 'Bermain'], 'jawabanBenar': 1},
    {'id': 28, 'pulauId': 4, 'tahap': 2, 'pertanyaan': 'Puasa batal jika?', 'opsi': ['Makan', 'Tidur', 'Dzikir', 'Shalat'], 'jawabanBenar': 0},
    {'id': 29, 'pulauId': 4, 'tahap': 3, 'pertanyaan': 'Bulan puasa adalah?', 'opsi': ['Syawal', 'Ramadhan', 'Dzulhijjah', 'Muharram'], 'jawabanBenar': 1},
    {'id': 30, 'pulauId': 4, 'tahap': 3, 'pertanyaan': 'Puasa sunnah Senin-Kamis dilakukan?', 'opsi': ['Setiap hari', 'Senin & Kamis', 'Jumat saja', 'Sabtu saja'], 'jawabanBenar': 1},
    {'id': 31, 'pulauId': 4, 'tahap': 4, 'pertanyaan': 'Muntah dengan sengaja membatalkan puasa?', 'opsi': ['Ya', 'Tidak', 'Kadang', 'Tergantung'], 'jawabanBenar': 0},
    {'id': 32, 'pulauId': 4, 'tahap': 4, 'pertanyaan': 'Sahur sunnah dilakukan?', 'opsi': ['Sore hari', 'Malam hari', 'Pagi hari', 'Siang hari'], 'jawabanBenar': 2},
    // Pulau 5 - Doa & Adab
    {'id': 33, 'pulauId': 5, 'tahap': 1, 'pertanyaan': 'Doa sebelum makan adalah?', 'opsi': ['Bismillah', 'Alhamdulillah', 'Subhanallah', 'Allahu Akbar'], 'jawabanBenar': 0},
    {'id': 34, 'pulauId': 5, 'tahap': 1, 'pertanyaan': 'Doa tidur dimulai dengan?', 'opsi': ['Allahumma', 'Bismillah', 'Subhanallah', 'Alhamdulillah'], 'jawabanBenar': 0},
    {'id': 35, 'pulauId': 5, 'tahap': 2, 'pertanyaan': 'Doa untuk orang tua adalah?', 'opsi': ['Rabbighfir li', 'Bismillah', 'Alhamdulillah', 'Subhanallah'], 'jawabanBenar': 0},
    {'id': 36, 'pulauId': 5, 'tahap': 2, 'pertanyaan': 'Adab masuk masjid adalah?', 'opsi': ['Berlari', 'Berbicara keras', "Membaca ta'awudz", 'Makan'], 'jawabanBenar': 2},
    {'id': 37, 'pulauId': 5, 'tahap': 3, 'pertanyaan': 'Adab terhadap guru adalah?', 'opsi': ['Membantah', 'Menghormati', 'Mengabaikan', 'Melawan'], 'jawabanBenar': 1},
    {'id': 38, 'pulauId': 5, 'tahap': 3, 'pertanyaan': 'Doa masuk masjid dimulai dengan?', 'opsi': ['Bismillah', 'Allahumma', 'Subhanallah', 'Alhamdulillah'], 'jawabanBenar': 1},
    {'id': 39, 'pulauId': 5, 'tahap': 4, 'pertanyaan': 'Mendahulukan kaki kanan saat masuk masjid adalah?', 'opsi': ['Sunnah', 'Wajib', 'Makruh', 'Haram'], 'jawabanBenar': 0},
    {'id': 40, 'pulauId': 5, 'tahap': 4, 'pertanyaan': 'Doa keluar masjid adalah?', 'opsi': ['Bismillah', 'Allahumma inni as\'aluka', 'Subhanallah', 'Alhamdulillah'], 'jawabanBenar': 1},
  ];

  static List<Map<String, dynamic>> getSoalPulau(int pulauId) {
    if (pulauId == 6) {
      final combined = bank.where((question) => question['pulauId'] != 6).toList();
      return FisherYatesShuffler.acakDaftarSoal(combined).take(10).toList();
    }
    final filtered = bank.where((question) => question['pulauId'] == pulauId).toList();
    return FisherYatesShuffler.acakDaftarSoal(filtered);
  }

  static List<Map<String, dynamic>> getSoalTahap(int pulauId, int tahap) {
    if (pulauId < 1 || pulauId > 6 || tahap < 1 || tahap > 4) {
      return [];
    }
    if (pulauId == 6) {
      return getSoalPulau(6);
    }
    final filtered = bank
        .where((question) =>
            question['pulauId'] == pulauId && question['tahap'] == tahap)
        .toList();
    return FisherYatesShuffler.acakDaftarSoal(filtered);
  }
}