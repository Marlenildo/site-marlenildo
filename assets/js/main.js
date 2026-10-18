document.getElementById("year").textContent = new Date().getFullYear();

// Tema claro/escuro: segue o sistema até a pessoa escolher no botão do topo (como nos apps)
const themeToggle = document.getElementById("themeToggle");
if (themeToggle) {
  const CHAVE_TEMA = "marlenildo:tema";
  const SOL = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>';
  const LUA = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><path d="M20.5 14.5A8.5 8.5 0 0 1 9.5 3.5a8.5 8.5 0 1 0 11 11z"/></svg>';
  const sistemaClaro = matchMedia("(prefers-color-scheme: light)");
  let tema = "auto";
  try { tema = localStorage.getItem(CHAVE_TEMA) || "auto"; } catch (e) { /* sem armazenamento */ }
  const escuro = () => tema === "dark" || (tema === "auto" && !sistemaClaro.matches);
  const aplicarTema = () => {
    if (tema === "auto") document.documentElement.removeAttribute("data-theme");
    else document.documentElement.setAttribute("data-theme", tema);
    themeToggle.innerHTML = escuro() ? SOL : LUA;
    themeToggle.title = escuro() ? "Usar tema claro" : "Usar tema escuro";
    themeToggle.setAttribute("aria-label", themeToggle.title);
  };
  themeToggle.addEventListener("click", () => {
    tema = escuro() ? "light" : "dark";
    try { localStorage.setItem(CHAVE_TEMA, tema); } catch (e) { /* sem armazenamento */ }
    aplicarTema();
  });
  if (sistemaClaro.addEventListener) sistemaClaro.addEventListener("change", aplicarTema);
  aplicarTema();
}

const navToggle = document.getElementById("navToggle");
const navLinks = document.getElementById("navLinks");

navToggle.addEventListener("click", () => {
  const isOpen = navLinks.classList.toggle("is-open");
  navToggle.setAttribute("aria-expanded", String(isOpen));
});

navLinks.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", () => {
    navLinks.classList.remove("is-open");
    navToggle.setAttribute("aria-expanded", "false");
  });
});

const lightbox = document.getElementById("lightbox");
if (lightbox) {
  const lightboxImg = document.getElementById("lightboxImg");
  const lightboxClose = document.getElementById("lightboxClose");
  const lightboxCaption = document.getElementById("lightboxCaption");

  const openLightbox = (src, alt, captionHTML) => {
    lightboxImg.src = src;
    lightboxImg.alt = alt || "";
    lightboxCaption.innerHTML = captionHTML || "";
    lightbox.classList.add("is-open");
    lightbox.setAttribute("aria-hidden", "false");
  };

  const closeLightbox = () => {
    lightbox.classList.remove("is-open");
    lightbox.setAttribute("aria-hidden", "true");
  };

  document.querySelectorAll(".example-card img").forEach((img) => {
    img.addEventListener("click", () => {
      const figcaption = img.closest("figure")?.querySelector("figcaption");
      openLightbox(img.src, img.alt, figcaption ? figcaption.innerHTML : "");
    });
  });

  lightbox.addEventListener("click", (e) => {
    if (e.target === lightbox) closeLightbox();
  });
  lightboxClose.addEventListener("click", closeLightbox);
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeLightbox();
  });
}

const revealTargets = document.querySelectorAll(".app-card");

if ("IntersectionObserver" in window) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15 }
  );
  revealTargets.forEach((el) => observer.observe(el));
} else {
  revealTargets.forEach((el) => el.classList.add("is-visible"));
}

/* ---------- Realce de sintaxe do R nos blocos de código ---------- */
(() => {
  const KEYWORDS = new Set([
    "function", "if", "else", "for", "while", "repeat", "in", "next", "break", "return",
    "TRUE", "FALSE", "NULL", "NA", "NaN", "Inf", "NA_real_", "NA_integer_", "NA_character_",
  ]);
  const TOKEN = new RegExp([
    "(#[^\\n]*)",                                   // 1 comentário
    "(\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*')", // 2 texto
    "(\\b\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?L?\\b)",   // 3 número
    "(<-|->|\\|>|%[^%\\s]*%|::|==|!=|<=|>=|&&|\\|\\||[~$^@]|\\\\(?=\\())", // 4 operador
    "([A-Za-z.][A-Za-z0-9._]*)",                    // 5 identificador
  ].join("|"), "g");

  const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const span = (cls, s) => `<span class="tok-${cls}">${esc(s)}</span>`;

  const highlightR = (src) => {
    let out = "";
    let last = 0;
    let depth = 0;
    let m;
    TOKEN.lastIndex = 0;
    while ((m = TOKEN.exec(src))) {
      const between = src.slice(last, m.index);
      for (const ch of between) {
        if (ch === "(") depth++;
        else if (ch === ")") depth = Math.max(0, depth - 1);
      }
      out += esc(between);
      const [tok, com, str, num, op, id] = m;
      const rest = src.slice(TOKEN.lastIndex);
      if (com) out += span("com", tok);
      else if (str) out += span("str", tok);
      else if (num) out += span("num", tok);
      else if (op) out += span(op === "\\" ? "kw" : "op", tok);
      else if (id) {
        if (KEYWORDS.has(id)) out += span("kw", tok);
        else if (rest.startsWith("::")) out += span("ns", tok);
        else if (rest.startsWith("(")) out += span("fn", tok);
        else if (depth > 0 && /^\s*=(?!=)/.test(rest)) out += span("arg", tok);
        else out += esc(tok);
      }
      last = TOKEN.lastIndex;
    }
    return out + esc(src.slice(last));
  };

  // Saída do console: realça só as linhas de comando ("> ...") e os asteriscos
  const highlightOutput = (src) =>
    src.split("\n").map((line) => {
      if (line.startsWith("> ")) return span("prompt", "> ") + highlightR(line.slice(2));
      return esc(line).replace(/(\*{1,3})(\s*)$/, '<span class="tok-num">$1</span>$2');
    }).join("\n");

  document.querySelectorAll("pre.code-block > code").forEach((code) => {
    const pre = code.parentElement;
    const src = code.textContent;
    code.innerHTML = pre.dataset.lang === "output" ? highlightOutput(src) : highlightR(src);
  });
})();
