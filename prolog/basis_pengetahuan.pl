% basis_pengetahuan.pl
% Fakta gejala, diagnosis, aturan IF-THEN, dan nilai CF penyakit blas padi.
% Ini satu-satunya file yang perlu diedit kelompok saat validasi.
% Jika premis aturan diubah, ubah menyebabkan/2 DAN premis/2 bersama-sama
% (tests/test_sistem.pl memeriksa keduanya tetap sama).

:- encoding(utf8).
:- discontiguous menyebabkan/2, premis/2, cf_aturan/2.

% ---------------------------------------------------------------------
% GEJALA: gejala(IdGejala, Deskripsi)
% CF pakar hanya ada pada level aturan (lihat cf_aturan/2).
% ---------------------------------------------------------------------

% Daun
gejala(g1, 'Bercak belah ketupat (lonjong, ujung runcing) pada daun').
gejala(g2, 'Pusat bercak abu-abu atau keputihan').
gejala(g3, 'Tepi bercak cokelat kemerahan').
gejala(g4, 'Bercak menyatu sehingga daun mengering').
gejala(g5, 'Bibit atau anakan layu dan mati').

% Batang/Buku
gejala(g6, 'Buku batang cokelat kehitaman').
gejala(g7, 'Batang mudah patah pada bagian buku').

% Malai
gejala(g8, 'Leher malai cokelat kehitaman (busuk leher)').
gejala(g9, 'Malai patah atau terkulai').
gejala(g10, 'Gabah hampa atau pengisian tidak sempurna').

% Lingkungan & Budidaya
gejala(g11, 'Lingkungan lembap, berembun, atau sering hujan').
gejala(g12, 'Pemupukan nitrogen (urea) berlebihan').

% Kelompok organ untuk tampilan web.
kelompok_organ('Daun', [g1, g2, g3, g4, g5]).
kelompok_organ('Batang/Buku', [g6, g7]).
kelompok_organ('Malai', [g8, g9, g10]).
kelompok_organ('Lingkungan & Budidaya', [g11, g12]).

% Gejala yang ditampilkan sebagai faktor risiko pendukung.
gejala_risiko(g11).
gejala_risiko(g12).

% CF jawaban pengguna. Jawaban t membuat premis gagal.
cf_jawaban(y, 1.0).

% ---------------------------------------------------------------------
% DIAGNOSIS: diagnosis(IdDiagnosis, 'Nama — saran tindakan')
% ---------------------------------------------------------------------

diagnosis(d1, 'Blas leher (neck blast) — kehilangan hasil tinggi; segera aplikasikan fungisida sistemik dan konsultasikan dengan PPL/POPT').
diagnosis(d2, 'Blas daun (leaf blast) — kurangi pupuk N, aplikasikan fungisida, perbaiki jarak tanam').
diagnosis(d3, 'Blas buku (node blast) — aplikasikan fungisida dan pantau penyebaran ke malai').
diagnosis(d4, 'Gejala awal blas / risiko tinggi — pemantauan rutin, perbaiki drainase, gunakan varietas tahan').
diagnosis(d5, 'Kemungkinan rendah blas — gejala tidak cukup kuat, kemungkinan penyakit lain; konsultasikan dengan PPL').

% Tingkat prioritas tampil: hanya tingkat terkecil yang terpicu ditampilkan.
tingkat_diagnosis(d1, 1).
tingkat_diagnosis(d2, 1).
tingkat_diagnosis(d3, 1).
tingkat_diagnosis(d4, 2).
tingkat_diagnosis(d5, 3).

% Derajat per aturan. Derajat diagnosis = derajat paling berat dari aturan terpicu.
derajat_aturan(r1, 'Berat'). % TODO: validasi literatur
derajat_aturan(r2, 'Berat'). % TODO: validasi literatur
derajat_aturan(r3, 'Sedang'). % TODO: validasi literatur
derajat_aturan(r4, 'Awal'). % TODO: validasi literatur
derajat_aturan(r5, 'Berat'). % TODO: validasi literatur
derajat_aturan(r6, 'Sedang'). % TODO: validasi literatur
derajat_aturan(r7, 'Berat'). % TODO: validasi literatur
derajat_aturan(r8, 'Sedang'). % TODO: validasi literatur
derajat_aturan(r9, 'Sedang–Berat'). % TODO: validasi literatur
derajat_aturan(r10, 'Awal'). % TODO: validasi literatur
derajat_aturan(r11, 'Risiko'). % TODO: validasi literatur
derajat_aturan(r12, 'Risiko'). % TODO: validasi literatur
derajat_aturan(r13, 'Risiko'). % TODO: validasi literatur
derajat_aturan(r14, 'Risiko'). % TODO: validasi literatur
derajat_aturan(r15, 'Risiko'). % TODO: validasi literatur
derajat_aturan(r16, 'Rendah'). % TODO: validasi literatur
derajat_aturan(r17, 'Rendah'). % TODO: validasi literatur
derajat_aturan(r18, 'Rendah'). % TODO: validasi literatur
derajat_aturan(r19, 'Rendah'). % TODO: validasi literatur
derajat_aturan(r20, 'Rendah'). % TODO: validasi literatur
derajat_aturan(r21, 'Rendah'). % TODO: validasi literatur

% Urutan tie-break: angka kecil = derajat lebih berat.
urutan_derajat('Berat', 1).
urutan_derajat('Sedang–Berat', 2).
urutan_derajat('Sedang', 3).
urutan_derajat('Awal', 4).
urutan_derajat('Risiko', 5).
urutan_derajat('Rendah', 6).

% ---------------------------------------------------------------------
% ATURAN: menyebabkan(Diagnosis, IdAturan) :- ya(Gejala), ...
%         premis(IdAturan, [Gejala...]) dan cf_aturan(IdAturan, Nilai)
% ---------------------------------------------------------------------

% --- D1: Blas leher ---

% R1: busuk leher, malai patah, dan gabah hampa adalah rangkaian lengkap
% kerusakan leher malai yang menghambat pengisian bulir.
menyebabkan(d1, r1) :- ya(g8), ya(g9), ya(g10).
premis(r1, [g8, g9, g10]).
cf_aturan(r1, 0.95). % TODO: validasi literatur

% R2: busuk leher yang sudah melemahkan leher sampai malai patah.
menyebabkan(d1, r2) :- ya(g8), ya(g9).
premis(r2, [g8, g9]).
cf_aturan(r2, 0.90). % TODO: validasi literatur

% R3: busuk leher disertai gangguan pengisian gabah.
menyebabkan(d1, r3) :- ya(g8), ya(g10).
premis(r3, [g8, g10]).
cf_aturan(r3, 0.80). % TODO: validasi literatur

% R4: busuk leher tanpa kerusakan malai lanjutan (derajat awal).
menyebabkan(d1, r4) :- ya(g8).
premis(r4, [g8]).
cf_aturan(r4, 0.55). % TODO: validasi literatur

% --- D2: Blas daun ---

% R5: bercak khas lengkap dan sudah menyatu menunjukkan blas daun berat.
menyebabkan(d2, r5) :- ya(g1), ya(g2), ya(g3), ya(g4).
premis(r5, [g1, g2, g3, g4]).
cf_aturan(r5, 0.95). % TODO: validasi literatur

% R6: bentuk, pusat, dan tepi bercak semuanya khas blas daun.
menyebabkan(d2, r6) :- ya(g1), ya(g2), ya(g3).
premis(r6, [g1, g2, g3]).
cf_aturan(r6, 0.90). % TODO: validasi literatur

% R7: bercak belah ketupat disertai kematian bibit atau anakan (derajat berat).
menyebabkan(d2, r7) :- ya(g1), ya(g5).
premis(r7, [g1, g5]).
cf_aturan(r7, 0.80). % TODO: validasi literatur

% R8: bercak belah ketupat yang meluas dan menyatu (derajat sedang).
menyebabkan(d2, r8) :- ya(g1), ya(g4).
premis(r8, [g1, g4]).
cf_aturan(r8, 0.75). % TODO: validasi literatur

% --- D3: Blas buku ---

% R9: buku menghitam dan batang patah di buku adalah pola khas blas buku.
menyebabkan(d3, r9) :- ya(g6), ya(g7).
premis(r9, [g6, g7]).
cf_aturan(r9, 0.90). % TODO: validasi literatur

% R10: buku menghitam tanpa patah batang (derajat awal).
menyebabkan(d3, r10) :- ya(g6).
premis(r10, [g6]).
cf_aturan(r10, 0.60). % TODO: validasi literatur

% --- D4: Gejala awal / risiko tinggi ---

% R11: lingkungan lembap dan nitrogen berlebih bersama-sama meningkatkan risiko.
menyebabkan(d4, r11) :- ya(g11), ya(g12).
premis(r11, [g11, g12]).
cf_aturan(r11, 0.50). % TODO: validasi literatur

% R12: bercak belah ketupat tunggal belum cukup untuk memastikan blas daun.
menyebabkan(d4, r12) :- ya(g1).
premis(r12, [g1]).
cf_aturan(r12, 0.30). % TODO: validasi literatur

% R13: warna bercak mirip blas, tetapi bentuk khasnya belum terlihat.
menyebabkan(d4, r13) :- ya(g2), ya(g3).
premis(r13, [g2, g3]).
cf_aturan(r13, 0.30). % TODO: validasi literatur

% R14: kelembapan tinggi mendukung perkembangan jamur, tanpa gejala tanaman.
menyebabkan(d4, r14) :- ya(g11).
premis(r14, [g11]).
cf_aturan(r14, 0.40). % TODO: validasi literatur

% R15: nitrogen berlebih meningkatkan kerentanan tanaman, tanpa gejala tanaman.
menyebabkan(d4, r15) :- ya(g12).
premis(r15, [g12]).
cf_aturan(r15, 0.40). % TODO: validasi literatur

% --- D5: Kemungkinan rendah blas ---

% R16: daun mengering tanpa bercak khas dapat disebabkan faktor lain.
menyebabkan(d5, r16) :- ya(g4).
premis(r16, [g4]).
cf_aturan(r16, 0.30). % TODO: validasi literatur

% R17: bibit layu tanpa bercak khas tidak spesifik untuk blas.
menyebabkan(d5, r17) :- ya(g5).
premis(r17, [g5]).
cf_aturan(r17, 0.30). % TODO: validasi literatur

% R18: batang patah tanpa buku menghitam dapat disebabkan penyebab lain.
menyebabkan(d5, r18) :- ya(g7).
premis(r18, [g7]).
cf_aturan(r18, 0.40). % TODO: validasi literatur

% R19: malai patah tanpa busuk leher tidak spesifik untuk blas.
menyebabkan(d5, r19) :- ya(g9).
premis(r19, [g9]).
cf_aturan(r19, 0.40). % TODO: validasi literatur

% R20: gabah hampa memiliki banyak kemungkinan penyebab.
menyebabkan(d5, r20) :- ya(g10).
premis(r20, [g10]).
cf_aturan(r20, 0.35). % TODO: validasi literatur

% R21: malai patah dan gabah hampa tanpa busuk leher masih belum spesifik.
menyebabkan(d5, r21) :- ya(g9), ya(g10).
premis(r21, [g9, g10]).
cf_aturan(r21, 0.50). % TODO: validasi literatur
