// Hanya tampilan. Seluruh logika diagnosis, CF, derajat, dan saran berada di Prolog.
const $ = (selektor) => document.querySelector(selektor);
const form = $("#form-gejala");
const tombolDiagnosa = form.querySelector("button[type=submit]");
const KELILING_GAUGE = 2 * Math.PI * 62;

const IKON = {
  "Daun": '<path d="M5 19C4 10 10 4 20 4c0 10-6 16-15 15Z"/><path d="M5 19 14 10"/>',
  "Batang/Buku": '<path d="M12 3v18"/><path d="M8 8h8"/><path d="M8 16h8"/><path d="M12 8c3-1 5-3 6-5"/>',
  "Malai": '<path d="M12 22V9"/><path d="M12 9c0-3 1-5 3-6 1 3 0 5-3 6Z"/><path d="M12 14c-3 0-5-2-6-5 3 0 5 2 6 5Z"/><path d="M12 14c3 0 5-2 6-5-3 0-5 2-6 5Z"/><path d="M12 19c-3 0-5-1-6-4 3 0 5 1 6 4Z"/><path d="M12 19c3 0 5-1 6-4-3 0-5 1-6 4Z"/>',
  "Lingkungan & Budidaya": '<path d="M12 3s6 6.2 6 11a6 6 0 0 1-12 0c0-4.8 6-11 6-11Z"/><path d="M9.5 14.5a2.7 2.7 0 0 0 2.5 2.5"/>',
};
const CENTANG = '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="m3 8.5 3.2 3.2L13 4.8"/></svg>';
const KELAS_DERAJAT = {
  "Berat": "derajat-berat",
  "Sedang–Berat": "derajat-sedang-berat",
  "Sedang": "derajat-sedang",
  "Awal": "derajat-awal",
  "Risiko": "derajat-risiko",
  "Rendah": "derajat-rendah",
};

let kelompokGejala = [];

function el(tag, kelas, teks) {
  const node = document.createElement(tag);
  if (kelas) node.className = kelas;
  if (teks !== undefined) node.textContent = teks;
  return node;
}

function animasikanNilai() {
  const target = document.querySelectorAll("[data-animasi]");
  requestAnimationFrame(() => requestAnimationFrame(() => {
    target.forEach((node) => {
      const nilai = Number(node.dataset.animasi);
      if (node.tagName === "circle") node.style.strokeDashoffset = KELILING_GAUGE * (1 - nilai / 100);
      else node.style.width = `${nilai}%`;
      node.removeAttribute("data-animasi");
    });
  }));
}

function tampilkanHalaman() {
  const hash = location.hash.slice(1);
  const id = ["diagnosis", "hasil", "tentang"].includes(hash) ? hash : "diagnosis";
  document.querySelectorAll(".page").forEach((p) => p.classList.toggle("aktif", p.id === id));
  document.querySelectorAll("nav a").forEach((a) => {
    const aktif = a.hash === `#${id}`;
    a.classList.toggle("aktif", aktif);
    if (aktif) a.setAttribute("aria-current", "page");
    else a.removeAttribute("aria-current");
  });
  window.scrollTo(0, 0);
  if (id === "hasil") animasikanNilai();
}

function bukaHasil() {
  if (location.hash === "#hasil") tampilkanHalaman();
  else location.hash = "hasil";
  $("#judul-hasil").focus({ preventScroll: true });
}

function perbaruiPenghitung() {
  const jumlah = form.querySelectorAll('input[value="y"]:checked').length;
  $("#penghitung").textContent = `${jumlah} gejala dipilih`;
  $("#petunjuk").hidden = jumlah > 0;
  tombolDiagnosa.disabled = jumlah === 0;
}

function pilihan(id, nilai, label, terpilih) {
  const wadah = el("label");
  const input = el("input");
  input.type = "radio";
  input.name = id;
  input.value = nilai;
  input.defaultChecked = terpilih;
  wadah.append(input, el("span", "", label));
  return wadah;
}

function barisGejala(g) {
  const baris = el("div", "gejala");
  const teks = el("div", "gejala-teks");
  teks.append(el("b", "", g.label), g.deskripsi);
  const toggle = el("div", "toggle");
  toggle.setAttribute("role", "radiogroup");
  toggle.setAttribute("aria-label", `${g.label}: ${g.deskripsi}`);
  toggle.append(pilihan(g.id, "y", "Ya", false), pilihan(g.id, "t", "Tidak", true));
  baris.append(teks, toggle);
  return baris;
}

function kartuOrgan(k, indeks) {
  const kartu = el("section", "organ");
  const idJudul = `organ-${indeks}`;
  kartu.setAttribute("role", "group");
  kartu.setAttribute("aria-labelledby", idJudul);
  const kepala = el("div", "organ-kepala");
  const ikon = el("span", "organ-ikon");
  ikon.innerHTML = `<svg viewBox="0 0 24 24" aria-hidden="true">${IKON[k.organ] || ""}</svg>`;
  const judul = el("h2", "judul-bagian", k.organ);
  judul.id = idJudul;
  kepala.append(ikon, judul);
  kartu.append(kepala, ...k.gejala.map(barisGejala));
  return kartu;
}

async function muatGejala() {
  const wadah = $("#daftar-gejala");
  try {
    const respons = await fetch("/api/gejala");
    if (!respons.ok) throw new Error();
    const data = await respons.json();
    kelompokGejala = data.kelompok;
    wadah.replaceChildren(...kelompokGejala.map(kartuOrgan));
  } catch {
    wadah.replaceChildren(el("p", "kartu error", "Gagal memuat gejala. Pastikan server Prolog berjalan."));
  }
}

function badgeDerajat(d) {
  return el("span", `badge ${KELAS_DERAJAT[d.derajat] || "derajat-rendah"}`, d.teks_derajat);
}

function gauge(d) {
  const wadah = el("div", "gauge");
  wadah.setAttribute("role", "img");
  wadah.setAttribute("aria-label", `Keyakinan sistem ${d.cf_teks}`);
  wadah.innerHTML = '<svg viewBox="0 0 148 148" aria-hidden="true"><circle class="gauge-jalur" cx="74" cy="74" r="62"/><circle class="gauge-isi" cx="74" cy="74" r="62"/></svg>';
  const isi = wadah.querySelector(".gauge-isi");
  isi.style.strokeDasharray = KELILING_GAUGE;
  isi.style.strokeDashoffset = KELILING_GAUGE;
  isi.dataset.animasi = d.cf_persen;
  const teks = el("div", "gauge-teks");
  teks.append(el("strong", "", d.cf_teks), el("span", "", "keyakinan"));
  wadah.append(teks);
  return wadah;
}

function barisAturan(a, d) {
  const dihitung = a.status === "dihitung";
  const item = el("li", dihitung ? "aturan dihitung" : "aturan");
  const baris = el("div", "aturan-baris");
  baris.append(el("b", "", a.label), el("span", "kata", "IF"));
  a.premis.forEach((p, i) => {
    if (i) baris.append(el("span", "kata", "AND"));
    const gejala = el("span", "premis");
    gejala.title = `${p.label}: ${p.deskripsi} (terpenuhi)`;
    gejala.innerHTML = CENTANG;
    gejala.append(p.label);
    baris.append(gejala);
  });
  baris.append(el("span", "kata", "THEN"), el("b", "", d.label), el("span", "", `(CF ${a.cf_aturan.toFixed(2)})`));
  const status = dihitung
    ? "Dihitung untuk keyakinan"
    : "Tidak dihitung: berbagi gejala dengan aturan yang dipilih";
  item.append(baris, el("span", "aturan-status", status));
  return item;
}

function daftarAturan(d) {
  const daftar = el("ul", "aturan-daftar");
  daftar.append(...d.aturan.map((a) => barisAturan(a, d)));
  return daftar;
}

function ringkasan(d, jumlah, catatan) {
  const kartu = el("section", "ringkasan");
  const teks = el("div", "ringkasan-teks");
  teks.append(
    el("p", "eyebrow", `Diagnosis utama · ${d.label}`),
    el("h2", "", d.nama),
    badgeDerajat(d),
    el("p", "kesimpulan", `Berdasarkan ${jumlah} gejala yang dipilih, sistem menempatkan ${d.nama} sebagai diagnosis utama dengan keyakinan ${d.cf_teks} dan derajat ${d.derajat}.`),
  );
  if (d.sumber) teks.append(el("p", "kecil", `${d.sumber}.`));
  teks.append(el("p", "kecil", catatan));
  kartu.append(gauge(d), teks);
  return kartu;
}

function kartuLain(d) {
  const kartu = el("article", "kartu kartu-lain");
  const kepala = el("div", "lain-kepala");
  kepala.append(el("h3", "", `${d.label}: ${d.nama}`), el("strong", "", d.cf_teks));
  const meter = el("div", "meter");
  meter.setAttribute("role", "progressbar");
  meter.setAttribute("aria-valuemin", "0");
  meter.setAttribute("aria-valuemax", "100");
  meter.setAttribute("aria-valuenow", d.cf_persen);
  meter.setAttribute("aria-label", `Keyakinan ${d.nama}`);
  const isi = el("span");
  isi.dataset.animasi = d.cf_persen;
  meter.append(isi);
  const detail = el("details");
  detail.append(el("summary", "", "Saran dan alasan"), el("p", "", d.saran));
  if (d.sumber) detail.append(el("p", "kecil", `${d.sumber}.`));
  detail.append(daftarAturan(d));
  kartu.append(kepala, badgeDerajat(d), meter, detail);
  return kartu;
}

function kartuGejalaDipilih(dipilih) {
  const kartu = el("section", "kartu");
  kartu.append(el("h2", "judul-bagian", "Gejala yang Anda pilih"));
  kelompokGejala.forEach((k) => {
    const terpilih = k.gejala.filter((g) => dipilih.has(g.id));
    if (!terpilih.length) return;
    const blok = el("div", "pilihan-organ");
    const daftar = el("ul", "daftar");
    terpilih.forEach((g) => {
      const li = el("li");
      li.append(el("b", "", `${g.label} `), g.deskripsi);
      daftar.append(li);
    });
    blok.append(el("h3", "", k.organ), daftar);
    kartu.append(blok);
  });
  return kartu;
}

function tampilkanHasil(data, dipilih) {
  const wadah = $("#isi-hasil");
  $("#aksi-hasil").hidden = false;
  if (!data.diagnosis.length) {
    const pesan = el("section", "ringkasan");
    pesan.append(el("h2", "", data.pesan));
    wadah.replaceChildren(pesan, kartuGejalaDipilih(dipilih));
    return;
  }

  const [utama, ...lain] = data.diagnosis;
  const kiri = el("div", "kolom");
  const saran = el("section", "kartu kartu-saran");
  saran.append(el("h2", "judul-bagian", "Saran tindakan"), el("p", "", utama.saran));
  const kartuMengapa = el("section", "kartu kartu-mengapa");
  const mengapa = el("details", "mengapa");
  mengapa.open = true;
  mengapa.append(el("summary", "", "Mengapa?"), daftarAturan(utama));
  kartuMengapa.append(mengapa);
  kiri.append(saran, kartuMengapa);
  if (lain.length) {
    const blokLain = el("section", "lain-daftar");
    blokLain.append(el("h2", "judul-bagian", "Diagnosis lain"), ...lain.map(kartuLain));
    kiri.append(blokLain);
  }

  const kanan = el("aside", "kolom");
  kanan.append(kartuGejalaDipilih(dipilih));
  if (data.faktor_risiko.length) {
    const faktor = el("section", "kartu");
    const daftar = el("ul", "daftar");
    data.faktor_risiko.forEach((f) => {
      const li = el("li");
      li.append(el("b", "", `${f.label} `), f.deskripsi);
      daftar.append(li);
    });
    faktor.append(el("h2", "judul-bagian", "Faktor risiko pendukung"), daftar);
    kanan.append(faktor);
  }
  kanan.append(el("p", "note", "Nilai CF, derajat, dan saran masih draf. Konfirmasi hasil dengan PPL/POPT."));

  const grid = el("div", "hasil-grid");
  grid.append(kiri, kanan);
  wadah.replaceChildren(ringkasan(utama, dipilih.size, data.catatan), grid);
}

form.addEventListener("change", perbaruiPenghitung);
form.addEventListener("reset", () => setTimeout(perbaruiPenghitung));

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const jawaban = Object.fromEntries(new FormData(form));
  const dipilih = new Set(Object.keys(jawaban).filter((id) => jawaban[id] === "y"));
  if (!dipilih.size) return;
  const galat = $("#galat");
  galat.hidden = true;
  tombolDiagnosa.disabled = true;
  tombolDiagnosa.textContent = "Mendiagnosa…";
  try {
    const respons = await fetch("/api/diagnosa", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(jawaban),
    });
    if (!respons.ok) throw new Error();
    tampilkanHasil(await respons.json(), dipilih);
    bukaHasil();
  } catch {
    galat.textContent = "Diagnosis gagal. Pastikan server Prolog berjalan.";
    galat.hidden = false;
  } finally {
    tombolDiagnosa.textContent = "Diagnosa";
    perbaruiPenghitung();
  }
});

$("#tombol-ulang").addEventListener("click", () => {
  form.reset();
  location.hash = "diagnosis";
});
$("#tombol-cetak").addEventListener("click", () => window.print());

// Panel tertutup ikut tercetak, lalu kembali ke keadaan semula.
let panelTertutup = [];
window.addEventListener("beforeprint", () => {
  panelTertutup = [...document.querySelectorAll("#hasil details:not([open])")];
  panelTertutup.forEach((d) => { d.open = true; });
});
window.addEventListener("afterprint", () => {
  panelTertutup.forEach((d) => { d.open = false; });
  panelTertutup = [];
});

window.addEventListener("hashchange", tampilkanHalaman);
tampilkanHalaman();
muatGejala();
