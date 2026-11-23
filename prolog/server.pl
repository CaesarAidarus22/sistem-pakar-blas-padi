% server.pl
% Web server. Jalankan: swipl prolog/server.pl lalu buka http://localhost:8080

:- encoding(utf8).
:- ensure_loaded(mesin_inferensi).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).

:- prolog_load_context(directory, Dir),
   directory_file_path(Dir, '../web', Web),
   assertz(user:file_search_path(web_root, Web)).

:- http_handler(root(api/gejala), api_gejala, [method(get)]).
:- http_handler(root(api/diagnosa), api_diagnosa, [method(post)]).
:- http_handler(root(.), http_reply_from_files(web_root(.), [indexes(['index.html'])]), [prefix]).

mulai_server :-
    http_server(http_dispatch, [port(localhost:8080)]),
    writeln('Server berjalan di http://localhost:8080 (ketik halt. untuk berhenti)').

api_gejala(_Request) :-
    findall(_{organ: Organ, gejala: Daftar},
            ( kelompok_organ(Organ, Ids), maplist(json_gejala, Ids, Daftar) ),
            Kelompok),
    reply_json_dict(_{kelompok: Kelompok}).

api_diagnosa(Request) :-
    (   catch(http_read_json_dict(Request, Body), _, fail),
        is_dict(Body),
        dict_pairs(Body, _, Mentah),
        maplist(jawaban_valid, Mentah, Pasangan)
    ->  diagnosa_jawaban(Pasangan, Hasil, Faktor),
        maplist(json_hasil, Hasil, Diagnosis),
        maplist(json_gejala, Faktor, FaktorJson),
        (   Hasil == []
        ->  pesan_tanpa_kesimpulan(Pesan)
        ;   Pesan = null
        ),
        catatan_cf(Catatan),
        reply_json_dict(_{diagnosis: Diagnosis, faktor_risiko: FaktorJson,
                          pesan: Pesan, catatan: Catatan})
    ;   reply_json_dict(_{error: "Format jawaban tidak valid. Contoh: {\"g1\":\"y\",\"g2\":\"t\"}"},
                        [status(400)])
    ).

% Validasi input: ID harus gejala yang dikenal dan nilai hanya y/t.
jawaban_valid(Kunci-Nilai, G-J) :-
    downcase_atom(Kunci, G),
    gejala(G, _),
    string(Nilai),
    normalisasi_jawaban(Nilai, J).

json_gejala(G, _{id: G, label: Label, deskripsi: Deskripsi}) :-
    gejala(G, Deskripsi),
    upcase_atom(G, Label).

json_hasil(hasil(D, _, Persen, Aturan),
           _{id: D, label: Label, nama: Nama, saran: Saran, keparahan: Keparahan,
             cf_persen: Persen, cf_teks: Teks, aturan: AturanJson}) :-
    upcase_atom(D, Label),
    pisah_diagnosis(D, Nama, Saran),
    keparahan(D, Keparahan),
    teks_persen(Persen, Teks),
    maplist(json_aturan, Aturan, AturanJson).

json_aturan(aturan(R, Premis, CFAturan, CFHasil, Status),
            _{id: R, label: Label, premis: PremisJson, cf_aturan: CFAturan,
              cf_hasil_teks: Teks, status: Status}) :-
    upcase_atom(R, Label),
    maplist(json_gejala, Premis, PremisJson),
    persen(CFHasil, Persen),
    teks_persen(Persen, Teks).

% Test memuat file ini tanpa membuka port 8080.
:- if(\+ current_prolog_flag(blas_tanpa_server, true)).
:- initialization(mulai_server).
:- endif.
