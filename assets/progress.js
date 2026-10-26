// rtrainer progress: versioned JSON in localStorage, shared by all pages.
// Also fills the "Wiederholen (n)" badge and the course plan statuses.
(function () {
  "use strict";

  const L = window.rtLogic;
  const KEY = "rtrainer.progress";
  const VERSION = L.VERSION;
  const empty = L.emptyProgress;

  function load() {
    try {
      const raw = window.localStorage.getItem(KEY);
      if (!raw) return empty();
      const data = JSON.parse(raw);
      if (!data || data.version !== VERSION) return Object.assign(empty(), migrate(data));
      return Object.assign(empty(), data);
    } catch (e) {
      return empty();
    }
  }

  // Later versions convert older data here; v1 is the first format.
  function migrate(data) {
    return data && typeof data === "object" ? data : {};
  }

  function save(data) {
    try {
      window.localStorage.setItem(KEY, JSON.stringify(data));
    } catch (e) {
      // Storage full or blocked: progress stays in memory for this page.
    }
    document.dispatchEvent(new CustomEvent("rt-progress", { detail: data }));
  }

  function update(fn) {
    const data = load();
    fn(data);
    save(data);
    return data;
  }

  const isoDate = L.isoDate;
  const addDays = (days) => L.addDays(L.isoDate(), days);
  const dueIds = (data, ids) => L.dueIds(data, L.isoDate(), ids);
  const lessonStatus = L.lessonStatus;
  const updateCompletion = (data, lesson, requiredIds, allIds, hasQuiz) =>
    L.updateCompletion(data, lesson, requiredIds, allIds, hasQuiz, new Date());

  const TEXT = {
    de: {
      status: { "not-started": "nicht begonnen", started: "begonnen", done: "abgeschlossen" },
      due: (n) => `${n} fällig`,
      dueLabel: (n) => `${n} Übung${n === 1 ? "" : "en"} fällig`,
      today: (n) =>
        `${n} Übung${n === 1 ? " ist" : "en sind"} heute zur Wiederholung fällig.`,
    },
    en: {
      status: { "not-started": "not started", started: "started", done: "completed" },
      due: (n) => `${n} due`,
      dueLabel: (n) => `${n} exercise${n === 1 ? "" : "s"} due`,
      today: (n) => `${n} exercise${n === 1 ? " is" : "s are"} due for review today.`,
    },
  };

  function text() {
    const lang = (document.documentElement.lang || "de").slice(0, 2);
    return TEXT[lang] || TEXT.de;
  }

  function renderNavBadge(data) {
    const link =
      document.querySelector("#rt-nav-review") ||
      document.querySelector('.navbar a.nav-link[href$="review.html"]');
    if (!link) return;
    const n = dueIds(data).length;
    let badge = link.querySelector(".rt-due-badge");
    if (n === 0) {
      if (badge) badge.remove();
      link.removeAttribute("aria-label");
      return;
    }
    if (!badge) {
      badge = document.createElement("span");
      badge.className = "rt-due-badge";
      badge.setAttribute("aria-hidden", "true");
      (link.querySelector(".menu-text") || link).appendChild(badge);
    }
    badge.textContent = String(n);
    const label = (link.querySelector(".menu-text") || link).firstChild.textContent.trim();
    link.setAttribute("aria-label", `${label}, ${text().dueLabel(n)}`);
  }

  function renderCoursePlan(data) {
    const courseEl = document.getElementById("rt-course");
    if (!courseEl) return;
    const course = JSON.parse(courseEl.textContent);
    const t = text();
    document.querySelectorAll(".rt-cell-active[data-lesson]").forEach((cell) => {
      const lesson = cell.dataset.lesson;
      const info = course[lesson] || { required: [], exercises: [] };
      const status = lessonStatus(data, lesson, info.exercises);
      const statusEl = cell.querySelector(".rt-status");
      statusEl.dataset.status = status;
      statusEl.querySelector(".rt-status-text").textContent = t.status[status];
      const due = dueIds(data, info.exercises).length;
      const dueEl = cell.querySelector(".rt-due");
      dueEl.hidden = due === 0;
      dueEl.textContent = due > 0 ? t.due(due) : "";
    });
    const today = document.querySelector(".rt-today");
    if (today) {
      const n = dueIds(data).length;
      today.hidden = n === 0;
      today.querySelector(".rt-today-title").textContent += n > 0 ? ` (${n})` : "";
      today.querySelector(".rt-today-text").textContent = t.today(n);
    }
  }

  // ---- Language: one navbar config (German) for both page trees ----------
  const NAV_EN = {
    Kursplan: "Course plan",
    Wiederholen: "Review",
    Pakete: "Packages",
    Glossar: "Glossary",
    Quellcode: "Source code",
    "rtrainer · R-Kurs für Human Factors und UX": "rtrainer · R course for human factors and UX",
  };

  function pageInfo() {
    const m = window.location.pathname.match(/\/(de|en)\/([^/]*)$/);
    if (!m) return null;
    return { lang: m[1], page: m[2] || "index.html" };
  }

  function localiseNavbar(info) {
    if (info.lang === "en") {
      document.querySelectorAll(".navbar a, .nav-footer a, .nav-footer-left, .nav-footer-left p").forEach((node) => {
        const href = node.getAttribute && node.getAttribute("href");
        if (href && /(^|\/)de\//.test(href)) node.setAttribute("href", href.replace(/(^|\/)de\//, "$1en/"));
      });
      const walker = document.createTreeWalker(document.querySelector("header") || document.body, NodeFilter.SHOW_TEXT);
      const footer = document.querySelector(".nav-footer");
      const nodes = [];
      let node;
      while ((node = walker.nextNode())) nodes.push(node);
      if (footer) {
        const fw = document.createTreeWalker(footer, NodeFilter.SHOW_TEXT);
        while ((node = fw.nextNode())) nodes.push(node);
      }
      nodes.forEach((n) => {
        const key = n.nodeValue.trim();
        if (NAV_EN[key]) n.nodeValue = n.nodeValue.replace(key, NAV_EN[key]);
      });
    }
    // Mark the current page in the navbar (Quarto only knows the German tree).
    document.querySelectorAll(".navbar a.nav-link").forEach((a) => {
      const target = (a.getAttribute("href") || "").split("/").pop();
      if (a.closest("#rt-nav-lang") || a.id === "rt-nav-lang") return;
      if (target === info.page || (info.page === "" && target === "index.html")) {
        a.classList.add("active");
        a.setAttribute("aria-current", "page");
      }
    });
  }

  // DE/EN switch: same page and section in the other language.
  function setupLanguageSwitch(info) {
    const link = document.querySelector("a#rt-nav-lang");
    if (!link) return;
    const other = info.lang === "de" ? "en" : "de";
    const label = link.querySelector(".menu-text") || link;
    label.textContent = other.toUpperCase();
    link.setAttribute("lang", other);
    link.setAttribute("hreflang", other);
    link.setAttribute("aria-label", other === "en" ? "English version of this page" : "Deutsche Fassung dieser Seite");
    const update = () => {
      const section = window.rtCurrentSection ? `#${window.rtCurrentSection}` : window.location.hash;
      link.setAttribute("href", `../${other}/${info.page}${section || ""}`);
    };
    update();
    link.addEventListener("focus", update);
    link.addEventListener("mouseenter", update);
    link.addEventListener("click", update);
  }

  function renderAll() {
    const info = pageInfo();
    // Quarto drops navbar ids; find the language link by its label.
    const langLink = Array.from(document.querySelectorAll(".navbar a.nav-link")).find(
      (a) => a.textContent.trim() === "EN"
    );
    if (langLink) langLink.id = "rt-nav-lang";
    if (info) {
      localiseNavbar(info);
      setupLanguageSwitch(info);
    }
    const data = load();
    renderNavBadge(data);
    renderCoursePlan(data);
  }

  window.rtProgress = { load, save, update, isoDate, addDays, dueIds, lessonStatus, updateCompletion, KEY, VERSION };

  document.addEventListener("rt-progress", (e) => renderNavBadge(e.detail));
  window.addEventListener("storage", (e) => {
    if (e.key === KEY) renderNavBadge(load());
  });
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", renderAll);
  } else {
    renderAll();
  }
})();
