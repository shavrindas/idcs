# Foydalanuvchi baholash so'rovnomasi — reja

Bu fayl — IDCS loyihasini real foydalanuvchilar (IDCool va uning mijozlari, masalan 다온)
orqali baholashni tashkillashtirish rejasi. Ikki bosqichli: **1차 (hozir, yengil)** va
**2차 (V2 tugagach, jiddiy)**.

## 1. Kimdan so'raymiz — ikki xil auditoriya

Ular bir xil savolga qiziqmaydi, shuning uchun ikkita qisqa variant kerak:

| Auditoriya | Nimaga qiziqadi | Vaqt imkoniyati |
|---|---|---|
| **IDCool xodimlari** (admin/veb ishlatuvchilar) | Ko'p sittingni boshqarish, mijoz bilan aloqa, vaqt tejash | Yaxshi — ular loyihaga yaqin |
| **Sitting mijozlari** (masalan 다온) — ilova ishlatuvchilar | Tushunarli-mi, alarm foydalimi, IDCool bilan aloqa osonmi | Kam — band, uzoq so'rovga vaqt yo'q |

**Muhim qoida**: mijozlarga (다온 kabi) og'ir/uzun narsa yubormang. Ularga faqat **1 daqiqalik,
bosish bilan javob beriladigan** variant yuboriladi (pastda 1차 qismida).

## 2. Taqsimlash usuli (mijozlar band bo'lgani uchun)

- **IDCool o'zi vositachi bo'lsin** — mijozga sizdan emas, ular ishonadigan IDCool'dan so'rov kelsin (masalan texnik xizmatga borganda 2 daqiqa ko'rsatib, link tashlab ketishadi).
- Ilovani o'rnatishni/sinab ko'rishni so'ramang — **30-60 soniyalik qisqa video yoki 3-4 ta skrinshot** yuboriladi, shunga reaksiya so'raladi.
- Google Forms (yoki shunga o'xshash) — faqat bosish, yozish shart emas.
- **3-5 ta real javob** yetarli — katta statistik namuna shart emas, bu bitiruv loyihasi uchun.

## 3. 1차 so'rovnoma — hozir, yengil (~1 daqiqa)

### IDCool xodimlari uchun (5 ta savol, 1-5 ball)

1. 여러 시설을 한 곳에서 관리하는 게 이전보다 편해졌다고 생각하십니까?
2. 고객과의 소통(채팅/게시판)이 실제로 도움이 될 것 같습니까?
3. 이상 상황(알람)을 더 빠르게 확인할 수 있을 것 같습니까?
4. 화면 구성이 이해하기 쉬웠습니까?
5. 전체적으로 이 시스템이 실제 업무에 도움이 될 것 같습니까?

+ 1 ta ochiq savol (majburiy emas): 가장 아쉬운 점이 있다면 무엇입니까?

### Sitting mijozi (다온 va h.k.) uchun — juda qisqa (3 ta savol, 1-5 ball, video/skrinshot ko'rgandan keyin)

1. 화면을 보고 무슨 정보인지 쉽게 이해되셨습니까?
2. 문제가 생겼을 때 이렇게 바로 알림을 받으면 도움이 될 것 같습니까?
3. IDCool과 이 앱으로 소통하는 게 편할 것 같습니까?

## 4. 2차 so'rovnoma — V2 tugagach, jiddiy

V2 tayyor bo'lganda, savollarni **IDCool aytgan aniq muammolarga bog'lab** kengaytiring.
Har bir funksiya uchun format bir xil:

> "IDCool avval [X muammosi]ni aytgan edi. Biz buni [Y funksiya] bilan hal qilishga harakat qildik.
> Sizningcha bu yordam berdimi?" (1-5 ball)

Bu formatni to'ldirish uchun, avval IDCool aytgan har bir real muammoni yozib chiqing (masalan
jadval qilib): muammo → qaysi funksiya bilan yechilgan → savol matni. Shunda natija shunchaki
"foydalanuvchilar mamnun" emas, balki **"aytilgan muammo → qurilgan yechim → tasdiqlangan"**
degan yopiq zanjir bo'ladi.

### IDCool aytgan real muammolar → yechim → savol

**Muammo 1 — doimiy kuzatuv zarurati**
IDCool'da doim kimdir monitor oldida o'tirib kuzatib turishi kerak edi, chunki muammo chiqsa ham
telefonga hech qanday xabar kelmasdi.
→ Yechim: ilova muammoni avtomatik aniqlab, push-xabar (FCM) yuboradi (알람 funksiyasi).
→ Savol: *"이제 화면을 계속 지켜보지 않아도, 문제가 생기면 알림으로 바로 알 수 있을 것 같습니까?"* (1-5)

**Muammo 2 — mijoz bilan aloqa (KakaoTalk/qo'ng'iroq) qiyin va takrorlanuvchi**
Mijozlar bilan KakaoTalk yoki telefon orqali gaplashilardi — uskuna/tugmani tushuntirish qiyin edi,
chunki mijozning texnik tushunchasi yo'q, va ko'p savollar bir-biriga o'xshab takrorlanardi.
→ Yechim: sitting/alarmga bog'langan chat va board — tushuntirish yozib qoladi, grafik orqali
vaziyat ko'rgazmali ko'rsatiladi (og'zaki tushuntirishdan ko'ra tushunarli).
→ Savol: *"전화로 설명 듣는 것보다, 화면을 보면서 대화하는 게 이해하기 쉬울 것 같습니까?"* (1-5)
→ Savol: *"같은 설명을 여러 번 반복하지 않아도 될 것 같습니까?"* (게시판 관련, 1-5)

**Muammo 3 — mijozning texnik bilimi yo'q, uskuna/terminal tushunarsiz**
Mijozlar texnik bilimga ega emas, shuning uchun ko'p terminal/uskuna ko'rsatkichlari ular uchun
umuman tushunarsiz edi.
→ Yechim: murakkab uskuna ko'rsatkichlari o'rniga, mijoz ham tushuna oladigan oddiy holat
(정상/이상) va sodda tugmalar bilan almashtirildi — mijoz oddiy nosozlikni o'zi ko'rib, hatto
o'zi tuzata oladi (customer self-service).
→ Savol: *"화면의 정보나 버튼이 이해하기 쉬웠습니까?"* (1-5)
→ Savol: *"간단한 문제라면, 전화하지 않고 스스로 확인하거나 해결할 수 있을 것 같습니까?"* (1-5)

2차 uchun qo'shimcha:
- Real ilovani (yoki demo hisobni) 5-10 daqiqa sinab ko'rishlarini so'rash mumkin (V2 da tayyorroq bo'lgani uchun)
- Har bir asosiy ekran/funksiya uchun alohida savol (chart, alarm, chat, monitoring)

## 5. Legacy Compare — eski usul bilan solishtirish (5 ta savol)

Bu — yuqoridagi 3 ta muammoni **to'g'ridan-to'g'ri "eski vs yangi"** shaklida so'raydi. Har bir
savol 1 (eski usul ancha yaxshi edi) dan 5 (yangi usul ancha yaxshi) gacha baholanadi, 3 — "farqi yo'q".

1. *"사람이 계속 화면을 지켜보던 예전 방식과 비교했을 때, 자동 알림 방식이 얼마나 낫다고 생각하십니까?"*
   (Muammo 1 — doimiy kuzatuv bilan solishtirish)

2. *"카카오톡·전화로 설명하던 예전 방식과 비교했을 때, 앱 안에서 대화하고 기록이 남는 방식이 얼마나 낫습니까?"*
   (Muammo 2 — aloqa usuli bilan solishtirish)

3. *"장비 화면을 직접 봐야 했던 예전 방식과 비교했을 때, 쉬운 문구로 상태를 보는 방식이 얼마나 이해하기 쉽습니까?"*
   (Muammo 3 — tushunarlilik bilan solishtirish)

4. *"예전 방식과 비교했을 때, 문제를 알아차리고 해결하는 데 걸리는 시간이 얼마나 줄어들 것 같습니까?"*
   (Umumiy — tezlik)

5. *"전체적으로, 예전 방식 대신 이 시스템을 계속 사용하고 싶으십니까?"*
   (Umumiy — almashtirishga tayyormisiz)

Birinchi 3 tasi aynan yuqoridagi 3 ta real muammoga bog'langan, oxirgi 2 tasi — umumlashtiruvchi.
Bu savollar javobi poster'da **"eski usul → yangi usul" o'zgarish grafigi** sifatida chizilsa juda
kuchli ko'rinadi (masalan har bir savol uchun bitta ustun, 3 chizig'idan — o'rtadan — qanchalik
uzoqlashganini ko'rsatib).

## 6. Baholashni qanday o'lchash kerak

- Har bir savol — 1-5 ball (Likert scale).
- **Funksiya bo'yicha o'rtacha**: bir funksiyaga tegishli savollarni o'rtachasini oling (masalan "aloqa" bo'yicha 2-3 savol bo'lsa, ularning o'rtachasi = "aloqa funksiyasi bahosi").
- **Umumiy natija**: barcha savollarning o'rtachasi.
- Hisobotda shunday yozing: *"N kishidan M tasi X funksiyani 4/5 va undan yuqori baholadi"* — bu D07 hujjatidagi "기능구현범위" formulasiga o'xshab, **raqam bilan isbotlanadigan** natija beradi.
- Ochiq savol javoblarini (agar bo'lsa) 1-2 ta to'g'ridan-to'g'ri iqtibos sifatida hisobotga qo'shing — bu raqamdan ko'ra ko'proq ishonch uyg'otadi.

## 7. Keyingi qadam

- [ ] IDCool aytgan real muammolar ro'yxatini yozib chiqish (2차 savollar uchun kerak)
- [ ] 1차 so'rovnomani Google Forms qilib tayyorlash
- [ ] IDCool orqali 다온ga (va boshqa mumkin bo'lgan sittinglarga) yuborish
- [ ] Natijalarni yig'ib, D07/D08 hujjatlariga qo'shish
