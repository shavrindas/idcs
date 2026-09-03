# Bu loyiha nima?

Bu — **muzlatgich omborlar** (sovutgich, cold storage) uchun kuzatuv tizimi. Ya'ni katta
sovutgich omborlarda harorat, gaz bosimi, kompressor holati kabi narsalarni masofadan
kuzatib turadigan va boshqaradigan dastur.

Oddiy tilda aytganda: omborda sensorlar (o'lchagichlar) turadi, ular haroratni o'lchab
turadi, bu ma'lumot serverga yuboriladi, server uni saqlaydi, keyin siz uni telefon
ilovasi yoki veb-sayt orqali ko'rasiz va kerak bo'lsa boshqarasiz (masalan sovutishni
kuchaytirish).

---

## Loyiha qismlari (5 ta bo'lim bor)

Loyiha bitta katta papka ichida, lekin aslida 5 ta **mustaqil** kichik loyihadan iborat.
Har birining o'z vazifasi bor:

### 1. `idc_server` — Server (miya qismi)
Bu — barcha ma'lumotlarni qabul qiluvchi, saqlaydigan va boshqa qismlarga beradigan
markaziy dastur. Python tilida (FastAPI degan vosita bilan) yozilgan.

O'xshatish: bu — restoranning **oshxonasi**. Hamma buyurtma shu yerga keladi, shu yerda
tayyorlanadi.

### 2. `idc_web` — Veb-sayt (kompyuter uchun boshqaruv paneli)
Brauzerda ochiladigan sahifa. Admin va xodimlar shu orqali barcha omborlarni,
xonalarni, grafiklarni ko'radi va boshqaradi. React degan texnologiyada yozilgan.

O'xshatish: bu — restoranning **menejer kabineti**, hammasini yuqoridan kuzatib turadi.

### 3. `idc_app` — Telefon ilovasi (Flutter)
Xodimlar telefonda ishlatadigan ilova. Monitoring, chat, e'lonlar (board), signal
(alarm) — hammasi shu yerda. **Siz aynan shu qism ustida ishlayapsiz** (`uiux` branch —
dizaynni chiroyli va professional qilish).

O'xshatish: bu — restoranning **ofitsiant qo'lidagi planshet**, u orqali tez-tez
tekshirib turadi.

### 4. `fac_server` va `DataIntercept` — Ombordagi kichik dastur
Bular haqiqiy ombor ichida ishlaydigan dasturlar. Ular jismoniy sensorlarga (simlar,
portlar orqali) ulanadi, ma'lumot o'qiydi va uni serverga (`idc_server`) yuboradi.
Ikkalasi bir xil ishni qiladi, faqat sensorlarga ulanish usuli boshqacha (biri —
to'g'ridan-to'g'ri kabel, ikkinchisi — internet orqali).

O'xshatish: bu — oshxonaga mahsulot yetkazib beruvchi **yetkazib beruvchi**.

### 5. `doker_list` — O'rnatish sozlamalari
Bu kod emas, balki "hammasini serverga qanday joylashtirish kerak" degan
sozlamalar to'plami (Docker degan vositadan foydalanadi).

---

## Hammasi qanday ishlaydi (ma'lumot yo'li)

```
Ombordagi sensor (harorat o'lchagich)
      ↓
fac_server / DataIntercept  (ombordagi kichik dastur, ma'lumotni yig'adi)
      ↓
idc_server  (markaziy server, ma'lumotni saqlaydi)
      ↓
   ↙        ↘
idc_web    idc_app
(veb-sayt)  (telefon)
```

Ya'ni: sensor → ombordagi dastur → markaziy server → siz buni veb-saytda yoki
telefon ilovasida ko'rasiz.

---

## Siz nima qilyapsiz?

Siz `uiux` degan **branch** (bu — loyihaning alohida "nusxasi", asosiy kodga
tegmasdan ishlash uchun) ustida ishlayapsiz. Vazifangiz: telefon ilovasi va
veb-saytning **tashqi ko'rinishini** (dizayn, ranglar, tugmalar, joylashuv)
zamonaviy va professional qilish. Backend (server) mantig'iga deyarli tegilmayapti
— faqat "ko'rinish" o'zgaryapti.

`main` branch — bu asosiy, "ishlab turgan" versiya. Unga to'g'ridan-to'g'ri
tegilmaydi, chunki xato ketsa hamma narsa buziladi. Shuning uchun alohida `uiux`
branchda ishlanadi, keyin tekshirilib, faqat kerak bo'lganda asosiy versiyaga
qo'shiladi.

---

## Ba'zi atamalar (tez-tez uchraydi)

- **Backend / server** — ma'lumotni saqlaydigan va ishlov beradigan qism (ko'rinmaydi,
  "orqa tomon").
- **Frontend** — foydalanuvchi ko'radigan qism: veb-sayt yoki ilova ekranlari.
- **API** — server bilan ilova/sayt o'rtasidagi "so'rov-javob" yo'li. Masalan ilova
  "menga haroratlarni ber" deb so'raydi, server javob qaytaradi.
- **Database (baza)** — barcha ma'lumotlar saqlanadigan katta jadval/ombor.
- **WebSocket** — doimiy ochiq aloqa liniyasi, real vaqtda (jonli) ma'lumot kelib
  turishi uchun ishlatiladi (masalan chat yoki jonli harorat ko'rsatkichi).
- **Git branch** — loyihaning alohida "nusxasi", boshqalarga xalaqit bermasdan
  o'zgartirish kiritish uchun.
- **Commit** — qilingan o'zgarishni "saqlash nuqtasi" sifatida yozib qo'yish.
- **Push** — o'z kompyuteringizdagi o'zgarishlarni GitHub'ga (internetga) yuklash.

---

## Batafsil (texnik) ma'lumot kerak bo'lsa

Loyihaning to'liq texnik tavsifi — qaysi papkada nima bor, qanday ishga tushiriladi
— `CLAUDE.md` faylida yozilgan (shu papkaning ichida). Bu fayl ko'proq
dasturchilar/AI yordamchi uchun batafsilroq yozilgan.
