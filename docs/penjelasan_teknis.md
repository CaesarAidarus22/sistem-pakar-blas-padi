# Penjelasan Teknis

Dokumen ini dapat diadaptasi untuk Bab III dan Bab IV laporan.

## 1. Arsitektur

```text
┌──────────────────────────────┐
│ basis_pengetahuan.pl         │
│ gejala/2, diagnosis/2        │
│ menyebabkan/2, premis/2      │
│ cf_aturan/2, derajat_aturan/2│
│ saran/3                      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ mesin_inferensi.pl           │
│ ya/1, tanya_gejala/1         │
│ diagnosa/3, cf_hasil/2       │
│ komponen bukti, prioritas    │
│ hasil_diagnosa/1             │
└───────┬──────────────┬───────┘
        │              │
        ▼              ▼
┌──────────────┐ ┌──────────────┐
│ konsol.pl    │ │ server.pl    │
│ mulai/0      │ │ REST API     │
│ diagnosa/0   │ └──────┬───────┘
└──────────────┘        │
                        ▼
                 ┌──────────────┐
                 │ web/         │
                 │ hanya UI     │
                 └──────────────┘
```

Konsol dan web memanggil `hasil_diagnosa/1` yang sama, sehingga angkanya identik. JavaScript hanya menampilkan data dari Prolog.

## 2. Backward chaining dan backtracking

Setiap aturan ditulis sebagai klausa Prolog:

```prolog
menyebabkan(d1, r2) :- ya(g8), ya(g9).
```

Sistem memulai dari hipotesis, yaitu `diagnosis(D, _)`, lalu membuktikan `menyebabkan(D, R)`. Untuk membuktikannya, Prolog menurunkan subgoal `ya(g8)` dan `ya(g9)`. Inilah backward chaining: penalaran bergerak dari kesimpulan ke premis.

```prolog
diagnosa(Diagnosis, IdAturan, CFHasil) :-
    diagnosis(Diagnosis, _),
    menyebabkan(Diagnosis, IdAturan),
    cf_hasil(IdAturan, CFHasil).
```

Jika satu subgoal gagal, Prolog melakukan **backtracking** ke klausa `menyebabkan/2` berikutnya. `findall/3` memaksa proses ini berlanjut sampai semua aturan alternatif untuk semua diagnosis selesai dicoba.

## 3. Predikat kunci

### `tanya_gejala/1`

Predikat ini adalah mekanisme input dinamis. Jawaban disimpan pada `:- dynamic jawaban/2` dengan `assertz/1` dan dibersihkan dengan `retractall/1`.

1. Jika gejala sudah dijawab, predikat langsung berhasil tanpa bertanya lagi.
2. Jika belum, sistem menampilkan pertanyaan dengan pilihan `(Y/T)`.
3. Input huruf besar dan kecil diterima. Input lain menyebabkan pertanyaan diulang.

`mulai/0` menanyakan semua gejala G1–G12 secara berurutan sesuai PDF. Setelah itu, `ya/1` membaca jawaban tersimpan saat aturan dibuktikan.

### `diagnosa`

`diagnosa/3` adalah mekanisme penalaran yang menghasilkan satu solusi per aturan terpicu melalui backtracking. `diagnosa/0` di konsol menjalankan `hasil_diagnosa/1` lalu menampilkan hasilnya.

### `hasil_diagnosa/1`

Predikat inti ini mengumpulkan aturan terpicu, membentuk komponen bukti, menggabungkan CF, menerapkan prioritas, lalu mengurutkan hasil.

## 4. Perhitungan Certainty Factor

```text
Jawaban Y = 1.0; jawaban T = aturan gagal
CF hasil = CF aturan × min(CF jawaban pengguna untuk semua premis)
CFgab    = CF1 + CF2 × (1 − CF1)
```

CF hanya ada pada level aturan. Template dosen menulis CF gejala sebagai "(Jika Ada)", sehingga bersifat opsional. Versi sebelumnya memasukkan CF gejala ke `min()` premis. Akibatnya, bobot pakar dihitung ganda, di gejala dan di aturan, dan aturan yang lebih spesifik dapat kalah. Contohnya, R1 hanya bernilai 38% karena dibatasi CF G10 = 0.4, sehingga R1, R3, dan R21 tidak pernah dihitung.

Contoh skenario A (G8, G9, G10):

| Aturan | min(CF jawaban) | CF aturan | CF hasil | Status |
|---|---:|---:|---:|---|
| R1: G8, G9, G10 | 1.0 | 0.95 | 0.95 | **Dihitung** |
| R2: G8, G9 | 1.0 | 0.90 | 0.90 | Diabaikan |
| R3: G8, G10 | 1.0 | 0.80 | 0.80 | Diabaikan |
| R4: G8 | 1.0 | 0.55 | 0.55 | Diabaikan |

CF akhir D1 = 95.00%.

## 5. Penggabungan hanya untuk bukti independen

Rumus kombinasi CF mengasumsikan bukti independen. Aturan yang berbagi gejala bukan bukti independen, sehingga menggabungkannya menghitung gejala yang sama lebih dari sekali.

Langkah untuk aturan terpicu dengan kesimpulan sama:

1. Kelompokkan aturan menjadi komponen. Dua aturan berada pada satu komponen jika premisnya beririsan, secara transitif.
2. Di dalam satu komponen, ambil CF hasil tertinggi. Subset adalah kasus khusus irisan, sehingga langkah ini menggantikan subsumption.
3. Jika CF seri, pilih derajat lebih berat, lalu ID aturan.
4. Gabungkan nilai antar-komponen dengan `CF1 + CF2 × (1 − CF1)`.

Contoh:

| Gejala | Aturan terpicu | Komponen | Hasil |
|---|---|---|---:|
| G1, G4, G5 → D2 | R7 (0.80), R8 (0.75) | {R7, R8}, berbagi G1 | 80% |
| G11, G12 → D4 | R11 (0.50), R14 (0.40), R15 (0.40) | {R11, R14, R15}, transitif melalui R11 | 50% |
| G1, G11 → D4 | R12 (0.30), R14 (0.40) | {R12}, {R14} | 0.40 + 0.30 × 0.60 = 58% |

Pengujian brute force atas 4.096 kombinasi menunjukkan 0 pelanggaran monotonisitas CF, tidak ada aturan mati, dan prioritas D4/D5 tetap berlaku.

## 6. Prioritas diagnosis

| Kondisi | Diagnosis yang tampil |
|---|---|
| Ada D1, D2, atau D3 | D1–D3 yang terpicu. G11/G12 = Y tampil sebagai faktor risiko pendukung |
| Tidak ada D1–D3, ada D4 | D4 |
| Hanya D5 | D5 |
| Tidak ada aturan terpicu | "Sistem tidak dapat menyimpulkan; konsultasikan dengan PPL." |

Tingkat prioritas disimpan pada `tingkat_diagnosis/2` di basis pengetahuan.

## 7. Keyakinan dan derajat

CF dan derajat menjawab dua pertanyaan berbeda, sehingga sumbernya boleh berbeda.

- **CF = keyakinan:** seberapa yakin sistem bahwa diagnosis itu benar berdasarkan gejala. Nilainya memakai CF tertinggi per komponen, lalu digabung antar-komponen.
- **Derajat = keparahan:** seberapa berat kondisi yang ditunjukkan gejala. Nilainya adalah derajat paling berat di antara semua aturan terpicu untuk diagnosis itu.

Urutan derajat: Berat > Sedang–Berat > Sedang > Awal > Risiko > Rendah. Jika beberapa aturan memiliki derajat sama, sistem memilih CF tertinggi, lalu ID aturan.

Satu gejala parah tidak boleh hilang hanya karena aturan lain lebih meyakinkan. Karena himpunan aturan terpicu hanya bertambah saat gejala ditambah, derajat tidak pernah turun. Pengujian brute force atas 4.096 kombinasi menunjukkan 0 pelanggaran.

| Aturan | Derajat (draf) |
|---|---|
| R1, R2 | Berat |
| R3 | Sedang |
| R4 | Awal |
| R5, R7 | Berat |
| R6, R8 | Sedang |
| R9 | Sedang–Berat |
| R10 | Awal |
| R11–R15 | Risiko |
| R16–R21 | Rendah |

Contoh G1, G2, G3, G5 pada D2:

| Aspek | Aturan | Nilai |
|---|---|---|
| Keyakinan | R6 (CF tertinggi dalam komponen) | 90% |
| Derajat | R7 (derajat paling berat) | Berat |

Output menampilkan "Derajat: Berat (berdasarkan aturan R7)" dan "Keyakinan dari R6, derajat dari R7". Konsol dan web juga menampilkan kalimat "Persentase menunjukkan tingkat keyakinan sistem, bukan tingkat keparahan."

### Saran mengikuti derajat

`diagnosis/2` hanya menyimpan nama penyakit. Saran disimpan pada `saran(Diagnosis, Derajat, Teks)`, dan `saran_hasil/2` memilih teks berdasarkan derajat hasil diagnosis.

Contoh: G8 saja menghasilkan D1 berderajat Awal, sehingga saran berfokus pada pemantauan dan pencegahan. G8, G9, G10 menghasilkan D1 berderajat Berat, sehingga saran berisi tindakan pengendalian segera. Pengujian brute force memastikan setiap diagnosis yang tampil pada 4.096 kombinasi memiliki saran untuk derajatnya.

## 8. Urutan diagnosis

Diagnosis diurutkan dari CF tertinggi. Jika CF seri, derajat lebih berat tampil lebih dulu, lalu ID diagnosis. Contoh: G1, G5, G8, G10 menghasilkan D2 dan D1 sama-sama 80%. D2 tampil lebih dulu karena berderajat Berat, sedangkan D1 berderajat Sedang.

## 9. Batasan sistem

- Nilai CF masih draf dan belum tervalidasi literatur atau pakar.
- Komponen hanya memakai CF tertinggi, sehingga gejala tambahan dalam komponen yang sama belum tentu menaikkan CF. Contoh: G1, G4, G5 tetap 80%.
- Jawaban hanya Y atau T, sehingga CF hasil aturan yang terpicu sama dengan CF aturan.
- Label derajat dan teks saran masih draf dan perlu divalidasi dengan literatur atau pakar.
- Pada SWI-Prolog 11.0.0, request `If-Modified-Since` ke file statis menghentikan server. `sajikan_web/1` membuang header tersebut, sehingga file statis tidak memakai balasan 304. Predikat ini juga membalas 404 secara langsung, karena opsi `not_found(404)` dapat menyebabkan segmentation fault.
- Urutan diagnosis mengutamakan CF. Derajat hanya menjadi penentu saat CF seri.
- Sistem hanya mencakup blas padi dan tidak membedakan penyakit lain dengan gejala serupa.
- Pengujian membuktikan konsistensi logika, bukan akurasi diagnosis di lapangan.

## 10. Tabel validasi sumber

Kolom Sumber diisi kelompok setelah validasi. Contoh isian: `Semangun, 2008, hlm. ..`.

### Gejala

| ID | Gejala | Sumber |
|---|---|---|
| G1 | Bercak belah ketupat (lonjong, ujung runcing) pada daun | |
| G2 | Pusat bercak abu-abu atau keputihan | |
| G3 | Tepi bercak cokelat kemerahan | |
| G4 | Bercak menyatu sehingga daun mengering | |
| G5 | Bibit atau anakan layu dan mati | |
| G6 | Buku batang cokelat kehitaman | |
| G7 | Batang mudah patah pada bagian buku | |
| G8 | Leher malai cokelat kehitaman (busuk leher) | |
| G9 | Malai patah atau terkulai | |
| G10 | Gabah hampa atau pengisian tidak sempurna | |
| G11 | Lingkungan lembap, berembun, atau sering hujan | |
| G12 | Pemupukan nitrogen (urea) berlebihan | |

### Aturan

| ID | Premis | Kesimpulan | CF aturan | Derajat | Sumber |
|---|---|---|---:|---|---|
| R1 | G8, G9, G10 | D1 | 0.95 | Berat | |
| R2 | G8, G9 | D1 | 0.90 | Berat | |
| R3 | G8, G10 | D1 | 0.80 | Sedang | |
| R4 | G8 | D1 | 0.55 | Awal | |
| R5 | G1, G2, G3, G4 | D2 | 0.95 | Berat | |
| R6 | G1, G2, G3 | D2 | 0.90 | Sedang | |
| R7 | G1, G5 | D2 | 0.80 | Berat | |
| R8 | G1, G4 | D2 | 0.75 | Sedang | |
| R9 | G6, G7 | D3 | 0.90 | Sedang–Berat | |
| R10 | G6 | D3 | 0.60 | Awal | |
| R11 | G11, G12 | D4 | 0.50 | Risiko | |
| R12 | G1 | D4 | 0.30 | Risiko | |
| R13 | G2, G3 | D4 | 0.30 | Risiko | |
| R14 | G11 | D4 | 0.40 | Risiko | |
| R15 | G12 | D4 | 0.40 | Risiko | |
| R16 | G4 | D5 | 0.30 | Rendah | |
| R17 | G5 | D5 | 0.30 | Rendah | |
| R18 | G7 | D5 | 0.40 | Rendah | |
| R19 | G9 | D5 | 0.40 | Rendah | |
| R20 | G10 | D5 | 0.35 | Rendah | |
| R21 | G9, G10 | D5 | 0.50 | Rendah | |

## 11. Daftar pustaka

*Pyricularia grisea* adalah nama yang dipakai literatur lama untuk patogen blas padi; nama yang kini digunakan adalah *Pyricularia oryzae* (teleomorf *Magnaporthe oryzae*).

Almahdi, B., Riansyah, A., & Kurniadi, D. (2024). Pengembangan sistem pakar diagnosa penyakit tanaman padi varietas Inpari 32 di daerah Demak dengan metode certainty factor. *Prosiding Konferensi Ilmiah Mahasiswa Unissula (KIMU)*. Universitas Islam Sultan Agung.

Bratko, I. (2012). *Prolog programming for artificial intelligence* (4th ed.). Pearson Education.

Giarratano, J. C., & Riley, G. D. (2005). *Expert systems: Principles and programming* (4th ed.). Thomson Course Technology.

Semangun, H. (2008). *Penyakit-penyakit tanaman pangan di Indonesia* (Ed. 2). Gadjah Mada University Press.

Shortliffe, E. H., & Buchanan, B. G. (1975). A model of inexact reasoning in medicine. *Mathematical Biosciences*, *23*(3–4), 351–379.

Sudir, Nasution, A., Santoso, & Nuryanto, B. (2014). Penyakit blas *Pyricularia grisea* pada tanaman padi dan strategi pengendaliannya. *Iptek Tanaman Pangan*, *9*(2).

Yulianto. (2017). Pengendalian penyakit blas secara terpadu pada tanaman padi. *Iptek Tanaman Pangan*, *12*(1).
