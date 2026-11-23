# Sistem Pakar Diagnosa Dini Penyakit Blas pada Tanaman Padi

Sistem pakar berbasis aturan untuk memperkirakan diagnosis dini penyakit blas (*Pyricularia oryzae*) pada padi. Basis pengetahuan dan mesin inferensi ditulis dalam SWI-Prolog dengan **Backward Chaining** dan **Certainty Factor (CF)**. Tugas 2 mata kuliah Kecerdasan Artifisial (MMAI1001).

> **Catatan:** semua nilai CF masih **draf** dan harus divalidasi dengan literatur atau pakar. Hasil sistem tidak menggantikan pemeriksaan PPL/POPT.

## Struktur folder

```text
prolog/basis_pengetahuan.pl   fakta gejala, diagnosis, aturan, nilai CF (file yang diedit saat validasi)
prolog/mesin_inferensi.pl     backward chaining, CF, komponen bukti, prioritas diagnosis
prolog/konsol.pl              antarmuka konsol
prolog/server.pl              web server dan API, port 8080
web/                          index.html, style.css, app.js, favicon.svg (hanya tampilan)
tests/test_sistem.pl          unit test plunit
docs/hasil_uji.md             tabel hasil pengujian
docs/penjelasan_teknis.md     bahan Bab III dan IV
docs/contoh_konsol.txt        contoh sesi konsol
docs/screenshot/              tampilan web sebelum dan sesudah perbaikan
```

## Cara menjalankan

Pasang [SWI-Prolog](https://www.swi-prolog.org/), lalu buka terminal di folder project.

### Konsol (Lampiran B)

```console
$ swipl
?- consult('prolog/konsol.pl').
?- mulai.
```

Jawab setiap gejala dengan `Y` atau `T` (huruf besar atau kecil). Input lain akan ditanyakan ulang.

### Web

**Cara biasa (foreground).** Jalankan di terminal, lalu biarkan terminal tetap terbuka:

```console
$ swipl prolog/server.pl
Server berjalan di http://localhost:8080 (ketik halt. untuk berhenti)
?-
```

Buka <http://localhost:8080>. Untuk menghentikan server, lakukan salah satu cara berikut di terminal yang sama:

- Ketik `halt.` lalu tekan Enter.
- Tekan Ctrl+D pada prompt `?-`.
- Tekan Ctrl+C, lalu tekan `e` saat muncul `Action (h for help) ?`.

**Cara background.** Perintah foreground memerlukan terminal aktif dan langsung berhenti jika dijalankan tanpa input. Untuk menjalankannya di background, gunakan:

```console
$ nohup swipl -g 'thread_get_message(stop)' prolog/server.pl > /dev/null 2>&1 < /dev/null &
```

Hentikan server background dengan:

```console
$ lsof -ti tcp:8080 -sTCP:LISTEN | xargs kill
```

Jika muncul `Socket error: Address already in use`, port 8080 sudah dipakai. Hentikan server lama terlebih dahulu. Server foreground yang berjalan di terminal lain mungkin tidak berhenti dengan `kill` biasa. Hentikan dari terminalnya, atau gunakan `kill -9`.

### Test

```console
$ swipl -g run_tests -t halt tests/test_sistem.pl
```

## Basis pengetahuan

### Gejala

| ID | Organ | Gejala |
|---|---|---|
| G1 | Daun | Bercak belah ketupat (lonjong, ujung runcing) pada daun |
| G2 | Daun | Pusat bercak abu-abu atau keputihan |
| G3 | Daun | Tepi bercak cokelat kemerahan |
| G4 | Daun | Bercak menyatu sehingga daun mengering |
| G5 | Daun | Bibit atau anakan layu dan mati |
| G6 | Batang/Buku | Buku batang cokelat kehitaman |
| G7 | Batang/Buku | Batang mudah patah pada bagian buku |
| G8 | Malai | Leher malai cokelat kehitaman (busuk leher) |
| G9 | Malai | Malai patah atau terkulai |
| G10 | Malai | Gabah hampa atau pengisian tidak sempurna |
| G11 | Lingkungan & Budidaya | Lingkungan lembap, berembun, atau sering hujan |
| G12 | Lingkungan & Budidaya | Pemupukan nitrogen (urea) berlebihan |

### Diagnosis

| ID | Diagnosis |
|---|---|
| D1 | Blas leher (neck blast) |
| D2 | Blas daun (leaf blast) |
| D3 | Blas buku (node blast) |
| D4 | Gejala awal blas / risiko tinggi |
| D5 | Kemungkinan rendah blas |

### Saran per derajat

Predikat `saran/3` menyimpan saran untuk setiap pasangan diagnosis dan derajat. Saran yang tampil mengikuti derajat hasil diagnosis.

| Diagnosis | Derajat | Saran tindakan (draf) |
|---|---|---|
| D1 | Berat | Kehilangan hasil berpotensi tinggi. Segera aplikasikan fungisida sistemik sesuai anjuran label dan konsultasikan dengan PPL/POPT. |
| D1 | Sedang | Pengisian gabah mulai terganggu. Periksa leher malai pada rumpun sekitar dan konsultasikan kebutuhan fungisida dengan PPL/POPT. |
| D1 | Awal | Gejala masih awal. Pantau leher malai secara rutin, hindari pupuk N berlebih, jaga drainase, dan hubungi PPL/POPT jika malai mulai patah atau gabah hampa. |
| D2 | Berat | Segera aplikasikan fungisida sesuai anjuran label, kurangi pupuk N, perbaiki jarak tanam, dan konsultasikan dengan PPL/POPT. |
| D2 | Sedang | Kurangi pupuk N, perbaiki jarak tanam, pantau penyebaran bercak, dan konsultasikan kebutuhan fungisida dengan PPL/POPT. |
| D3 | Sedang–Berat | Aplikasikan fungisida sesuai anjuran label, pantau penyebaran ke malai, dan konsultasikan dengan PPL/POPT. |
| D3 | Awal | Gejala masih awal. Pantau buku batang dan penyebaran ke malai, hindari pupuk N berlebih, dan jaga drainase. |
| D4 | Risiko | Lakukan pemantauan rutin, perbaiki drainase, dan gunakan varietas tahan. |
| D5 | Rendah | Gejala tidak cukup kuat dan mungkin disebabkan penyakit lain. Konsultasikan dengan PPL. |

### Aturan

| Aturan | IF | THEN | CF aturan (draf) | Derajat (draf) |
|---|---|---|---:|---|
| R1 | G8 AND G9 AND G10 | D1 | 0.95 | Berat |
| R2 | G8 AND G9 | D1 | 0.90 | Berat |
| R3 | G8 AND G10 | D1 | 0.80 | Sedang |
| R4 | G8 | D1 | 0.55 | Awal |
| R5 | G1 AND G2 AND G3 AND G4 | D2 | 0.95 | Berat |
| R6 | G1 AND G2 AND G3 | D2 | 0.90 | Sedang |
| R7 | G1 AND G5 | D2 | 0.80 | Berat |
| R8 | G1 AND G4 | D2 | 0.75 | Sedang |
| R9 | G6 AND G7 | D3 | 0.90 | Sedang–Berat |
| R10 | G6 | D3 | 0.60 | Awal |
| R11 | G11 AND G12 | D4 | 0.50 | Risiko |
| R12 | G1 | D4 | 0.30 | Risiko |
| R13 | G2 AND G3 | D4 | 0.30 | Risiko |
| R14 | G11 | D4 | 0.40 | Risiko |
| R15 | G12 | D4 | 0.40 | Risiko |
| R16 | G4 | D5 | 0.30 | Rendah |
| R17 | G5 | D5 | 0.30 | Rendah |
| R18 | G7 | D5 | 0.40 | Rendah |
| R19 | G9 | D5 | 0.40 | Rendah |
| R20 | G10 | D5 | 0.35 | Rendah |
| R21 | G9 AND G10 | D5 | 0.50 | Rendah |

## Perhitungan CF

```text
CF hasil = CF aturan × min(CF jawaban pengguna untuk semua premis), dengan Y = 1.0
CFgab    = CF1 + CF2 × (1 − CF1)
```

**CF hanya ada pada level aturan.** Kolom CF gejala pada template bersifat opsional ("Jika Ada"). CF gejala tidak dipakai karena sebelumnya membuat bobot pakar dihitung ganda, di gejala dan di aturan, sehingga aturan yang lebih spesifik kalah.

**Keyakinan berbeda dari derajat.** Persentase menunjukkan tingkat keyakinan sistem, bukan tingkat keparahan. Derajat diagnosis adalah derajat paling berat di antara semua aturan terpicu (Berat > Sedang–Berat > Sedang > Awal > Risiko > Rendah) dan tampil sebagai "Derajat: <label> (berdasarkan aturan Rx)". Jika aturan derajat berbeda dari aturan penentu CF, sistem menampilkan keduanya, misalnya "Keyakinan dari R6, derajat dari R7".

**Urutan diagnosis.** Diagnosis diurutkan dari CF tertinggi. Jika CF seri, derajat lebih berat tampil lebih dulu, lalu ID.

**Penggabungan hanya untuk bukti independen.** Rumus kombinasi CF mengasumsikan bukti independen, sedangkan aturan yang berbagi gejala bukan bukti independen. Aturan terpicu dengan kesimpulan sama dikelompokkan menjadi komponen berdasarkan irisan premis secara transitif. Setiap komponen hanya menyumbang CF hasil tertinggi. Nilai antar-komponen, yang premisnya saling lepas, digabung dengan rumus di atas.

**Prioritas tampil.**

1. Jika ada D1, D2, atau D3, maka D4 dan D5 tidak ditampilkan. G11 dan G12 yang dijawab Y tampil sebagai faktor risiko pendukung.
2. Jika tidak ada D1–D3 tetapi ada D4, maka D5 tidak ditampilkan.
3. D5 hanya muncul jika D1–D4 tidak ada.
4. Jika tidak ada aturan terpicu, sistem menampilkan "Sistem tidak dapat menyimpulkan; konsultasikan dengan PPL."

## Pengujian

| Skenario | Input | Hasil sistem | Derajat | Aturan dihitung |
|---|---|---|---|---|
| A | G8, G9, G10 | D1 95.00% | Berat | R1 |
| B | G1, G2, G3, G4 | D2 95.00% | Berat | R5 |
| C | G6, G7 | D3 90.00% | Sedang–Berat | R9 |
| D | G11, G12 | D4 50.00% | Risiko | R11 |
| E | tanpa gejala | tidak dapat menyimpulkan | – | – |
| F | G1, G2, G3, G4, G8, G9, G10 | D1 95.00%, D2 95.00% (CF dan derajat seri, urut ID) | Berat; Berat | R1; R5 |
| G | G9 | D5 40.00% | Rendah | R19 |

Rincian ada di [docs/hasil_uji.md](docs/hasil_uji.md). Penjelasan mekanisme ada di [docs/penjelasan_teknis.md](docs/penjelasan_teknis.md).

## Batasan

- Nilai CF masih draf dan daftar pustaka belum diisi.
- Jawaban hanya Y atau T, sehingga CF hasil aturan yang terpicu sama dengan CF aturan.
- Label derajat dan saran masih draf dan perlu divalidasi dengan literatur atau pakar.

## Masalah yang diketahui

**Crash saat refresh pada SWI-Prolog 11.0.0 (sudah ditangani).** Project ini diuji dengan SWI-Prolog 11.0.0 for arm64-darwin. Pada versi tersebut, request file statis dengan header `If-Modified-Since`, yang dikirim browser saat refresh, menghentikan server dengan pesan:

```text
Assertion failed: (0), function raiseStackOverflow, file pl-alloc.c, line 759.
```

Masalah yang sama muncul pada server minimal di luar project ini. Sebagai workaround, `sajikan_web/1` di `prolog/server.pl` membuang header tersebut sebelum memanggil `http_reply_from_files/3`. Akibatnya, file statis selalu dikirim penuh dengan status 200 dan tidak memakai balasan 304. Test `refresh_if_modified_since_server_tetap_hidup` menjaga perilaku ini.

**Balasan 404 pada SWI-Prolog 11.0.0 (sudah ditangani).** Opsi `not_found(404)` pada `http_reply_from_files/3` dapat menyebabkan segmentation fault. Karena itu, `sajikan_web/1` membalas 404 secara langsung dalam format JSON. Test `file_tidak_ada_404_server_tetap_hidup` menjaga perilaku ini.
