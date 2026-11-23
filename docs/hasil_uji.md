# Hasil Pengujian

Metode: black-box testing per skenario dan pengujian menyeluruh atas seluruh kombinasi gejala dengan plunit.

Lingkungan: SWI-Prolog 11.0.0. Perintah: `swipl -g run_tests -t halt tests/test_sistem.pl`.

Hasil: **35 dari 35 test lulus.**

Rumus yang diuji:

- CF hasil aturan = CF aturan × min(CF jawaban pengguna), dengan Y = 1.0.
- Aturan yang premisnya beririsan (transitif) membentuk satu komponen, dan hanya CF tertinggi yang dipakai.
- Antar-komponen digabung dengan CF1 + CF2 × (1 − CF1).
- Derajat diagnosis = derajat paling berat di antara semua aturan terpicu.
- Diagnosis diurutkan menurut CF, lalu derajat lebih berat, lalu ID.

## Skenario A–G

Kolom "diagnosis yang diharapkan" berasal dari rancangan tugas dan belum divalidasi.

| Skenario | Input (Y) | Diagnosis yang diharapkan [PERLU VALIDASI LITERATUR/PAKAR] | Hasil sistem | Derajat | CF (keyakinan) | Aturan dihitung | Status |
|---|---|---|---|---|---:|---|---|
| A. Blas leher | G8, G9, G10 | D1 | D1 | Berat (R1) | 95.00% | R1 | Lulus |
| B. Blas daun | G1, G2, G3, G4 | D2, tanpa D4 | D2 | Berat (R5) | 95.00% | R5 | Lulus |
| C. Blas buku | G6, G7 | D3 | D3 | Sedang–Berat (R9) | 90.00% | R9 | Lulus |
| D. Lingkungan | G11, G12 | D4 | D4 | Risiko (R11) | 50.00% | R11 | Lulus |
| E. Tanpa gejala | tidak ada | Tidak ada diagnosis | Tidak dapat menyimpulkan | – | – | – | Lulus |
| F. Campuran | G1, G2, G3, G4, G8, G9, G10 | D1 dan D2, urut CF | D1, lalu D2 (CF dan derajat seri, urut ID) | Berat (R1); Berat (R5) | 95.00%, 95.00% | R1; R5 | Lulus |
| G. Gejala minim | G9 | D5 | D5 | Rendah (R19) | 40.00% | R19 | Lulus |

## Pengujian tambahan

| Pengujian | Hasil |
|---|---|
| Jumlah 12 gejala dan 21 aturan, premis/2 sama dengan badan menyebabkan/2 | Lulus |
| Setiap aturan memiliki derajat, dan derajat diagnosis diambil dari aturan terpicu paling berat | Lulus |
| G1, G2, G3, G5: CF 90% dari R6, Derajat Berat dari R7, sumber keduanya ditampilkan | Lulus |
| Nama D1 dan D2 tidak lagi memuat tingkat | Lulus |
| Pemilihan aturan saat CF seri: derajat lebih berat, lalu ID numerik | Lulus |
| Urutan diagnosis saat CF seri: G1, G5, G8, G10 menampilkan D2 (Berat) sebelum D1 (Sedang) | Lulus |
| CF D1 untuk G8, G9, G10 tidak lebih rendah daripada G8, G9 | Lulus |
| G1, G4, G5 menghasilkan D2 = 80% dari R7 | Lulus |
| Komponen transitif: G11, G12 menghasilkan D4 = 50% dari R11 | Lulus |
| Komponen saling lepas: G1, G11 menghasilkan D4 = 58% dari R12 dan R14 | Lulus |
| 4.096 kombinasi: menambah satu gejala tidak menurunkan CF diagnosis yang tetap tampil (0 pelanggaran) | Lulus |
| 4.096 kombinasi: menambah satu gejala tidak menurunkan derajat diagnosis yang tetap tampil (0 pelanggaran) | Lulus |
| 4.096 kombinasi: D4 tidak tampil bersama D1–D3 | Lulus |
| 4.096 kombinasi: D5 tidak tampil bersama D1–D4 | Lulus |
| 4.096 kombinasi: R1–R21 masing-masing pernah dihitung (tidak ada aturan mati) | Lulus |
| Hasil `hasil_diagnosa/1` skenario A–G sama dengan `POST /api/diagnosa` | Lulus |
| Derajat dan catatan keyakinan tersedia di API | Lulus |
| Input API tidak valid ditolak dengan status 400 | Lulus |

## Catatan analisis (bahan Bab 4.3)

- **CF hasil aturan sama dengan CF aturan.** Jawaban hanya Y atau T, sehingga min(CF jawaban) selalu 1.0 untuk aturan yang terpicu.
- **Sumber keyakinan dan derajat dapat berbeda.** G1, G2, G3, G5 memperoleh CF 90% dari R6 dan Derajat Berat dari R7. Kondisi ini terjadi pada 128 dari 4.096 kombinasi, seluruhnya pada D2.
- **Skenario F seri pada CF dan derajat.** D1 dan D2 sama-sama 95% dan Berat, sehingga D1 tampil lebih dulu karena ID.
- **Akurasi klinis belum diukur.** Test membuktikan sistem konsisten dengan aturan, bukan bahwa diagnosis benar di lapangan. PDF meminta analisis akurasi, sehingga kelompok perlu membandingkan hasil dengan kasus dari literatur atau pakar.
