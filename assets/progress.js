// rtrainer progress: versioned JSON in localStorage, shared by all pages.
// Also fills the "Wiederholen (n)" badge and the course plan statuses.
(function () {
  "use strict";

  const KEY = "rtrainer.progress";
  const VERSION = 1;
  const DAY_MS = 24 * 60 * 60 * 1000;

  function empty() {
    return { version: VERSION, exercises: {}, quizzes: {}, lessons: {}, sections: {}, review: {} };
  }

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

  function isoDate(date) {
    const d = date || new Date();
    const pad = (n) => String(n).padStart(2, "0");
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  }

  function addDays(days) {
    return isoDate(new Date(Date.now() + days * DAY_MS));
  }

  function dueIds(data, ids) {
    const today = isoDate();
    return Object.keys(data.review).filter(
      (id) => data.review[id].due <= today && (!ids || ids.includes(id))
    );
  }

  // Lesson status: "done", "started" or "not-started".
  function lessonStatus(data, lesson, exerciseIds) {
    if (data.lessons[lesson] && data.lessons[lesson].completedAt) return "done";
    const touched =
      (data.lessons[lesson] && data.lessons[lesson].startedAt) ||
      data.quizzes[lesson] ||
      (exerciseIds || []).some((id) => data.exercises[id]);
    return touched ? "started" : "not-started";
  }

  // Completed = all required exercises solved + knowledge check passed.
  // Then the lesson's exercises enter review box 1, due the next day.
  function updateCompletion(data, lesson, requiredIds, allIds, hasQuiz) {
    const entry = data.lessons[lesson] || (data.lessons[lesson] = {});
    if (entry.completedAt) return false;
    const solved = requiredIds.every((id) => data.exercises[id] && data.exercises[id].solved);
    const quizOk = !hasQuiz || (data.quizzes[lesson] && data.quizzes[lesson].passed);
    if (!(solved && quizOk)) return false;
    entry.completedAt = new Date().toISOString();
    (allIds || requiredIds).forEach((id) => {
      if (!data.review[id]) data.review[id] = { box: 1, due: addDays(1) };
    });
    return true;
  }

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

  function renderAll() {
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
