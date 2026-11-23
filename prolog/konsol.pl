% konsol.pl
% Antarmuka konsol. Cara pakai:
%   ?- consult('prolog/konsol.pl').
%   ?- mulai.

:- encoding(utf8).
:- ensure_loaded(mesin_inferensi).

mulai :-
    catch(set_stream(user_output, encoding(utf8)), _, true),
    reset_jawaban,
    nl,
    writeln('=== SISTEM PAKAR DIAGNOSA DINI PENYAKIT BLAS PADI ==='),
    writeln('Jawab setiap gejala dengan Y (ya) atau T (tidak).'),
    nl,
    catch(( forall(gejala(G, _), tanya_gejala(G)), diagnosa ),
          input_habis,
          ( nl, writeln('Input berakhir. Diagnosis dibatalkan.') )),
    reset_jawaban.

% diagnosa: jalankan penalaran lalu tampilkan hasilnya.
diagnosa :-
    hasil_diagnosa(Hasil),
    faktor_risiko(Hasil, Faktor),
    nl,
    writeln('=== HASIL DIAGNOSA ==='),
    tampilkan_hasil(Hasil, Faktor).

tampilkan_hasil([], _) :-
    pesan_tanpa_kesimpulan(Pesan),
    writeln(Pesan).
tampilkan_hasil([H|T], Faktor) :-
    forall(nth1(No, [H|T], Item), tampilkan_diagnosis(No, Item)),
    tampilkan_faktor(Faktor).

tampilkan_diagnosis(No, hasil(D, _, Persen, Aturan)) :-
    pisah_diagnosis(D, Nama, Saran),
    teks_persen(Persen, Teks),
    upcase_atom(D, Label),
    format('~w. [~w] ~w~n   CF: ~s~n   Saran: ~w~n   Mengapa:~n',
           [No, Label, Nama, Teks, Saran]),
    forall(member(A, Aturan), tampilkan_aturan(A)).

tampilkan_aturan(aturan(R, Premis, CFAturan, CFHasil, Status)) :-
    upcase_atom(R, Label),
    maplist([G, L]>>upcase_atom(G, L), Premis, Labels),
    atomic_list_concat(Labels, ' AND ', Teks),
    persen(CFHasil, Persen),
    teks_persen(Persen, TeksCF),
    format('   - ~w: IF ~w (CF aturan ~2f, hasil ~s, ~w)~n',
           [Label, Teks, CFAturan, TeksCF, Status]).

tampilkan_faktor([]).
tampilkan_faktor([F|Fs]) :-
    writeln('Faktor risiko pendukung:'),
    forall(member(G, [F|Fs]),
           ( gejala(G, Deskripsi),
             upcase_atom(G, Label),
             format('   - ~w: ~w~n', [Label, Deskripsi]) )).
