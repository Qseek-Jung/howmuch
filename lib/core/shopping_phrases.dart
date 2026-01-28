class ShoppingPhrases {
  static const List<String> koreanPhrases = [
    "이거 얼마예요?",
    "너무 비싸요. 할인해 주세요.",
    "2개 사면 더 깎아주실 수 있어요?",
    "가장 인기 있는 제품이 뭐예요?",
    "입어봐도 돼요?",
    "이거 다른 색 있어요?",
    "너무 커요. 한 사이즈 작은 걸로 주세요.",
    "너무 작아요. 한 사이즈 큰 걸로 주세요.",
    "이거 새 제품으로 주세요.",
    "카드 되나요?",
    "현금 결제할테니까 할인 더 해줘요?",
    "택스 프리 가능해요?",
    "한국까지 가져가야하니 잘 포장해 주세요.",
  ];

  /// Map Currency Code to TTS Locale ID
  static const Map<String, String> ttsLocaleMap = {
    'KRW': 'ko-KR',
    'USD': 'en-US',
    'JPY': 'ja-JP',
    'CNY': 'zh-CN',
    'VND': 'vi-VN',
    'THB': 'th-TH',
    'IDR': 'id-ID',
    'PHP': 'en-PH',
    'SGD': 'en-SG',
    'TWD': 'zh-TW',
    'HKD': 'zh-HK',
    'EUR': 'en-US',
    'GBP': 'en-GB',
    'CHF': 'de-CH',
    'CAD': 'en-CA',
    'AUD': 'en-AU',
    'NZD': 'en-NZ',
  };

  /// Map Currency Code to List of Translated Phrases
  /// Indices must match [koreanPhrases]
  static const Map<String, List<String>> translations = {
    // English (USD, GBP, SGD, etc fallback)
    'en': [
      "How much is this?",
      "It's too expensive. Can you give me a discount?",
      "Can you give me a discount if I buy two?",
      "What is the most popular product?",
      "Can I try this on?",
      "Do you have this in another color?",
      "It's too big. Can I get a smaller size?",
      "It's too small. Can I get a larger size?",
      "Please give me a new one.",
      "Do you accept credit cards?",
      "Can you give me a discount if I pay in cash?",
      "Is Tax Free available?",
      "Please wrap it well for taking to Korea.",
    ],
    // Japanese (JPY)
    'JPY': [
      "これ、いくらですか？",
      "高いです。まけてください。",
      "2つ買ったら安くなりますか？",
      "一番人気の商品はどれですか？",
      "試着してもいいですか？",
      "これ、他の色はありますか？",
      "大きすぎます。小さいサイズをください。",
      "小さすぎます。大きいサイズをください。",
      "新しいものをください。",
      "クレジットカードは使えますか？",
      "現金で払うので、もっとまけてくれませんか？",
      "免税にはなりますか？",
      "韓国まで持っていくので、しっかり梱包してください。",
    ],
    // Chinese (CNY)
    'CNY': [
      "这个多少钱？",
      "太贵了。便宜点吧。",
      "买两个能便宜点吗？",
      "最受欢迎的产品是什么？",
      "我可以试穿吗？",
      "这个有别的颜色吗？",
      "太大了。请给我拿小一号的。",
      "太小了。请给我拿大一号的。",
      "请给我拿个新的。",
      "可以刷卡吗？",
      "付现金能再便宜点吗？",
      "可以退税吗？",
      "我要带回韩国，请帮我包好。",
    ],
    // Vietnamese (VND)
    'VND': [
      "Cái này bao nhiêu tiền?",
      "Đắt quá. Giảm giá cho tôi đi.",
      "Mua 2 cái có được giảm giá không?",
      "Sản phẩm nào được ưa chuộng nhất?",
      "Tôi có thể mặc thử không?",
      "Cái này có màu khác không?",
      "To quá. Cho tôi size nhỏ hơn.",
      "Nhỏ quá. Cho tôi size lớn hơn.",
      "Lấy cho tôi cái mới nhé.",
      "Có thanh toán bằng thẻ được không?",
      "Tôi trả tiền mặt thì có được giảm giá thêm không?",
      "Có được hoàn thuế không?",
      "Tôi mang về Hàn Quốc, gói kỹ giúp tôi nhé.",
    ],
    // Thai (THB)
    'THB': [
      "อันนี้เท่าไหร่ครับ/คะ",
      "แพงไปครับ/ค่ะ ลดหน่อยได้ไหม",
      "ซื้อ 2 อัน ลดได้ไหม",
      "สินค้าตัวไหนขายดีที่สุด",
      "ลองใส่ได้ไหม",
      "มีสีอื่นไหม",
      "ใหญ่เกินไป ขอไซส์เล็กกว่านี้หน่อย",
      "เล็กเกินไป ขอไซส์ใหญ่กว่านี้หน่อย",
      "ขอตัวใหม่ได้ไหม",
      "รับบัตรเครดิตไหม",
      "จ่ายเงินสด ลดเพิ่มได้ไหม",
      "คืนภาษีได้ไหม",
      "จะเอากลับเกาหลี ช่วยห่อให้ดีหน่อย",
    ],
    // Indonesian (IDR)
    'IDR': [
      "Berapa harga ini?",
      "Terlalu mahal. Tolong beri diskon.",
      "Kalau beli dua, bisa diskon?",
      "Produk apa yang paling populer?",
      "Boleh saya coba?",
      "Apakah ada warna lain?",
      "Terlalu besar. Tolong beri ukuran lebih kecil.",
      "Terlalu kecil. Tolong beri ukuran lebih besar.",
      "Tolong berikan yang baru.",
      "Bisa bayar pakai kartu?",
      "Kalau bayar tunai, bisa diskon lagi?",
      "Apakah bisa Tax Free?",
      "Tolong bungkus yang rapi, mau dibawa ke Korea.",
    ],
  };

  static List<String> getPhrasesFor(String currencyCode) {
    if (translations.containsKey(currencyCode)) {
      return translations[currencyCode]!;
    }
    // Specific Fallbacks
    if (currencyCode == 'USD' ||
        currencyCode == 'GBP' ||
        currencyCode == 'SGD' ||
        currencyCode == 'EUR' ||
        currencyCode == 'AUD' ||
        currencyCode == 'CAD' ||
        currencyCode == 'NZD' ||
        currencyCode == 'PHP') {
      return translations['en']!;
    }
    if (currencyCode == 'HKD' || currencyCode == 'TWD') {
      return translations['en']!;
    }

    // Default to English
    return translations['en']!;
  }
}
