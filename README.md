# Sistem Pakar Diagnosa Dini Penyakit Blas pada Tanaman Padi

Sistem pakar berbasis aturan untuk memperkirakan diagnosis dini penyakit blas (*Pyricularia oryzae*) pada padi. Basis pengetahuan dan mesin inferensi ditulis dalam SWI-Prolog dengan **Backward Chaining** dan **Certainty Factor (CF)**. Tugas 2 mata kuliah Kecerdasan Artifisial (MMAI1001).

> **Catatan:** semua nilai CF masih **draf** dan harus divalidasi dengan literatur atau pakar. Hasil sistem tidak menggantikan pemeriksaan PPL/POPT.

## Struktur folder

```text
prolog/basis_pengetahuan.pl   fakta gejala, diagnosis, aturan, nilai CF (file yang diedit saat validasi)
prolog/mesin_inferensi.pl     backward chaining, CF, subsumption, prioritas diagnosis
prolog/konsol.pl              antarmuka konsol
prolog/server.pl              web server dan API, port 8080
web/                          index.html, style.css, app.js (hanya tampilan)
tests/test_sistem.pl          unit test plunit
docs/hasil_uji.md             tabel hasil pengujian
docs/penjelasan_teknis.md     bahan Bab III dan IV
docs/contoh_konsol.txt        contoh sesi konsol
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

```console
$ swipl prolog/server.pl
```

Buka <http://localhost:8080>. Ketik `halt.` di terminal untuk mematikan server.

### Test

```console
$ swipl -g run_tests -t halt tests/test_sistem.pl
```

## Basis pengetahuan

### Gejala

| ID | Organ | Gejala | CF pakar (draf) |
|---|---|---|---:|
| G1 | Daun | Bercak belah ketupat (lonjong, ujung runcing) pada daun | 0.8 |
| G2 | Daun | Pusat bercak abu-abu atau keputihan | 0.7 |
| G3 | Daun | Tepi bercak cokelat kemerahan | 0.6 |
| G4 | Daun | Bercak menyatu sehingga daun mengering | 0.6 |
| G5 | Daun | Bibit atau anakan layu dan mati | 0.5 |
| G6 | Batang/Buku | Buku batang cokelat kehitaman | 0.7 |
| G7 | Batang/Buku | Batang mudah patah pada bagian buku | 0.6 |
| G8 | Malai | Leher malai cokelat kehitaman (busuk leher) | 0.8 |
| G9 | Malai | Malai patah atau terkulai | 0.6 |
| G10 | Malai | Gabah hampa atau pengisian tidak sempurna | 0.4 |
| G11 | Lingkungan & Budidaya | Lingkungan lembap, berembun, atau sering hujan | 0.3 |
| G12 | Lingkungan & Budidaya | Pemupukan nitrogen (urea) berlebihan | 0.3 |

### Diagnosis

| ID | Diagnosis | Saran tindakan |
|---|---|---|
| D1 | Blas leher (neck blast), tingkat berat | Kehilangan hasil tinggi; segera aplikasikan fungisida sistemik dan konsultasikan dengan PPL/POPT |
| D2 | Blas daun (leaf blast), tingkat sedang–berat | Kurangi pupuk N, aplikasikan fungisida, perbaiki jarak tanam |
| D3 | Blas buku (node blast) | Aplikasikan fungisida dan pantau penyebaran ke malai |
| D4 | Gejala awal blas / risiko tinggi | Pemantauan rutin, perbaiki drainase, gunakan varietas tahan |
| D5 | Kemungkinan rendah blas | Gejala tidak cukup kuat, kemungkinan penyakit lain; konsultasikan dengan PPL |

### Aturan

| Aturan | IF | THEN | CF aturan (draf) |
|---|---|---|---:|
| R1 | G8 AND G9 AND G10 | D1 | 0.95 |
| R2 | G8 AND G9 | D1 | 0.90 |
| R3 | G8 AND G10 | D1 | 0.80 |
| R4 | G8 | D1 | 0.55 |
| R5 | G1 AND G2 AND G3 AND G4 | D2 | 0.95 |
| R6 | G1 AND G2 AND G3 | D2 | 0.90 |
| R7 | G1 AND G5 | D2 | 0.80 |
| R8 | G1 AND G4 | D2 | 0.75 |
| R9 | G6 AND G7 | D3 | 0.90 |
| R10 | G6 | D3 | 0.60 |
| R11 | G11 AND G12 | D4 | 0.50 |
| R12 | G1 | D4 | 0.30 |
| R13 | G2 AND G3 | D4 | 0.30 |
| R14 | G11 | D4 | 0.40 |
| R15 | G12 | D4 | 0.40 |
| R16 | G4 | D5 | 0.30 |
| R17 | G5 | D5 | 0.30 |
| R18 | G7 | D5 | 0.40 |
| R19 | G9 | D5 | 0.40 |
| R20 | G10 | D5 | 0.35 |
| R21 | G9 AND G10 | D5 | 0.50 |

## Perhitungan CF

```text
CF premis = min(CF pakar semua gejala di premis) × 1.0
CF hasil  = CF premis × CF aturan
CFgab     = CF1 + CF2 × (1 − CF1)
```

**Subsumption (CF maksimum per rantai).** Rumus kombinasi mengasumsikan bukti antar-aturan independen. Karena itu, jika premis satu aturan adalah subset dari premis aturan lain dengan kesimpulan sama, hanya aturan dengan CF hasil lebih tinggi yang dihitung. Jika seri, aturan yang lebih spesifik dipilih. Semua pasangan dibandingkan dari himpunan aturan terpicu, sehingga hasil tidak bergantung pada urutan aturan.

**Prioritas tampil.**

1. Jika ada D1, D2, atau D3, maka D4 dan D5 tidak ditampilkan. G11 dan G12 yang dijawab Y tampil sebagai faktor risiko pendukung.
2. Jika tidak ada D1–D3 tetapi ada D4, maka D5 tidak ditampilkan.
3. D5 hanya muncul jika D1–D4 tidak ada.
4. Jika tidak ada aturan terpicu, sistem menampilkan "Sistem tidak dapat menyimpulkan; konsultasikan dengan PPL."

## Pengujian

| Skenario | Input | Hasil sistem |
|---|---|---|
| A | G8, G9, G10 | D1 54.00% |
| B | G1, G2, G3, G4 | D2 57.00% |
| C | G6, G7 | D3 54.00% |
| D | G11, G12 | D4 15.00% |
| E | tanpa gejala | tidak dapat menyimpulkan |
| F | G1, G2, G3, G4, G8, G9, G10 | D2 57.00%, D1 54.00% |
| G | G9 | D5 24.00% |

Rincian ada di [docs/hasil_uji.md](docs/hasil_uji.md). Penjelasan mekanisme ada di [docs/penjelasan_teknis.md](docs/penjelasan_teknis.md).

## Batasan

- Nilai CF masih draf dan daftar pustaka belum diisi.
- Dengan CF G10 = 0.4, aturan R1, R3, dan R21 terpicu tetapi tidak pernah dihitung. G10 karena itu tidak menaikkan CF D1.
- Aturan yang premisnya hanya beririsan sebagian tetap digabung, sehingga gejala yang sama masih dapat berkontribusi dua kali.
