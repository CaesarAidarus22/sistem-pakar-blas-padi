% mesin_inferensi.pl
% Backward chaining, Certainty Factor, subsumption, dan prioritas diagnosis.
% Konsol dan web sama-sama memakai hasil_diagnosa/1.

:- encoding(utf8).
:- ensure_loaded(basis_pengetahuan).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(readutil)).

:- dynamic jawaban/2.

% ---------------------------------------------------------------------
% Input dinamis
% ---------------------------------------------------------------------

% ya(+Gejala): subgoal backward chaining. Bertanya hanya jika belum dijawab.
ya(G) :-
    tanya_gejala(G),
    jawaban(G, y).

% tanya_gejala(+Gejala): simpan jawaban Y/T dengan assert; ulangi jika tidak valid.
tanya_gejala(G) :-
    jawaban(G, _),
    !.
tanya_gejala(G) :-
    gejala(G, Deskripsi),
    upcase_atom(G, Label),
    format('~w: ~w? (Y/T): ', [Label, Deskripsi]),
    flush_output,
    baca_baris(Baris),
    (   Baris == end_of_file
    ->  throw(input_habis)
    ;   normalisasi_jawaban(Baris, Nilai)
    ->  assertz(jawaban(G, Nilai))
    ;   writeln('Input tidak valid. Ketik Y atau T.'),
        tanya_gejala(G)
    ).

baca_baris(Baris) :-
    setup_call_cleanup(
        prompt(Lama, ''),
        read_line_to_string(user_input, Baris),
        prompt(_, Lama)).

normalisasi_jawaban(Teks, Nilai) :-
    normalize_space(string(Bersih), Teks),
    string_lower(Bersih, Kecil),
    memberchk(Kecil-Nilai, ["y"-y, "t"-t]).

reset_jawaban :-
    retractall(jawaban(_, _)).

% muat_jawaban(+Pasangan): Pasangan = [g1-y, g2-t, ...]; gejala yang tidak ada = t.
muat_jawaban(Pasangan) :-
    reset_jawaban,
    forall(gejala(G, _),
           (   memberchk(G-y, Pasangan)
           ->  assertz(jawaban(G, y))
           ;   assertz(jawaban(G, t))
           )).

% ---------------------------------------------------------------------
% Penalaran: backtracking mencoba setiap klausa menyebabkan/2
% ---------------------------------------------------------------------

% diagnosa(?Diagnosis, ?IdAturan, -CFHasil): satu solusi per aturan yang terpicu.
diagnosa(Diagnosis, IdAturan, CFHasil) :-
    diagnosis(Diagnosis, _),
    menyebabkan(Diagnosis, IdAturan),
    cf_hasil(IdAturan, CFHasil).

% CF hasil = CF aturan x min(CF jawaban pengguna untuk semua premis).
cf_hasil(IdAturan, CFHasil) :-
    premis(IdAturan, Premis),
    findall(CF, (member(G, Premis), jawaban(G, J), cf_jawaban(J, CF)), Nilai),
    min_list(Nilai, CFPremis),
    cf_aturan(IdAturan, CFAturan),
    CFHasil is CFAturan * CFPremis.

% hasil_diagnosa(-Hasil): predikat inti untuk konsol dan web.
% Hasil = [hasil(Diagnosis, CF, Persen, Aturan), ...], terurut CF menurun lalu ID.
hasil_diagnosa(Hasil) :-
    findall(H, hasil_per_diagnosis(H), Semua),
    terapkan_prioritas(Semua, Tampil),
    map_list_to_pairs(kunci_urut, Tampil, Berkunci),
    keysort(Berkunci, Urut),
    pairs_values(Urut, Hasil).

kunci_urut(hasil(D, CF, _, _), k(Negatif, D)) :-
    bulat(CF, B),
    Negatif is -B.

hasil_per_diagnosis(hasil(D, CF, Persen, Aturan)) :-
    diagnosis(D, _),
    findall(a(R, P, C), (diagnosa(D, R, C), premis(R, P)), Terpicu),
    Terpicu \== [],
    exclude(kalah_di(Terpicu), Terpicu, Dihitung),
    foldl(gabung_cf, Dihitung, 0.0, CF),
    persen(CF, Persen),
    maplist(info_aturan(Dihitung), Terpicu, Aturan).

info_aturan(Dihitung, A, aturan(R, Premis, CFAturan, CFHasil, Status)) :-
    A = a(R, Premis, CFHasil),
    cf_aturan(R, CFAturan),
    (   memberchk(A, Dihitung)
    ->  Status = dihitung
    ;   Status = diabaikan
    ).

% ---------------------------------------------------------------------
% Subsumption: CF maksimum per rantai subset
% ---------------------------------------------------------------------

% Aturan gugur jika ada aturan terpicu lain yang premisnya sebanding
% (subset/superset) dan menang. Semua pasangan dibandingkan dari himpunan awal,
% sehingga hasilnya tidak bergantung pada urutan aturan.
kalah_di(Terpicu, A) :-
    member(B, Terpicu),
    B \== A,
    menang(B, A),
    !.

menang(a(_, PB, CB), a(_, PA, CA)) :-
    subset_ketat(PA, PB),
    bulat(CB, NB),
    bulat(CA, NA),
    NB >= NA.
menang(a(_, PB, CB), a(_, PA, CA)) :-
    subset_ketat(PB, PA),
    bulat(CB, NB),
    bulat(CA, NA),
    NB > NA.

subset_ketat(Kecil, Besar) :-
    subset(Kecil, Besar),
    length(Kecil, K),
    length(Besar, B),
    K < B.

% Perbandingan seri tahan terhadap galat pembulatan floating point.
bulat(CF, B) :-
    B is round(CF * 1000000000).

% CFgab = CF1 + CF2 x (1 - CF1)
gabung_cf(a(_, _, CF2), CF1, CFGab) :-
    CFGab is CF1 + CF2 * (1 - CF1).

% ---------------------------------------------------------------------
% Prioritas dan format hasil
% ---------------------------------------------------------------------

terapkan_prioritas([], []).
terapkan_prioritas(Semua, Tampil) :-
    Semua \== [],
    findall(T, (member(hasil(D, _, _, _), Semua), tingkat_diagnosis(D, T)), Tingkat),
    min_list(Tingkat, Min),
    include(pada_tingkat(Min), Semua, Tampil).

pada_tingkat(T, hasil(D, _, _, _)) :-
    tingkat_diagnosis(D, T).

% g11/g12 = Y ditampilkan sebagai faktor risiko hanya di bawah D1-D3.
faktor_risiko(Hasil, Faktor) :-
    (   member(hasil(D, _, _, _), Hasil),
        tingkat_diagnosis(D, 1)
    ->  findall(G, (gejala_risiko(G), jawaban(G, y)), Faktor)
    ;   Faktor = []
    ).

persen(CF, Persen) :-
    Persen is round(CF * 10000) / 100.0.

teks_persen(Persen, Teks) :-
    format(string(Teks), '~2f%', [Persen]).

% pisah_diagnosis(+Id, -Nama, -Saran): pisahkan teks diagnosis/2 pada ' — '.
pisah_diagnosis(Id, Nama, Saran) :-
    diagnosis(Id, Teks),
    sub_atom(Teks, Awal, _, Akhir, ' — '),
    !,
    sub_atom(Teks, 0, Awal, _, Nama),
    sub_atom(Teks, _, Akhir, 0, Saran).

pesan_tanpa_kesimpulan('Sistem tidak dapat menyimpulkan; konsultasikan dengan PPL.').
catatan_cf('Persentase menunjukkan tingkat keyakinan sistem, bukan tingkat keparahan.').

% diagnosa_jawaban(+Pasangan, -Hasil, -Faktor): untuk permintaan web.
% Mutex menjaga jawaban/2 agar permintaan bersamaan tidak saling menimpa.
diagnosa_jawaban(Pasangan, Hasil, Faktor) :-
    with_mutex(mesin_inferensi,
               setup_call_cleanup(
                   muat_jawaban(Pasangan),
                   ( hasil_diagnosa(Hasil), faktor_risiko(Hasil, Faktor) ),
                   reset_jawaban)).
