import 'package:alarm/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AwarenessPage extends StatelessWidget {
  const AwarenessPage({super.key});

  final List<Map<String, String>> tips = const [
    {
      "title": "Mavi Işık Tuzağı",
      "summary": "Uyku kalitenizi bozan dijital düşman ile nasıl başa çıkılır?",
      "detail": '''
📱 Mavi ışık melatonin hormonu üretimini %50'den fazla baskılar.

• Yatmadan en az 60-90 dakika önce ekranla olan bağınızı koparın.
• İş veya ödev için mecbursanız: Gece modu + en düşük parlaklık + kırmızı filtre kullanın.
• Telefon/tablet alırken OLED veya AMOLED ekranlı modelleri tercih edin; klasik LCD'lere göre 3-4 kat daha az mavi ışık yayarlar.
• "Gece Modu" yazılımları sadece renk sıcaklığını değiştirir, parlaklık hâlâ retinaya zarar verir. En etkili çözüm: Mavi ışık kesici fiziksel gözlük + karanlık oda kombinasyonudur.
'''
    },
    {
      "title": "90 Dakika Sihri",
      "summary": "Hafif uykuda uyan, güne dinç başla! Bilimin desteklediği uyku hesaplama yöntemi",
      "detail": '''
🧠 Uyku mimarisi nedir?  
Uykumuz 90 dakikalık döngülerden oluşur. Ortalama bir gece uykusu 4–6 döngü (yaklaşık 6–9 saat) içerir. Her döngü şu 3 temel evreden geçer:

• Hafif uyku (N1–N2): Gözler kapanır, nabız yavaşlar. Uykuya geçiş evresidir.  
• Derin uyku (N3 – SWS): Vücut onarımı başlar. Bağışıklık sistemi, kaslar ve doku yenilenir.  
• REM uykusu: Beyin aktifleşir, rüyalar görülür. Öğrenme, hafıza, duygusal denge ve yaratıcılık bu evrede güçlenir.

💡REM ve Derin uyku neden önemlidir?  
• REM evresinde gün içinde öğrendikleriniz uzun süreli hafızaya aktarılır.  
• Derin uykuda büyüme hormonu salgılanır, beyin toksinlerden arınır, bağışıklık sistemi güçlenir.  
• Her iki evre yeterince alınmadığında zihinsel bulanıklık, unutkanlık ve bağışıklık zayıflığı görülebilir.

🔔Uyku döngüsü hesaplama:  
Yatış saatinizden itibaren her 90 dakikada bir döngü tamamlanır.  
Örneğin:  
Saat 00:00’da uyursanız → 06:00, 07:30, 09:00 gibi saatlerde uyanmak, döngü sonuna denk geldiği için en verimli zamandır.

🛌Neden döngü sonunda uyanmalıyız?  
Derin uykudan aniden uyanmak "uyku sarhoşluğu" yapar.  
Hafif uykuda uyanırsanız, zihniniz daha berrak olur ve güne daha hızlı adapte olursunuz.

⌚Teknoloji desteği (akıllı saatler):  
Bazı akıllı saatler (örneğin Apple Watch, Galaxy Watch, Fitbit) uykunuzu izler ve sizi REM veya derin uykuda değil, hafif uykuda uyandırmaya çalışır.  
Bu sayede alarm çaldığında kendinizi daha az yorgun hissedersiniz.

📱Uygulama önerisi:  
Telefonunuza “Sleep Cycle”, “Pillow” veya “Sleep as Android” gibi uygulamalar kurarak uyku döngülerinizi analiz edebilir, uyanış zamanınızı optimize edebilirsiniz.
Henüz uygulamamız bu kadar gelişmiş özelliklere sahip değil:)
'''
    },

    {
      "title": "Uykunun Gizli Kahramanları",
      "summary": "REM ve derin uyku: Zihinsel ve fiziksel sağlığın anahtarları",
      "detail": '''
🧠 Derin uyku (SWS) faydaları:  
• Vücut hücreleriniz yenilenir, kaslarınız onarılır.
• Büyüme hormonu bu evrede salgılanır.
• Bağışıklık sisteminizi güçlendiren proteinler üretilir.
• Alzheimer riskiyle ilişkili beta-amiloid plaklarının temizlenmesi hızlanır.

🌀 REM uykusu faydaları:
• Gün içinde öğrendiğiniz bilgileri kalıcı hafızaya aktarır.
• Duygusal travmaları işler, stres hormonlarını dengeler.
• Yaratıcı problem çözme yeteneğinizi %30'dan fazla artırır.

⚠️ Önemli not: Derin uyku gecenin ilk yarısında, REM ise son yarısında yoğunlaşır. Bu yüzden "az uyudum ama REM aldım" düşüncesi yanıltıcıdır - vücudunuz derin uyku evresinden mahrum kalır.
'''
    },
    {
      "title": "Sabah Güneşi Ritüeli",
      "summary": "Kahveden daha güçlü enerji kaynağı: 10 dakika doğal ışık",
      "detail": '''
🌞 Sabah güneşinin sihirli dokunuşu

• Gözlerinizin ipRGC hücreleri 10.000-30.000 lüks şiddetindeki doğal ışıkla uyarılır (ev içi aydınlatma sadece 300 lüks civarındadır).
• Etkisi: Kortizol seviyeniz yükselir → enerji ve odak artar.
• Melatonin hormonu baskılanır → vücut saatiniz "aktif mod"a geçer.
• Bu sabah ritüeli, akşam melatonin salgısını 14-16 saat sonra otomatik başlatır → uyku kaliteniz artar.

💡 Pratik öneri: Bulutlu havada bile dışarıda geçirilen 10 dakika, en parlak iç mekan LED aydınlatmasından 10 kat daha fazla ışık almanızı sağlar. Sabah kahvaltısını balkonda yapmayı veya işe/okula yürüyerek gitmeyi deneyin!
'''
    },
    {
      "title": "Kafein Kesme Noktası",
      "summary": "Son kahvenin kritik saati: Uyku kalitenizi %20 artıran ipucu",
      "detail": '''
☕ Kafein biyolojisi: Vücudunuzdan tam olarak çıkmaz

• Kafeinin yarılanma ömrü ortalama 5-6 saattir.
• Örnek: Saat 17:00'de içtiğiniz bir kahve, gece 23:00'te hâlâ %50 oranında kanınızda dolaşır.
• Araştırma sonucu: Geç saatte alınan kafein, derin uyku sürenizi %20 oranında kısaltır.

⏰ Pratik çözüm: Kafein kesme saatinizi belirleyin - uyumayı planladığınız saatten en az 8-10 saat önce. Telefonunuza bu saati hatırlatıcı olarak ekleyin.

🟢 Kafein alternatifleri: Öğleden sonra enerji için 30 dakikalık tempolu yürüyüş, parlak yeşil doğal ışığa maruz kalma (500 lüks) veya naneli sakız çiğnemek - bunlar beyin oksijenlenmesini artırır ama uyku düzeninizi bozmaz.
'''
    },
    {
      "title": "Uyku Öncesi Ritüel",
      "summary": "10 dakikalık rahatlama tekniği: Uyku sürenizi 30 dakika uzatın",
      "detail": '''
🧘 Beyin geçiş rutini oluşturun

• Uyku öncesi düzenli bir ritüel, beyninize "kapanma zamanı" sinyali verir.
• Bilimsel etki: Parasempatik sinir sisteminiz devreye girer, stres hormonları düşer.

✅ Basit ve etkili akşam ritüeli:
• Hafif germe veya nefes egzersizleri (4-7-8 tekniği: 4 saniye nefes al, 7 saniye tut, 8 saniye ver)
• Işıkları kıs veya sıcak tonda kullan (sarı/turuncu)
• Yarım saat kitap oku (elektronik değil, basılı kitap)
• Sıcak duş al - vücut ısısının sonraki düşüşü uyku hormonlarını tetikler
• Günlük tut: Üç şükran konusu yaz

🔬 Araştırma sonucu: Düzenli uygulanan akşam ritüeli, uyku süresini ortalama 30 dakika uzatır ve gece uyanma sayısını %60 azaltır.
'''
    },
    {
      "title": "Sıcaklık Kontrolü",
      "summary": "İdeal uyku için oda sıcaklığı: Bilimin önerdiği derece",
      "detail": '''
🌡️ Vücut ısısı ve uyku ilişkisi

• Uyku için beyin ve vücut sıcaklığının 1-1.5°C düşmesi gerekir.
• İdeal uyku odası sıcaklığı: 18-19°C (Araştırmalarla kanıtlanmış)
• Çok sıcak odalar (22°C üzeri) derin uyku süresini %30'a kadar azaltır!

🛏️ Pratik çözümler:
• Termostat kullanın veya odanızı yatmadan önce havalandırın
• "Chilipad" gibi sıcaklık kontrollü yatak ekipmanları derin uyku süresini artırır
• Üşüyorsanız: El ve ayakları ısıtın ama vücut çekirdeğini serin tutun (kalın çorap + ince battaniye kombinasyonu)

💡 İlginç bilgi: Sabaha karşı saat 4–5 civarında vücut ısısı minimum seviyeye iner. Bu evrede çekirdek sıcaklığınız, gün içindeki ortalamasından yaklaşık 0.5–1.0°C daha düşük olur ve genellikle 36.0°C civarına kadar gerileyebilir. Bu nedenle bu saatlerde uyanırsanız üşüme hissi yaşamanız biyolojik olarak doğaldır.
'''
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("🧠 Uyku Farkındalıkları")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return GestureDetector(
            onTap: () => _showDetail(context, tip),
            child: Card(
              color: AppColors.surface,
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              child: ListTile(
                title: Text(tip["title"]!,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(tip["summary"]!,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
                trailing: const Icon(Icons.keyboard_arrow_right,
                    color: AppColors.textDisabled),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext ctx, Map<String, String> tip) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(tip["title"]!,
                  style: const TextStyle(
                      fontSize: 22,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(tip["detail"]!,
                  style:
                  const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
