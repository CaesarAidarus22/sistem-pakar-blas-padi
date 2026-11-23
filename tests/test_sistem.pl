% test_sistem.pl
% Jalankan dari folder project: swipl -g run_tests -t halt tests/test_sistem.pl

:- encoding(utf8).
:- create_prolog_flag(blas_tanpa_server, true, []).
:- use_module(library(plunit)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).
:- use_module(library(assoc)).
:- ensure_loaded('../prolog/konsol').
:- ensure_loaded('../prolog/server').

uji(Gejala, Hasil, Faktor) :-
    findall(G-y, member(G, Gejala), Pasangan),
    diagnosa_jawaban(Pasangan, Hasil, Faktor).

ringkas(Gejala, Ringkas) :-
    uji(Gejala, Hasil, _),
    findall(D-T, (member(hasil(D, _, P, _), Hasil), teks_persen(P, S), atom_string(T, S)), Ringkas).

skenario(a, [g8, g9, g10]).
skenario(b, [g1, g2, g3, g4]).
skenario(c, [g6, g7]).
skenario(d, [g11, g12]).
skenario(e, []).
skenario(f, [g1, g2, g3, g4, g8, g9, g10]).
skenario(g, [g9]).

:- begin_tests(struktur).

test(jumlah_gejala_dan_aturan) :-
    aggregate_all(count, gejala(_, _), 12),
    aggregate_all(count, premis(_, _), 21),
    aggregate_all(count, cf_aturan(_, _), 21),
    aggregate_all(count, clause(menyebabkan(_, _), _), 21).

test(premis_sama_dengan_badan_aturan) :-
    forall(clause(menyebabkan(_, R), Badan),
           ( comma_list(Badan, Goals),
             findall(G, member(ya(G), Goals), Gs),
             premis(R, Gs) )).

:- end_tests(struktur).

:- begin_tests(skenario).

test(a_blas_leher) :- ringkas([g8, g9, g10], [d1-'54.00%']).
test(b_blas_daun_tanpa_d4) :- ringkas([g1, g2, g3, g4], [d2-'57.00%']).
test(c_blas_buku) :- ringkas([g6, g7], [d3-'54.00%']).
test(d_lingkungan) :- ringkas([g11, g12], [d4-'15.00%']).
test(e_tanpa_gejala) :- uji([], [], []).
test(f_campuran_urut_cf) :- ringkas([g1, g2, g3, g4, g8, g9, g10], [d2-'57.00%', d1-'54.00%']).
test(g_gejala_minim) :- ringkas([g9], [d5-'24.00%']).

test(faktor_risiko_di_bawah_diagnosis_utama) :-
    uji([g8, g11, g12], [hasil(d1, _, _, _)], [g11, g12]).

test(faktor_risiko_tidak_muncul_pada_d4) :-
    uji([g11, g12], [hasil(d4, _, _, _)], []).

test(seri_urut_id) :-
    Hasil = [hasil(d2, 0.5, 50.0, []), hasil(d1, 0.5, 50.0, [])],
    map_list_to_pairs(kunci_urut, Hasil, K),
    keysort(K, S),
    pairs_values(S, [hasil(d1, _, _, _), hasil(d2, _, _, _)]).

:- end_tests(skenario).

:- begin_tests(subsumption).

test(cf_d1_tidak_turun) :-
    uji([g8, g9], [hasil(d1, CF1, _, _)], _),
    uji([g8, g9, g10], [hasil(d1, CF2, _, _)], _),
    CF2 >= CF1.

test(hanya_cf_tertinggi_per_rantai) :-
    uji([g8, g9, g10], [hasil(d1, _, _, Aturan)], _),
    findall(R, member(aturan(R, _, _, _, dihitung), Aturan), [r2]).

test(seri_pilih_yang_lebih_spesifik) :-
    A = a(r_umum, [g1], 0.5),
    B = a(r_khusus, [g1, g2], 0.5),
    exclude(kalah_di([A, B]), [A, B], [B]).

test(irisan_sebagian_tetap_digabung) :-
    uji([g1, g4, g5], [hasil(d2, CF, _, Aturan)], _),
    findall(R, member(aturan(R, _, _, _, dihitung), Aturan), Rs),
    msort(Rs, [r7, r8]),
    abs(CF - 0.67) < 1.0e-9.

:- end_tests(subsumption).

:- begin_tests(brute_force).

semua_gejala(Gs) :- findall(G, gejala(G, _), Gs).

gejala_mask(Mask, Gs, Terpilih) :-
    findall(G, (nth0(I, Gs, G), Mask /\ (1 << I) =\= 0), Terpilih).

tabel(Tabel) :-
    semua_gejala(Gs),
    findall(M-R, ( between(0, 4095, M), gejala_mask(M, Gs, T), uji(T, H, _),
                   findall(D-CF, member(hasil(D, CF, _, _), H), R) ), Baris),
    list_to_assoc(Baris, Tabel).

% CF boleh hilang hanya jika tersingkir oleh diagnosis tingkat lebih tinggi.
pelanggaran(Tabel, M-G-D) :-
    between(0, 4095, M),
    get_assoc(M, Tabel, A),
    between(0, 11, I),
    M /\ (1 << I) =:= 0,
    M2 is M \/ (1 << I),
    get_assoc(M2, Tabel, B),
    member(D-CFA, A),
    (   memberchk(D-CFB, B)
    ->  CFB < CFA - 1.0e-9
    ;   tingkat_diagnosis(D, TD),
        \+ ( member(D2-_, B), tingkat_diagnosis(D2, T2), T2 < TD )
    ),
    G = I.

test(jumlah_kombinasi) :-
    tabel(T),
    assoc_to_keys(T, K),
    length(K, 4096).

test(tambah_gejala_tidak_menurunkan_cf) :-
    tabel(T),
    findall(P, pelanggaran(T, P), []).

test(d4_tidak_bersama_d1_d3) :-
    tabel(T),
    assoc_to_values(T, Vs),
    forall(member(V, Vs),
           \+ ( memberchk(d4-_, V), member(D-_, V), memberchk(D, [d1, d2, d3]) )).

test(d5_tidak_bersama_d1_d4) :-
    tabel(T),
    assoc_to_values(T, Vs),
    forall(member(V, Vs),
           \+ ( memberchk(d5-_, V), member(D-_, V), memberchk(D, [d1, d2, d3, d4]) )).

:- end_tests(brute_force).

:- begin_tests(konsistensi_web, [setup(nyalakan(Port)), cleanup(http_stop_server(Port, []))]).

test(skenario_a_g_sama_dengan_api) :-
    nb_getval(port_uji, Port),
    format(atom(Url), 'http://localhost:~w/api/diagnosa', [Port]),
    forall(skenario(_, Gs),
           ( ringkas(Gs, Harap),
             findall(G-"y", member(G, Gs), Ps),
             dict_pairs(Body, _, Ps),
             http_post(Url, json(Body), Balas, [json_object(dict)]),
             findall(D-T, ( member(X, Balas.diagnosis),
                            atom_string(D, X.id),
                            atom_string(T, X.cf_teks) ), Harap) )).

test(input_tidak_valid_ditolak) :-
    nb_getval(port_uji, Port),
    format(atom(Url), 'http://localhost:~w/api/diagnosa', [Port]),
    http_post(Url, json(_{g99: "y"}), _, [status_code(400), json_object(dict)]).

:- end_tests(konsistensi_web).

nyalakan(Port) :-
    http_server(http_dispatch, [port(localhost:Port), workers(2)]),
    nb_setval(port_uji, Port).
