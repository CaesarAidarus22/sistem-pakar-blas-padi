# Hasil Pengujian

Metode: black-box testing per skenario dan pengujian menyeluruh atas seluruh kombinasi gejala dengan plunit.

Lingkungan: SWI-Prolog 11.0.0. Perintah: `swipl -g run_tests -t halt tests/test_sistem.pl`.

Hasil: **22 dari 22 test lulus.**

## Skenario A–G

Kolom "diagnosis yang diharapkan" berasal dari rancangan tugas dan belum divalidasi.

| Skenario | Input (Y) | Diagnosis yang diharapkan [PERLU VALIDASI LITERATUR/PAKAR] | Hasil sistem | CF | Aturan dihitung | Status |
|---|---|---|---|---:|---|---|
| A. Blas leher | G8, G9, G10 | D1 | D1 | 54.00% | R2 | Lulus |
| B. Blas daun | G1, G2, G3, G4 | D2, tanpa D4 | D2 | 57.00% | R5 | Lulus |
| C. Blas buku | G6, G7 | D3 | D3 | 54.00% | R9 | Lulus |
| D. Lingkungan | G11, G12 | D4 | D4 | 15.00% | R11 | Lulus |
| E. Tanpa gejala | tidak ada | Tidak ada diagnosis | Tidak dapat menyimpulkan | – | – | Lulus |
| F. Campuran | G1, G2, G3, G4, G8, G9, G10 | D1 dan D2, urut CF | D2, lalu D1 | 57.00%, 54.00% | R5; R2 | Lulus |
| G. Gejala minim | G9 | D5 | D5 | 24.00% | R19 | Lulus |

## Pengujian tambahan

| Pengujian | Hasil |
|---|---|
| Jumlah 12 gejala dan 21 aturan, premis/2 sama dengan badan menyebabkan/2 | Lulus |
| Subsumption: CF D1 untuk G8, G9, G10 tidak lebih rendah daripada G8, G9 | Lulus |
| Seri CF memilih aturan lebih spesifik | Lulus |
| Aturan beririsan sebagian tetap digabung (G1, G4, G5 = 67%) | Lulus |
| 4.096 kombinasi: menambah satu gejala tidak menurunkan CF diagnosis yang tetap tampil | Lulus |
| 4.096 kombinasi: D4 tidak tampil bersama D1–D3 | Lulus |
| 4.096 kombinasi: D5 tidak tampil bersama D1–D4 | Lulus |
| Hasil `hasil_diagnosa/1` skenario A–G sama dengan `POST /api/diagnosa` | Lulus |
| Input API tidak valid ditolak dengan status 400 | Lulus |

## Catatan analisis (bahan Bab 4.3)

- **G10 tidak memengaruhi CF D1.** Pada skenario A, R1 menghasilkan 38% karena dibatasi CF G10 = 0.4, sedangkan R2 menghasilkan 54%. R2 yang dihitung.
- **R1, R3, dan R21 tidak pernah dihitung** pada seluruh 4.096 kombinasi. Aturan ini tetap terpicu dan tampil sebagai "diabaikan".
- **Skenario F menempatkan D2 di atas D1.** Urutan mengikuti CF, walaupun D1 memiliki dampak kehilangan hasil lebih berat.
- **Akurasi klinis belum diukur.** Test membuktikan sistem konsisten dengan aturan, bukan bahwa diagnosis benar di lapangan. PDF meminta analisis akurasi, sehingga kelompok perlu membandingkan hasil dengan kasus dari literatur atau pakar.
