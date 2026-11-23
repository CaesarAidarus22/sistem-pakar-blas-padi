# Hasil Pengujian

Metode: black-box testing per skenario dan pengujian menyeluruh atas seluruh kombinasi gejala dengan plunit.

Lingkungan: SWI-Prolog 11.0.0. Perintah: `swipl -g run_tests -t halt tests/test_sistem.pl`.

Hasil: **25 dari 25 test lulus.**

Rumus yang diuji: CF hasil aturan = CF aturan × min(CF jawaban pengguna), dengan Y = 1.0. CF hanya ada pada level aturan.

## Skenario A–G

Kolom "diagnosis yang diharapkan" berasal dari rancangan tugas dan belum divalidasi.

| Skenario | Input (Y) | Diagnosis yang diharapkan [PERLU VALIDASI LITERATUR/PAKAR] | Hasil sistem | Keparahan | CF (keyakinan) | Aturan dihitung | Status |
|---|---|---|---|---|---:|---|---|
| A. Blas leher | G8, G9, G10 | D1 | D1 | Berat | 95.00% | R1 | Lulus |
| B. Blas daun | G1, G2, G3, G4 | D2, tanpa D4 | D2 | Sedang–Berat | 95.00% | R5 | Lulus |
| C. Blas buku | G6, G7 | D3 | D3 | Sedang | 90.00% | R9 | Lulus |
| D. Lingkungan | G11, G12 | D4 | D4 | Ringan/Risiko | 50.00% | R11 | Lulus |
| E. Tanpa gejala | tidak ada | Tidak ada diagnosis | Tidak dapat menyimpulkan | – | – | – | Lulus |
| F. Campuran | G1, G2, G3, G4, G8, G9, G10 | D1 dan D2, urut CF | D1, lalu D2 (seri, urut ID) | Berat; Sedang–Berat | 95.00%, 95.00% | R1; R5 | Lulus |
| G. Gejala minim | G9 | D5 | D5 | Rendah | 40.00% | R19 | Lulus |

## Pengujian tambahan

| Pengujian | Hasil |
|---|---|
| Jumlah 12 gejala dan 21 aturan, premis/2 sama dengan badan menyebabkan/2 | Lulus |
| Label keparahan D1–D5 sesuai dan tersedia di API | Lulus |
| Subsumption: CF D1 untuk G8, G9, G10 tidak lebih rendah daripada G8, G9 | Lulus |
| Seri CF memilih aturan lebih spesifik | Lulus |
| Aturan beririsan sebagian tetap digabung (G1, G4, G5 = 95%) | Lulus |
| 4.096 kombinasi: menambah satu gejala tidak menurunkan CF diagnosis yang tetap tampil | Lulus |
| 4.096 kombinasi: D4 tidak tampil bersama D1–D3 | Lulus |
| 4.096 kombinasi: D5 tidak tampil bersama D1–D4 | Lulus |
| 4.096 kombinasi: R1–R21 masing-masing pernah dihitung (tidak ada aturan mati) | Lulus |
| Hasil `hasil_diagnosa/1` skenario A–G sama dengan `POST /api/diagnosa` | Lulus |
| Input API tidak valid ditolak dengan status 400 | Lulus |

## Catatan analisis (bahan Bab 4.3)

- **CF hasil saat ini sama dengan CF aturan.** Jawaban hanya Y atau T, sehingga min(CF jawaban) selalu 1.0 untuk aturan yang terpicu.
- **Skenario F seri pada 95%.** D1 tampil lebih dulu karena aturan seri diurutkan menurut ID, bukan karena keyakinannya lebih tinggi.
- **Irisan sebagian masih dapat menaikkan CF.** G1, G4, G5 menghasilkan 95% dari R7 dan R8, sama dengan R5 yang memerlukan G1–G4 lengkap. G1 berkontribusi pada kedua aturan.
- **Label keparahan melekat pada diagnosis.** G8 saja menghasilkan D1 dengan keparahan Berat dan keyakinan 55%, walaupun R4 dirancang sebagai derajat awal.
- **Akurasi klinis belum diukur.** Test membuktikan sistem konsisten dengan aturan, bukan bahwa diagnosis benar di lapangan. PDF meminta analisis akurasi, sehingga kelompok perlu membandingkan hasil dengan kasus dari literatur atau pakar.
