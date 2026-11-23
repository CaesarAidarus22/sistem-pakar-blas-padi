# Penjelasan Teknis

Dokumen ini dapat diadaptasi untuk Bab III dan Bab IV laporan.

## 1. Arsitektur

```text
┌──────────────────────────────┐
│ basis_pengetahuan.pl         │
│ gejala/2, cf_gejala/2        │
│ diagnosis/2, menyebabkan/2   │
│ premis/2, cf_aturan/2        │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ mesin_inferensi.pl           │
│ ya/1, tanya_gejala/1         │
│ diagnosa/3, cf_hasil/2       │
│ subsumption, prioritas       │
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

Predikat inti ini mengumpulkan aturan terpicu, menerapkan subsumption, menggabungkan CF, menerapkan prioritas, lalu mengurutkan hasil.

## 4. Perhitungan Certainty Factor

```text
Jawaban Y = 1.0; jawaban T = aturan gagal
CF premis = min(CF pakar semua gejala di premis) × 1.0
CF hasil  = CF premis × CF aturan
CFgab     = CF1 + CF2 × (1 − CF1)
```

Contoh skenario A (G8, G9, G10):

| Aturan | CF premis | CF aturan | CF hasil | Status |
|---|---:|---:|---:|---|
| R1: G8, G9, G10 | min(0.8, 0.6, 0.4) = 0.4 | 0.95 | 0.38 | Diabaikan |
| R2: G8, G9 | min(0.8, 0.6) = 0.6 | 0.90 | 0.54 | **Dihitung** |
| R3: G8, G10 | min(0.8, 0.4) = 0.4 | 0.80 | 0.32 | Diabaikan |
| R4: G8 | 0.8 | 0.55 | 0.44 | Diabaikan |

CF akhir D1 = 54.00%.

## 5. Subsumption CF maksimum per rantai

Rumus kombinasi CF mengasumsikan bukti antar-aturan independen. Pada aturan R2 dan R4, G8 muncul di keduanya. Jika keduanya digabung, bukti G8 terhitung dua kali dan CF menjadi terlalu tinggi.

Namun, memilih aturan paling spesifik saja juga bermasalah. Premis AND memakai `min`, sehingga menambah gejala lemah dapat menurunkan CF. Pada contoh di atas, R1 lebih spesifik daripada R2 tetapi hanya bernilai 38%.

Solusinya:

1. Bandingkan setiap pasangan aturan terpicu dengan kesimpulan sama.
2. Jika premis satu aturan adalah subset dari premis aturan lain, aturan dengan CF hasil lebih rendah gugur.
3. Jika CF seri, aturan yang kurang spesifik gugur.
4. Aturan yang tersisa digabung dengan rumus kombinasi.

Seluruh perbandingan memakai himpunan aturan terpicu awal, sehingga hasil tidak bergantung pada urutan aturan. Aturan yang bertahan tidak memiliki pasangan subset.

## 6. Prioritas diagnosis

| Kondisi | Diagnosis yang tampil |
|---|---|
| Ada D1, D2, atau D3 | D1–D3 yang terpicu. G11/G12 = Y tampil sebagai faktor risiko pendukung |
| Tidak ada D1–D3, ada D4 | D4 |
| Hanya D5 | D5 |
| Tidak ada aturan terpicu | "Sistem tidak dapat menyimpulkan; konsultasikan dengan PPL." |

Tingkat prioritas disimpan pada `tingkat_diagnosis/2` di basis pengetahuan.

## 7. Batasan sistem

- Nilai CF masih draf dan belum tervalidasi literatur atau pakar.
- Aturan yang hanya beririsan sebagian tetap digabung. Contoh: R5 dan R7 sama-sama memakai G1.
- Dengan CF G10 = 0.4, aturan R1, R3, dan R21 tidak pernah dihitung.
- Urutan diagnosis mengikuti CF, bukan tingkat keparahan penyakit.
- Sistem hanya mencakup blas padi dan tidak membedakan penyakit lain dengan gejala serupa.
- Pengujian membuktikan konsistensi logika, bukan akurasi diagnosis di lapangan.
