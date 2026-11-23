# Penjelasan Teknis

Dokumen ini dapat diadaptasi untuk Bab III dan Bab IV laporan.

## 1. Arsitektur

```text
┌──────────────────────────────┐
│ basis_pengetahuan.pl         │
│ gejala/2, diagnosis/2        │
│ menyebabkan/2, premis/2      │
│ cf_aturan/2, derajat_aturan/2│
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

CF dan derajat menjawab dua pertanyaan berbeda.

- **CF (keyakinan):** seberapa yakin sistem bahwa diagnosis itu benar berdasarkan gejala.
- **Derajat:** seberapa berat kondisi menurut aturan yang menjadi dasar diagnosis.

Derajat disimpan per aturan pada `derajat_aturan/2`. Label diagnosis diambil dari aturan terpicu dengan CF tertinggi. Jika CF seri, urutannya Berat > Sedang–Berat > Sedang > Awal > Risiko > Rendah, lalu ID aturan.

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

Contoh: G8 saja menghasilkan D1 dengan keyakinan 55% dan "Derajat: Awal (berdasarkan aturan R4)". Konsol dan web juga menampilkan kalimat "Persentase menunjukkan tingkat keyakinan sistem, bukan tingkat keparahan."

## 8. Batasan sistem

- Nilai CF masih draf dan belum tervalidasi literatur atau pakar.
- Komponen hanya memakai CF tertinggi, sehingga gejala tambahan dalam komponen yang sama belum tentu menaikkan CF. Contoh: G1, G4, G5 tetap 80%.
- Jawaban hanya Y atau T, sehingga CF hasil aturan yang terpicu sama dengan CF aturan.
- Label derajat D2 dapat turun saat gejala bertambah, walaupun CF tidak turun. Contoh: G1, G2, G5 = Berat (R7, 80%), lalu dengan G3 = Sedang (R6, 90%). Ini terjadi pada 256 transisi.
- Nama diagnosis dapat berbeda dengan derajat. Contoh: G8 saja tampil sebagai "tingkat berat" dengan Derajat Awal.
- Urutan diagnosis mengikuti CF, bukan tingkat keparahan penyakit.
- Sistem hanya mencakup blas padi dan tidak membedakan penyakit lain dengan gejala serupa.
- Pengujian membuktikan konsistensi logika, bukan akurasi diagnosis di lapangan.
