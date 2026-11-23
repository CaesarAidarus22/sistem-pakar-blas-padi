// Hanya tampilan. Seluruh logika diagnosis dan CF berada di Prolog.
const $ = (selektor) => document.querySelector(selektor);

function el(tag, kelas, teks) {
  const node = document.createElement(tag);
  if (kelas) node.className = kelas;
  if (teks !== undefined) node.textContent = teks;
  return node;
}

function tampilkanHalaman() {
  const id = ["diagnosis", "hasil", "tentang"].includes(location.hash.slice(1))
    ? location.hash.slice(1)
    : "diagnosis";
  document.querySelectorAll(".page").forEach((p) => p.classList.toggle("aktif", p.id === id));
  document.querySelectorAll("nav a").forEach((a) => {
    const aktif = a.hash === `#${id}`;
    a.classList.toggle("aktif", aktif);
    if (aktif) a.setAttribute("aria-current", "page");
    else a.removeAttribute("aria-current");
  });
  window.scrollTo(0, 0);
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
  const teks = el("div");
  teks.append(el("b", "", g.label), g.deskripsi);
  const toggle = el("div", "toggle");
  toggle.setAttribute("role", "radiogroup");
  toggle.setAttribute("aria-label", `${g.label}: ${g.deskripsi}`);
  toggle.append(pilihan(g.id, "y", "Ya", false), pilihan(g.id, "t", "Tidak", true));
  baris.append(teks, toggle);
  return baris;
}

async function muatGejala() {
  const wadah = $("#daftar-gejala");
  try {
    const respons = await fetch("/api/gejala");
    if (!respons.ok) throw new Error();
    const data = await respons.json();
    wadah.replaceChildren(...data.kelompok.map((k) => {
      const set = el("fieldset", "organ");
      set.append(el("legend", "", k.organ), ...k.gejala.map(barisGejala));
      return set;
    }));
  } catch {
    wadah.replaceChildren(el("p", "error", "Gagal memuat gejala. Pastikan server Prolog berjalan."));
  }
}

function kartuAturan(aturan) {
  const detail = el("details");
  detail.append(el("summary", "", "Mengapa?"));
  const daftar = el("ul");
  aturan.forEach((a) => {
    const premis = a.premis.map((p) => `${p.label} (${p.deskripsi})`).join(" DAN ");
    const status = a.status === "dihitung" ? "dihitung" : "tidak dihitung, kalah dalam rantai subset";
    daftar.append(el("li", a.status === "dihitung" ? "" : "diabaikan",
      `${a.label}: JIKA ${premis}. CF aturan ${a.cf_aturan.toFixed(2)}, hasil ${a.cf_hasil_teks}, ${status}.`));
  });
  detail.append(daftar);
  return detail;
}

function kartuDiagnosis(d, utama) {
  const kartu = el("article", utama ? "kartu utama" : "kartu");
  const judul = el("div", "judul-hasil");
  judul.append(el(utama ? "h2" : "h3", "", `${d.label}: ${d.nama}`), el("span", "angka", d.cf_teks));
  const meta = el("p", "meta");
  meta.append(el("span", "keparahan", `Keparahan: ${d.keparahan}`), el("span", "", `Keyakinan sistem: ${d.cf_teks}`));
  const bar = el("progress");
  bar.max = 100;
  bar.value = d.cf_persen;
  bar.setAttribute("aria-label", `Tingkat keyakinan ${d.cf_teks}`);
  const saran = el("p");
  saran.append(el("strong", "", "Saran tindakan: "), d.saran);
  kartu.append(judul, meta, bar, saran, kartuAturan(d.aturan));
  return kartu;
}

function tampilkanHasil(data) {
  const wadah = $("#isi-hasil");
  if (!data.diagnosis.length) {
    wadah.replaceChildren(el("p", "kartu", data.pesan));
    return;
  }
  const [utama, ...lain] = data.diagnosis;
  const isi = [kartuDiagnosis(utama, true)];
  if (data.faktor_risiko.length) {
    const kartu = el("div", "kartu");
    const daftar = el("ul");
    data.faktor_risiko.forEach((f) => daftar.append(el("li", "", `${f.label}: ${f.deskripsi}`)));
    kartu.append(el("h3", "", "Faktor risiko pendukung"), daftar);
    isi.push(kartu);
  }
  if (lain.length) {
    isi.push(el("h2", "", "Diagnosis lain"), ...lain.map((d) => kartuDiagnosis(d, false)));
  }
  isi.push(el("p", "note", `${data.catatan} Nilai CF masih draf. Konfirmasi hasil dengan PPL/POPT.`));
  wadah.replaceChildren(...isi);
}

$("#form-gejala").addEventListener("submit", async (e) => {
  e.preventDefault();
  const galat = $("#galat");
  const tombol = e.target.querySelector("button[type=submit]");
  galat.hidden = true;
  tombol.disabled = true;
  try {
    const respons = await fetch("/api/diagnosa", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(Object.fromEntries(new FormData(e.target))),
    });
    if (!respons.ok) throw new Error();
    tampilkanHasil(await respons.json());
    location.hash = "hasil";
  } catch {
    galat.textContent = "Diagnosis gagal. Pastikan server Prolog berjalan.";
    galat.hidden = false;
  } finally {
    tombol.disabled = false;
  }
});

window.addEventListener("hashchange", tampilkanHalaman);
tampilkanHalaman();
muatGejala();
