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
    // Traditional Chinese (TWD, HKD)
    'zh-TW': [
      "請問這個多少錢？",
      "太貴了。能不能便宜一點？",
      "如果買兩個，可以打折嗎？",
      "最受歡迎的產品是什麼？",
      "我可以試穿嗎？",
      "這個有其他的顏色嗎？",
      "太大了。請給我小一號的。",
      "太小了。請給我大一號的。",
      "請給我一個新的。",
      "可以刷卡嗎？",
      "如果付現的話，可以再便宜一點嗎？",
      "可以退稅嗎？",
      "我要帶回韓國，請幫我包好。",
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
    // Spanish (EUR - Spain, USD - parts of Americas, MXN, ARS, CLP, COP, etc.)
    'es': [
      "¿Cuánto cuesta esto?",
      "Es demasiado caro. ¿Me puede dar un descuento?",
      "¿Me da un descuento si compro dos?",
      "¿Cuál es el producto más popular?",
      "¿Puedo probármelo?",
      "¿Tiene esto en otro color?",
      "Es demasiado grande. ¿Puedo tener una talla más pequeña?",
      "Es demasiado pequeño. ¿Puedo tener una talla más grande?",
      "Por favor, deme uno nuevo.",
      "¿Aceptan tarjetas de crédito?",
      "¿Me da un descuento si pago en efectivo?",
      "¿Está disponible libre de impuestos?",
      "Por favor, envuélvalo bien para llevarlo a Corea.",
    ],
    // French (EUR - France, CAD - Quebec, West Africa, etc.)
    'fr': [
      "Combien ça coûte ?",
      "C'est trop cher. Pouvez-vous me faire une remise ?",
      "Pouvez-vous me faire une remise si j'en achète deux ?",
      "Quel est le produit le plus populaire ?",
      "Puis-je l'essayer ?",
      "Avez-vous ceci dans une autre couleur ?",
      "C'est trop grand. Puis-je avoir une taille en dessous ?",
      "C'est trop petit. Puis-je avoir une taille au-dessus ?",
      "S'il vous plaît, donnez-m'en un nouveau.",
      "Acceptez-vous les cartes de crédit ?",
      "Pouvez-vous me faire une remise si je paie en espèces ?",
      "La détaxe est-elle possible ?",
      "S'il vous plaît, emballez-le bien pour l'emporter en Corée.",
    ],
    // German (EUR - Germany/Austria, CHF - Switzerland)
    'de': [
      "Wie viel kostet das?",
      "Das ist zu teuer. Können Sie mir einen Rabatt geben?",
      "Gibt es einen Rabatt, wenn ich zwei kaufe?",
      "Was ist das beliebteste Produkt?",
      "Kann ich das anprobieren?",
      "Haben Sie das in einer anderen Farbe?",
      "Das ist zu groß. Kann ich eine Nummer kleiner haben?",
      "Das ist zu klein. Kann ich eine Nummer größer haben?",
      "Bitte geben Sie mir ein neues Exemplar.",
      "Akzeptieren Sie Kreditkarten?",
      "Gibt es einen Rabatt, wenn ich bar bezahle?",
      "Ist Tax-Free möglich?",
      "Bitte gut verpacken, ich nehme es mit nach Korea.",
    ],
    // Italian (EUR - Italy)
    'it': [
      "Quanto costa questo?",
      "È troppo caro. Mi può fare uno sconto?",
      "Mi fa uno sconto se ne compro due?",
      "Qual è il prodotto più popolare?",
      "Posso provarlo?",
      "Lo avete in un altro colore?",
      "È troppo grande. Posso avere una taglia in meno?",
      "È troppo piccolo. Posso avere una taglia in più?",
      "Per favore, me ne dia uno nuovo.",
      "Accettate carte di credito?",
      "Mi fa uno sconto se pago in contanti?",
      "È disponibile il Tax-Free?",
      "Per favore, lo imballi bene per portarlo in Corea.",
    ],
    // Portuguese (EUR - Portugal, BRL - Brazil)
    'pt': [
      "Quanto custa isto?",
      "É muito caro. Pode dar-me um desconto?",
      "Dá-me um desconto se eu comprar dois?",
      "Qual é o produto mais popular?",
      "Posso experimentar?",
      "Tem isto noutra cor?",
      "É muito grande. Posso levar um tamanho abaixo?",
      "É muito pequeno. Posso levar um tamanho acima?",
      "Por favor, dê-me um novo.",
      "Aceitam cartões de crédito?",
      "Dá-me um desconto se eu pagar em dinheiro?",
      "É possível fazer Tax-Free?",
      "Por favor, embrulhe bem para levar para a Coreia.",
    ],
    // Russian (RUB, CIS countries)
    'ru': [
      "Сколько это стоит?",
      "Это слишком дорого. Можете сделать скидку?",
      "Сделаете скидку, если я куплю два?",
      "Какой товар самый популярный?",
      "Можно это примерить?",
      "У вас есть это в другом цвете?",
      "Это слишком велико. Можно на размер меньше?",
      "Это слишком мало. Можно на размер больше?",
      "Пожалуйста, дайте мне новый экземпляр.",
      "Вы принимаете кредитные карты?",
      "Сделаете скидку, если я заплачу наличными?",
      "Можно оформить Tax-Free?",
      "Пожалуйста, хорошо упакуйте для перевозки в Корею.",
    ],
    // Arabic (AED, SAR, QAR, EGP, etc.)
    'ar': [
      "بكم هذا؟",
      "هذا غالٍ جداً. هل يمكنك إعطائي خصم؟",
      "هل يمكنك إعطائي خصم إذا اشتريت اثنين؟",
      "ما هو المنتج الأكثر شعبية؟",
      "هل يمكنني قياس هذا؟",
      "هل لديك هذا بلون آخر؟",
      "هذا كبير جداً. هل يمكنني الحصول على مقاس أصغر؟",
      "هذا صغير جداً. هل يمكنني الحصول على مقاس أكبر؟",
      "من فضلك أعطني واحداً جديداً.",
      "هل تقبلون البطاقات الائتمانية؟",
      "هل تعطيني خصماً إذا دفعت نقداً؟",
      "هل خدمة الإعفاء الضريبي متاحة؟",
      "يرجى تغليفه جيداً لأخذه إلى كوريا.",
    ],
    // Turkish (TRY)
    'tr': [
      "Bu ne kadar?",
      "Çok pahalı. İndirim yapabilir misiniz?",
      "İki tane alırsam indirim yapar mısınız?",
      "En popüler ürün hangisi?",
      "Bunu deneyebilir miyim?",
      "Bunun başka rengi var mı?",
      "Bu çok büyük. Bir beden küçüğünü alabilir miyim?",
      "Bu çok küçük. Bir beden büyüğünü alabilir miyim?",
      "Lütfen bana yenisini verin.",
      "Kredi kartı kabul ediyor musunuz?",
      "Nakit ödersem indirim olur mu?",
      "Tax Free (Vergi İadesi) var mı?",
      "Kore'ye götüreceğim, lütfen güzelce paketleyin.",
    ],
    // Polish (PLN)
    'pl': [
      "Ile to kosztuje?",
      "To za drogo. Czy mogę prosić o rabat?",
      "Czy dostanę zniżkę, jeśli kupię dwa?",
      "Jaki jest najpopularniejszy produkt?",
      "Czy mogę to przymierzyć?",
      "Czy jest ten produkt w innym kolorze?",
      "To jest za duże. Czy mogę prosić mniejszy rozmiar?",
      "To jest za małe. Czy mogę prosić większy rozmiar?",
      "Proszę o nową sztukę.",
      "Czy akceptujecie karty kredytowe?",
      "Czy dostanę zniżkę płacąc gotówką?",
      "Czy jest możliwość zwrotu podatku (Tax Free)?",
      "Proszę to dobrze zapakować, zabieram to do Korei.",
    ],
    // Czech (CZK)
    'cs': [
      "Kolik to stojí?",
      "To je moc drahé. Můžete mi dát slevu?",
      "Dostanu slevu, když koupím dva?",
      "Jaký je nejoblíbenější produkt?",
      "Můžu si to vyzkoušet?",
      "Máte to v jiné barvě?",
      "Je to moc velké. Můžu dostat menší velikost?",
      "Je to moc malé. Můžu dostat větší velikost?",
      "Prosím, dejte mi nový kus.",
      "Berete kreditní karty?",
      "Dostanu slevu při platbě v hotovosti?",
      "Je možné Tax Free?",
      "Prosím, dobře to zabalte, beru to do Koreje.",
    ],
    // Hungarian (HUF)
    'hu': [
      "Mennyibe kerül?",
      "Ez túl drága. Kaphatok kedvezményt?",
      "Kapok kedvezményt, ha kettőt veszek?",
      "Melyik a legnépszerűbb termék?",
      "Felpróbálhatom?",
      "Van ez más színben?",
      "Ez túl nagy. Kaphatok kisebbet?",
      "Ez túl kicsi. Kaphatok nagyobbat?",
      "Kérem, adjon egy újat.",
      "Elfogadnak hitelkártyát?",
      "Kapok kedvezményt, ha készpénzzel fizetek?",
      "Van lehetőség Tax Free-re?",
      "Kérem, csomagolja be jól, Koreába viszem.",
    ],
    // Swedish (SEK)
    'sv': [
      "Hur mycket kostar den här?",
      "Det är för dyrt. Kan du ge mig rabatt?",
      "Får jag rabatt om jag köper två?",
      "Vilken är den mest populära produkten?",
      "Kan jag prova den?",
      "Finns den i en annan färg?",
      "Den är för stor. Kan jag få en mindre storlek?",
      "Den är för liten. Kan jag få en större storlek?",
      "Snälla ge mig en ny.",
      "Tar ni kreditkort?",
      "Kan jag få rabatt om jag betalar kontant?",
      "Är det Tax Free?",
      "Snälla slå in det väl, jag ska ta det till Korea.",
    ],
    // Norwegian (NOK)
    'no': [
      "Hvor my koster denne?",
      "Det er for dyrt. Kan du gi meg en rabatt?",
      "Får jeg rabatt hvis jeg kjøper to?",
      "Hvilket produkt er mest populært?",
      "Kan jeg prøve den?",
      "Har du denne i en annen farge?",
      "Den er for stor. Kan jeg få en mindre størrelse?",
      "Den er for liten. Kan jeg få en større størrelse?",
      "Kan jeg få en ny, vær så snill?",
      "Tar dere kredittkort?",
      "Kan jeg få rabatt hvis jeg betaler kontant?",
      "Er det Tax Free mulig?",
      "Vennligst pakk det godt inn, jeg skal ta det med til Korea.",
    ],
    // Danish (DKK)
    'da': [
      "Hvor meget koster det?",
      "Det er for dyrt. Kan du give mig rabat?",
      "Kan du give rabat, hvis jeg køber to?",
      "Hvad er det mest populære produkt?",
      "Må jeg prøve det?",
      "Har I den i en anden farve?",
      "Den er for stor. Kan jeg få en mindre størrelse?",
      "Den er for lille. Kan jeg få en større størrelse?",
      "Jeg vil gerne have en ny.",
      "Tager I imod kreditkort?",
      "Kan jeg få rabat, hvis jeg betaler kontant?",
      "Er Tax Free muligt?",
      "Pak det venligst godt ind, jeg skal have det med til Korea.",
    ],
    // Finnish (EUR - Finland)
    'fi': [
      "Paljonko tämä maksaa?",
      "Se on liian kallis. Voitteko antaa alennusta?",
      "Saanko alennusta, jos ostan kaksi?",
      "Mikä on suosituin tuote?",
      "Voinko sovittaa tätä?",
      "Onko tätä toisen värisenä?",
      "Se on liian iso. Saanko pienemmän koon?",
      "Se on liian pieni. Saanko suuremman koon?",
      "Antaisitteko minulle uuden kappaleen.",
      "Hyväksyttekö luottokortin?",
      "Saanko alennusta, jos maksan käteisellä?",
      "Onko Tax Free mahdollista?",
      "Pakatkaa se hyvin, vien sen Koreaan.",
    ],
    // Dutch (EUR - Netherlands, Belgium)
    'nl': [
      "Hoeveel kost dit?",
      "Het is te duur. Kunt u korting geven?",
      "Krijg ik korting als ik er twee koop?",
      "Wat is het populairste product?",
      "Mag ik dit passen?",
      "Heeft u dit in een andere kleur?",
      "Het is te groot. Mag ik een maatje kleiner?",
      "Het is te klein. Mag ik een maatje groter?",
      "Mag ik een nieuwe, alstublieft?",
      "Accepteert u creditcards?",
      "Krijg ik korting als ik contant betaal?",
      "Is Tax Free mogelijk?",
      "Kunt u het goed inpakken voor de reis naar Korea?",
    ],
    // Greek (EUR - Greece)
    'el': [
      "Πόσο κοστίζει αυτό;",
      "Είναι πολύ ακριβό. Μπορείτε να μου κάνετε έκπτωση;",
      "Αν πάρω δύο, θα μου κάνετε καλύτερη τιμή;",
      "Ποιο είναι το πιο δημοφιλές προϊόν;",
      "Μπορώ να το δοκιμάσω;",
      "Το έχετε σε άλλο χρώμα;",
      "Είναι πολύ μεγάλο. Έχετε μικρότερο νούμερο;",
      "Είναι πολύ μικρό. Έχετε μεγαλύτερο νούμερο;",
      "Μου δίνετε ένα καινούργιο, παρακαλώ;",
      "Δέχεστε πιστωτικές κάρτες;",
      "Αν πληρώσω με μετρητά, έχω έκπτωση;",
      "Μπορώ να πάρω Tax Free;",
      "Παρακαλώ συσκευάστε το καλά, θα το πάρω στην Κορέα.",
    ],
    // Hebrew (ILS)
    'he': [
      "כמה זה עולה?",
      "זה יקר מדי. אפשר לקבל הנחה?",
      "אפשר הנחה אם אני קונה שניים?",
      "מהו המוצר הכי פופולרי?",
      "אפשר למדוד?",
      "יש לכם את זה בצבע אחר?",
      "זה גדול מדי. אפשר מידה קטנה יותר?",
      "זה קטן מדי. אפשר מידה גדולה יותר?",
      "אפשר לקבל אחד חדש בבקשה?",
      "אתם מקבלים כרטיסי אשראי?",
      "יש הנחה למזומן?",
      "האם יש החזר מס (Tax Free)?",
      "בבקשה תארזו טוב, אני לוקח את זה לקוריאה.",
    ],
    // Romanian (RON)
    'ro': [
      "Cât costă asta?",
      "Este prea scump. Îmi puteți face o reducere?",
      "Îmi faceți o reducere dacă cumpăr două?",
      "Care este cel mai popular produs?",
      "Pot să probez?",
      "Aveți asta în altă culoare?",
      "Este prea mare. Pot primi o mărime mai mică?",
      "Este prea mic. Pot primi o mărime mai mare?",
      "Vă rog să-mi dați unul nou.",
      "Acceptați carduri de credit?",
      "Îmi faceți o reducere dacă plătesc cash?",
      "Este posibil Tax Free?",
      "Vă rog să-l împachetați bine, îl duc în Coreea.",
    ],
    // Mongolian (MNT)
    'MN': [
      "Энэ ямар үнэтэй вэ?",
      "Хэтэрхий үнэтэй байна. Хямдруулж өгөөч.",
      "Хоёр ширхэгийг авбал хямдруулах уу?",
      "Хамгийн их борлуулалттай бүтээгдэхүүн юу вэ?",
      "Би үүнийг өмсөж үзэж болох уу?",
      "Үүнээс өөр өнгө байгаа юу?",
      "Хэтэрхий том байна. Жижиг размер байгаа юу?",
      "Хэтэрхий жижиг байна. Том размер байгаа юу?",
      "Шинэ ижилхэнийг өгөөч.",
      "Картаар тооцоо хийж болох уу?",
      "Бэлнээр төлбөл хямдруулах уу?",
      "Татварын хөнгөлөлт (Tax Free) боломжтой юу?",
      "Солонгос руу авч явах тул сайн баглаж өгөөрэй.",
    ],
    // Hindi (INR)
    'hi': [
      "यह कितने का है?",
      "यह बहुत महँगा है। क्या आप कुछ छूट दे सकते हैं?",
      "अगर मैं दो खरीदूँ तो क्या आप छूट देंगे?",
      "सबसे लोकप्रिय उत्पाद क्या है?",
      "क्या मैं इसे पहनकर देख सकता हूँ?",
      "क्या आपके पास इसमें दूसरा रंग है?",
      "यह बहुत बड़ा है। क्या मुझे छोटा आकार मिल सकता है?",
      "यह बहुत छोटा है। क्या मुझे बड़ा आकार मिल सकता है?",
      "कृपया मुझे एक नया दें।",
      "क्या आप क्रेडिट कार्ड स्वीकार करते हैं?",
      "अगर मैं नकद भुगतान करूँ तो क्या छूट मिलेगी?",
      "क्या टैक्स फ्री उपलब्ध है?",
      "कृपया इसे अच्छी तरह से पैक करें क्योंकि मुझे इसे कोरिया ले जाना है।",
    ],
  };

  /// Map Country Code to TTS Locale ID
  static const Map<String, String> countryToTTSLocale = {
    // Asia
    'KR': 'ko-KR', 'JP': 'ja-JP', 'CN': 'zh-CN', 'TW': 'zh-TW',
    'HK': 'zh-HK', 'VN': 'vi-VN', 'TH': 'th-TH', 'ID': 'id-ID',
    'MY': 'ms-MY', 'IN': 'hi-IN', 'PK': 'ur-PK', 'BD': 'bn-BD',
    'LK': 'ta-LK', 'PH': 'en-PH', 'SG': 'en-SG',
    // Europe
    'GB': 'en-GB', 'IE': 'en-IE', 'FR': 'fr-FR', 'DE': 'de-DE',
    'IT': 'it-IT', 'ES': 'es-ES', 'PT': 'pt-PT', 'NL': 'nl-NL',
    'RU': 'ru-RU', 'PL': 'pl-PL', 'TR': 'tr-TR', 'CZ': 'cs-CZ',
    'HU': 'hu-HU', 'RO': 'ro-RO', 'SE': 'sv-SE', 'NO': 'nb-NO',
    'DK': 'da-DK', 'FI': 'fi-FI', 'GR': 'el-GR', 'UA': 'uk-UA',
    'SK': 'sk-SK', 'HR': 'hr-HR', 'CH': 'de-CH', 'AT': 'de-AT',
    'BE': 'fr-BE',
    // Americas
    'US': 'en-US', 'CA': 'en-CA', 'MX': 'es-MX', 'BR': 'pt-BR',
    'AR': 'es-AR', 'CO': 'es-CO', 'CL': 'es-CL', 'PE': 'es-PE',
    // Middle East
    'SA': 'ar-SA', 'AE': 'ar-AE', 'QA': 'ar-QA', 'EG': 'ar-EG',
    'IL': 'he-IL',
    // Missing & Others
    'MN': 'mn-MN', 'AU': 'en-AU', 'NZ': 'en-NZ',
    'KZ': 'ru-KZ', 'KG': 'ru-KG',
    'UZ': 'ru-UZ', 'BY': 'ru-BY',
    // Default Fallbacks for others can be handled by logic
  };

  static String getTTSLocale(String uniqueId) {
    final parts = uniqueId.split(':');
    // We assume uniqueId is "Name:Code" (New) or "Code:Name" (Migration handling)
    String name = parts[0];
    String code = parts.length > 1 ? parts[1] : parts[0];

    // Check if parts[0] is code (legacy)
    if (RegExp(r'^[A-Z]{3}$').hasMatch(parts[0])) {
      code = parts[0];
      name = parts.length > 1 ? parts[1] : parts[0];
    }

    // 1. Try Country Name Map (Specific for TTS)
    // Create a reverse map if needed or just use code lookup for now if country code is not available
    // But better to use the country name directly if we can mapping it to country code.

    // For now, let's keep it simple: extract country name and match
    return _getLocaleByCountryName(name) ?? _getLocaleByCurrencyCode(code);
  }

  static String? _getLocaleByCountryName(String name) {
    const nameMap = {
      '대한민국': 'ko-KR',
      '일본': 'ja-JP',
      '중국': 'zh-CN',
      '대만': 'zh-TW',
      '홍콩': 'zh-HK',
      '베트남': 'vi-VN',
      '태국': 'th-TH',
      '인도네시아': 'id-ID',
      '말레이시아': 'ms-MY',
      '인도': 'hi-IN',
      '필리핀': 'en-PH',
      '싱가포르': 'en-SG',
      '영국': 'en-GB',
      '아일랜드': 'en-IE',
      '프랑스': 'fr-FR',
      '독일': 'de-DE',
      '이탈리아': 'it-IT',
      '스페인': 'es-ES',
      '포르투갈': 'pt-PT',
      '네덜란드': 'nl-NL',
      '러시아': 'ru-RU',
      '폴란드': 'pl-PL',
      '튀르키예': 'tr-TR',
      '체코': 'cs-CZ',
      '헝가리': 'hu-HU',
      '루마니아': 'ro-RO',
      '스웨덴': 'sv-SE',
      '노르웨이': 'nb-NO',
      '덴마크': 'da-DK',
      '핀란드': 'fi-FI',
      '그리스': 'el-GR',
      '우크라이나': 'uk-UA',
      '오스트리아': 'de-AT',
      '벨기에': 'fr-BE',
      '스위스': 'de-CH',
      '미국': 'en-US',
      '캐나다': 'en-CA',
      '멕시코': 'es-MX',
      '브라질': 'pt-BR',
      '호주': 'en-AU',
      '뉴질랜드': 'en-NZ',
      '몽골': 'mn-MN',
    };
    return nameMap[name];
  }

  static String _getLocaleByCurrencyCode(String code) {
    const currencyMap = {
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
      'RUB': 'ru-RU',
      'TRY': 'tr-TR',
      'PLN': 'pl-PL',
    };
    return currencyMap[code] ?? 'en-US';
  }

  /// Get language code (e.g., 'en', 'es') for Phrase Lookup
  static String getLanguageCode(String uniqueId) {
    final parts = uniqueId.split(':');
    String name = parts[0];
    String code = parts.length > 1 ? parts[1] : parts[0];

    if (RegExp(r'^[A-Z]{3}$').hasMatch(parts[0])) {
      code = parts[0];
      name = parts.length > 1 ? parts[1] : parts[0];
    }

    // Priority: Country Name based mapping
    final langByCountry = _getLangByCountryName(name);
    if (langByCountry != null) return langByCountry;

    // Fallback: Currency based mapping
    const currencyMap = {
      'TWD': 'zh-TW',
      'HKD': 'zh-TW',
      'CNY': 'CNY',
      'JPY': 'JPY',
      'VND': 'VND',
      'THB': 'THB',
      'IDR': 'IDR',
      'KRW': 'ko',
      'EUR': 'en',
      'GBP': 'en',
      'USD': 'en',
    };
    return currencyMap[code] ?? 'en';
  }

  static String? _getLangByCountryName(String name) {
    if (['스페인', '멕시코', '아르헨티나', '콜롬비아', '칠레', '페루'].contains(name)) return 'es';
    if (['프랑스', '벨기에', '룩셈부르크', '모나코'].contains(name)) return 'fr';
    if (['독일', '오스트리아', '스위스'].contains(name)) return 'de';
    if (['대만', '홍콩', '마카오'].contains(name)) return 'zh-TW';
    if (['일본'].contains(name)) return 'JPY';
    if (['중국'].contains(name)) return 'CNY';
    if (['베트남'].contains(name)) return 'VND';
    if (['태국'].contains(name)) return 'THB';
    if (['인도네시아'].contains(name)) return 'IDR';
    if (['이탈리아'].contains(name)) return 'it';
    if (['포르투갈', '브라질'].contains(name)) return 'pt';
    if (['러시아', '카자흐스탄', '벨라루스'].contains(name)) return 'ru';
    if (['튀르키예'].contains(name)) return 'tr';
    if (['폴란드'].contains(name)) return 'pl';
    if (['체코'].contains(name)) return 'cs';
    if (['헝가리'].contains(name)) return 'hu';
    if (['스웨덴'].contains(name)) return 'sv';
    if (['노르웨이'].contains(name)) return 'no';
    if (['덴마크'].contains(name)) return 'da';
    if (['핀란드'].contains(name)) return 'fi';
    if (['네덜란드'].contains(name)) return 'nl';
    if (['그리스'].contains(name)) return 'el';
    if (['이스라엘'].contains(name)) return 'he';
    if (['루마니아'].contains(name)) return 'ro';
    if (['몽골'].contains(name)) return 'MN';
    if (['인도'].contains(name)) return 'hi';
    if (['미국', '영국', '호주', '캐나다', '뉴질랜드', '싱가포르', '필리핀'].contains(name))
      return 'en';
    return null;
  }

  static List<String> getPhrasesFor(String uniqueId) {
    final lang = getLanguageCode(uniqueId);
    return translations[lang] ?? translations['en']!;
  }
}
