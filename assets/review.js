// rtrainer review page: Leitner repetition of exercises from completed
// lessons, confidence rating before checking, streak, progress backup.
// R runs in webR, loaded only when a review session starts.
(function () {
  "use strict";

  const root = document.getElementById("rt-review");
  const P = window.rtProgress;
  if (!root || !P) return;

  const WEBR_URL = "https://webr.r-wasm.org/v0.6.0/webr.mjs";
  const lang = (document.documentElement.lang || "de").slice(0, 2) === "en" ? "en" : "de";

  const TEXT = {
    de: {
      dueToday: (n) => (n === 1 ? "1 Übung ist heute fällig." : `${n} Übungen sind heute fällig.`),
      nothingDue: "Heute ist nichts fällig.",
      nextDue: (date, n) => `Nächste Wiederholung: ${date} (${n} ${n === 1 ? "Übung" : "Übungen"}).`,
      noItems:
        "Noch keine Übungen in der Wiederholung. Sobald du eine Lektion abschließt (Pflichtübungen gelöst, Wissenscheck ≥ 80 %), kommen ihre Übungen hierher.",
      toPlan: "Zum Kursplan",
      start: (n) => `Wiederholung starten (${n})`,
      streak: (n) => (n === 1 ? "Serie: 1 Tag" : `Serie: ${n} Tage`),
      boxes: "Deine Übungen in den Boxen",
      boxCaption: "Box 1 kommt bald wieder, Box 5 ist gefestigt.",
      boxLabel: (b, n) => `Box ${b}: ${n} ${n === 1 ? "Übung" : "Übungen"}`,
      streakLabel: "Serie",
      loading: "R wird geladen …",
      loadingPkgs: (p) => `Pakete werden geladen: ${p} …`,
      loadingFailed: (m) => `R konnte nicht geladen werden: ${m}. Prüfe die Internetverbindung und lade die Seite neu.`,
      cardOf: (i, n) => `Karte ${i} von ${n}`,
      from: "Aus der Lektion",
      openLesson: "Lektion öffnen",
      confidence: "Wie sicher bist du, dass du die Aufgabe lösen kannst?",
      confidenceHelp: "Wähle vor dem Prüfen. Das hilft dir, deine Einschätzung zu kalibrieren.",
      conf: ["unsicher", "eher sicher", "sicher"],
      code: "Dein Code",
      codeHelp: "Strg+Enter prüft. Tab rückt ein.",
      check: "Prüfen",
      checking: "Wird geprüft …",
      hint: (i, n) => `Hinweis ${i} von ${n}`,
      showHint: "Hinweis zeigen",
      showSolution: "Lösung zeigen",
      solution: "Lösung",
      explanation: "Erklärung",
      misconception: "Typische Fehlvorstellung",
      needConfidence: "Wähle zuerst, wie sicher du bist.",
      gaps: "Ersetze zuerst die Lücken ______ durch Code.",
      output: "Ausgabe",
      confidentError:
        "Du warst dir sicher, aber das Ergebnis stimmt noch nicht. Genau solche Fehler lohnen einen zweiten Blick:",
      rate: "Wie schwer war es?",
      easy: "Leicht",
      ok: "Okay",
      hard: "Schwer",
      easyLocked: "„Leicht“ gibt es nur mit weniger als 2 Hinweisen.",
      next: "Weiter",
      wrongNext: "Weiter (zählt als nicht gelöst)",
      scheduled: (box, date) => `Gespeichert: Box ${box}, wieder fällig: ${date}.`,
      today: "heute",
      again: "Diese Karte kommt am Ende der Runde noch einmal.",
      pause: "Pause – später weitermachen",
      done: (r, n) => `Runde beendet: ${r} von ${n} Karten gelöst.`,
      doneHint: "Bearbeitete Karten sind gespeichert. Nicht bearbeitete bleiben fällig.",
      error: "Fehler",
      backupTitle: "Fortschritt sichern",
      backupText:
        "Dein Fortschritt liegt nur in diesem Browser. Sichere ihn als Datei, um ihn auf ein anderes Gerät zu übertragen oder nach dem Löschen der Browserdaten wiederherzustellen.",
      export: "Als Datei speichern",
      importLabel: "Datei laden",
      importConfirm: (now, file) =>
        `Die Datei ersetzt deinen aktuellen Fortschritt (${now} Übungen) durch ${file} Übungen. Fortfahren?`,
      importDo: "Ersetzen",
      cancel: "Abbrechen",
      importDone: "Fortschritt geladen.",
      importBad: "Die Datei ist kein rtrainer-Fortschritt (oder eine neuere Version).",
    },
    en: {
      dueToday: (n) => (n === 1 ? "1 exercise is due today." : `${n} exercises are due today.`),
      nothingDue: "Nothing is due today.",
      nextDue: (date, n) => `Next review: ${date} (${n} ${n === 1 ? "exercise" : "exercises"}).`,
      noItems:
        "No exercises in review yet. As soon as you complete a lesson (required exercises solved, knowledge check ≥ 80%), its exercises come here.",
      toPlan: "Go to course plan",
      start: (n) => `Start review (${n})`,
      streak: (n) => (n === 1 ? "Streak: 1 day" : `Streak: ${n} days`),
      boxes: "Your exercises in the boxes",
      boxCaption: "Box 1 comes back soon, box 5 is well learned.",
      boxLabel: (b, n) => `Box ${b}: ${n} ${n === 1 ? "exercise" : "exercises"}`,
      streakLabel: "Streak",
      loading: "Loading R …",
      loadingPkgs: (p) => `Loading packages: ${p} …`,
      loadingFailed: (m) => `R could not be loaded: ${m}. Check your connection and reload the page.`,
      cardOf: (i, n) => `Card ${i} of ${n}`,
      from: "From the lesson",
      openLesson: "Open lesson",
      confidence: "How sure are you that you can solve this?",
      confidenceHelp: "Choose before checking. It helps you calibrate your judgement.",
      conf: ["unsure", "fairly sure", "sure"],
      code: "Your code",
      codeHelp: "Ctrl+Enter checks. Tab indents.",
      check: "Check",
      checking: "Checking …",
      hint: (i, n) => `Hint ${i} of ${n}`,
      showHint: "Show hint",
      showSolution: "Show solution",
      solution: "Solution",
      explanation: "Explanation",
      misconception: "Common misconception",
      needConfidence: "First choose how sure you are.",
      gaps: "First replace the gaps ______ with code.",
      output: "Output",
      confidentError: "You were sure, but the result is not right yet. Errors like this are worth a second look:",
      rate: "How hard was it?",
      easy: "Easy",
      ok: "Okay",
      hard: "Hard",
      easyLocked: "“Easy” is only available with fewer than 2 hints.",
      next: "Next",
      wrongNext: "Next (counts as not solved)",
      scheduled: (box, date) => `Saved: box ${box}, due again: ${date}.`,
      today: "today",
      again: "This card comes back once more at the end of the round.",
      pause: "Pause – continue later",
      done: (r, n) => `Round finished: ${r} of ${n} cards solved.`,
      doneHint: "Answered cards are saved. Unanswered ones stay due.",
      error: "Error",
      backupTitle: "Back up progress",
      backupText:
        "Your progress lives only in this browser. Save it as a file to move it to another device or to restore it after clearing browser data.",
      export: "Save as file",
      importLabel: "Load file",
      importConfirm: (now, file) =>
        `The file replaces your current progress (${now} exercises) with ${file} exercises. Continue?`,
      importDo: "Replace",
      cancel: "Cancel",
      importDone: "Progress loaded.",
      importBad: "The file is not rtrainer progress (or a newer version).",
    },
  };
  const t = TEXT[lang];

  const L = window.rtLogic;
  const schedule = (data, id, result, meta) => L.schedule(data, id, result, meta, P.isoDate());
  const dueQueue = (data, cards) => L.dueQueue(data, cards, P.isoDate());
  const currentStreak = (data) => L.currentStreak(data, P.isoDate());

  // ---- Helpers ---------------------------------------------------------------
  function el(tag, attrs, ...children) {
    const node = document.createElement(tag);
    Object.entries(attrs || {}).forEach(([k, v]) => {
      if (v === null || v === undefined || v === false) return;
      if (k === "class") node.className = v;
      else if (k === "html") node.innerHTML = v;
      else if (k.startsWith("on")) node.addEventListener(k.slice(2), v);
      else node.setAttribute(k, v === true ? "" : v);
    });
    children.flat().forEach((c) => c !== null && c !== undefined && node.append(c));
    return node;
  }

  function formatDate(iso) {
    if (iso <= P.isoDate()) return t.today;
    const [y, m, d] = iso.split("-").map(Number);
    return new Date(y, m - 1, d).toLocaleDateString(lang === "de" ? "de-DE" : "en-GB", {
      weekday: "short", day: "numeric", month: "short",
    });
  }

  // ---- State -----------------------------------------------------------------
  let course = null; // review-cards.json
  let webR = null;
  const installed = new Set();
  const dataWritten = new Set();
  const statusEl = root.querySelector(".rt-review-status");
  const stage = root.querySelector(".rt-review-stage");

  async function loadCards() {
    const res = await fetch("../assets/review-cards.json");
    course = await res.json();
  }

  async function ensureR(card, announce) {
    if (!webR) {
      announce(t.loading);
      const { WebR } = await import(WEBR_URL);
      webR = new WebR();
      await webR.init();
      await webR.evalRVoid(course.checks);
      await webR.evalRVoid(R_RUNNER);
    }
    const missing = card.packages.filter((p) => !installed.has(p));
    if (missing.length) {
      announce(t.loadingPkgs(missing.join(", ")));
      await webR.evalRVoid("webr::install(pkgs, quiet = TRUE)", { env: { pkgs: missing } });
      missing.forEach((p) => installed.add(p));
    }
    for (const name of card.data) {
      if (dataWritten.has(name)) continue;
      const file = course.datasets[name].file;
      const bytes = new Uint8Array(await (await fetch(`../data/${file}`)).arrayBuffer());
      try {
        await webR.FS.mkdir("data");
      } catch (e) {
        // exists already
      }
      await webR.FS.writeFile(`data/${file}`, bytes);
      dataWritten.add(name);
    }
  }

  // Runs setup, solution and the attempt like quarto-live and returns
  // c(correct, message, output, error) as strings.
  const R_RUNNER = `
rt_review_run <- function(setup, solution, user_code, check_code) {
  prep <- new.env(parent = globalenv())
  suppressMessages(eval(parse(text = setup), envir = prep))
  sol_env <- new.env(parent = prep)
  sol <- suppressMessages(withVisible(eval(parse(text = solution), envir = sol_env))$value)
  user_env <- new.env(parent = prep)
  value <- NULL
  err <- ""
  output <- utils::capture.output({
    res <- tryCatch(
      withVisible(eval(parse(text = user_code), envir = user_env)),
      error = function(e) {
        err <<- conditionMessage(e)
        NULL
      }
    )
    if (!is.null(res)) {
      value <- res$value
      if (res$visible) print(res$value)
    }
  })
  feedback <- if (nzchar(err)) {
    list(correct = FALSE, message = "")
  } else {
    rt_checker("review", user_code, check_code, user_env, value, solution = sol, envir_solution = sol_env)
  }
  c(
    tolower(isTRUE(feedback$correct)),
    paste(as.character(feedback$message), collapse = " "),
    paste(output, collapse = "\\n"),
    err
  )
}`;

  async function runAttempt(card, code) {
    const res = await webR.evalR(
      "rt_review_run(setup, solution, user_code, check_code)",
      { env: { setup: card.setup, solution: card.solution, user_code: code, check_code: card.check[lang] } }
    );
    const [correct, message, output, error] = await res.toArray();
    return { correct: correct === "true", message, output, error };
  }

  // ---- Overview --------------------------------------------------------------
  function renderOverview() {
    const data = P.load();
    const cards = course.cards;
    const ids = Object.keys(data.review).filter((id) => cards[id]);
    const queue = dueQueue(data, cards);
    stage.replaceChildren();

    const summary = el("div", { class: "rt-review-summary" });
    if (ids.length === 0) {
      summary.append(el("p", {}, t.noItems), el("a", { class: "btn btn-outline-primary", href: "index.html" }, t.toPlan));
    } else if (queue.length === 0) {
      const upcoming = ids.map((id) => data.review[id].due).sort();
      const next = upcoming[0];
      const n = upcoming.filter((d) => d === next).length;
      summary.append(el("p", { class: "rt-review-lead" }, t.nothingDue), el("p", {}, t.nextDue(formatDate(next), n)));
    } else {
      summary.append(
        el("p", { class: "rt-review-lead" }, t.dueToday(queue.length)),
        el("button", { type: "button", class: "btn btn-primary rt-review-start", onclick: () => startSession(queue) }, t.start(queue.length))
      );
    }
    stage.append(summary);

    if (ids.length > 0) {
      const counts = [1, 2, 3, 4, 5].map((b) => ids.filter((id) => data.review[id].box === b).length);
      const meta = el("dl", { class: "rt-review-meta" });
      if (currentStreak(data) > 0) {
        meta.append(el("div", {}, el("dt", { class: "visually-hidden" }, t.streakLabel), el("dd", {}, t.streak(currentStreak(data)))));
      }
      meta.append(
        el("div", {},
          el("dt", {}, t.boxes),
          el("dd", {},
            el("ol", { class: "rt-boxes" },
              counts.map((n, i) => el("li", { "data-box": i + 1 },
                el("span", { class: "visually-hidden" }, t.boxLabel(i + 1, n)),
                el("span", { class: "rt-box-n", "aria-hidden": "true" }, String(n)),
                el("span", { class: "rt-box-label", "aria-hidden": "true" }, `Box ${i + 1}`)))),
            el("p", { class: "rt-help" }, t.boxCaption)))
      );
      stage.append(meta);
    }
  }

  // ---- Session ---------------------------------------------------------------
  let session = null;

  function startSession(queue) {
    session = { queue: queue.slice(), index: 0, solved: 0, answered: 0, requeued: new Set() };
    showCard();
  }

  function finishSession() {
    const summary = el("div", { class: "rt-review-summary rt-review-done", tabindex: "-1" },
      el("p", { class: "rt-review-lead" }, t.done(session.solved, session.answered)),
      el("p", {}, t.doneHint));
    session = null;
    renderOverview();
    stage.prepend(summary);
    summary.focus();
  }

  function showCard() {
    if (session.index >= session.queue.length) {
      finishSession();
      return;
    }
    const id = session.queue[session.index];
    const card = course.cards[id];
    const state = { hints: 0, confidence: null, attempts: 0, firstWrong: false, solvedShown: false, done: false };

    const announce = (msg) => {
      statusEl.textContent = msg;
    };

    const heading = el("h2", { class: "rt-card-title", tabindex: "-1" }, card.title[lang]);
    const position = el("p", { class: "rt-card-position" }, t.cardOf(session.index + 1, session.queue.length));
    const source = el("p", { class: "rt-card-source" },
      `${t.from}: `,
      el("a", { href: `${card.lesson}.html` }, card.lesson_title[lang]),
      " · ",
      el("span", { class: "rt-tag" }, card.kind_label[lang]));

    // Confidence (1-3) before checking.
    const confName = `rt-conf-${id}`;
    const confidence = el("fieldset", { class: "rt-confidence" },
      el("legend", {}, t.confidence),
      el("p", { class: "rt-help" }, t.confidenceHelp),
      el("div", { class: "rt-confidence-options" },
        t.conf.map((label, i) => {
          const inputId = `${confName}-${i + 1}`;
          return el("span", { class: "rt-confidence-option" },
            el("input", { type: "radio", name: confName, id: inputId, value: String(i + 1),
              onchange: () => { state.confidence = i + 1; } }),
            el("label", { for: inputId }, `${i + 1} · ${label}`));
        })));

    const editorId = `rt-code-${id}`;
    const editor = el("textarea", {
      id: editorId, class: "rt-editor", rows: Math.max(4, card.starter.split("\n").length + 1),
      spellcheck: "false", autocapitalize: "off", autocomplete: "off", "aria-describedby": `${editorId}-help`,
    });
    editor.value = card.starter.replace(/\n$/, "");
    editor.addEventListener("keydown", (e) => {
      if (e.key === "Tab" && !e.shiftKey && !e.ctrlKey && !e.altKey) {
        e.preventDefault();
        const { selectionStart: a, selectionEnd: b, value } = editor;
        editor.value = value.slice(0, a) + "  " + value.slice(b);
        editor.selectionStart = editor.selectionEnd = a + 2;
      } else if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
        e.preventDefault();
        check();
      }
    });

    const hintsBox = el("div", { class: "rt-card-hints" });
    const feedback = el("div", { class: "rt-card-feedback", role: "status", "aria-live": "polite" });
    const outputBox = el("div", { class: "rt-card-output" });
    const after = el("div", { class: "rt-card-after" });

    const checkBtn = el("button", { type: "button", class: "btn btn-primary", onclick: () => check() }, t.check);
    const hintBtn = el("button", { type: "button", class: "btn btn-outline-primary", onclick: () => showHint() },
      card.hints.length ? `${t.showHint} (1/${card.hints.length})` : t.showHint);
    const solutionBtn = el("button", { type: "button", class: "btn btn-outline-secondary", onclick: () => showSolution() }, t.showSolution);
    if (!card.hints.length) hintBtn.hidden = true;

    function setFeedback(kind, html) {
      feedback.dataset.kind = kind;
      feedback.innerHTML = html;
    }

    // Escape, then render `code` spans of check messages.
    function escapeHtml(s) {
      return s
        .replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])
        .replace(/`([^`]+)`/g, "<code>$1</code>");
    }

    function showHint() {
      if (state.hints >= card.hints.length) return;
      const h = card.hints[state.hints];
      state.hints += 1;
      hintsBox.append(el("div", { class: "rt-card-hint", html: `<strong>${t.hint(state.hints, card.hints.length)}:</strong> ${h[lang].replace(/^<p>|<\/p>$/g, "")}` }));
      if (state.hints >= card.hints.length) hintBtn.hidden = true;
      else hintBtn.textContent = `${t.showHint} (${state.hints + 1}/${card.hints.length})`;
    }

    function explanationHtml() {
      const parts = [];
      if (card.misconception) parts.push(`<p><strong>${t.misconception}:</strong></p>${card.misconception[lang]}`);
      parts.push(`<p><strong>${t.explanation}:</strong></p>${card.explanation[lang]}`);
      return parts.join("");
    }

    function showSolution() {
      state.solvedShown = true;
      checkBtn.disabled = true;
      hintBtn.hidden = true;
      solutionBtn.hidden = true;
      after.replaceChildren(
        el("div", { class: "rt-card-solution" },
          el("p", {}, el("strong", {}, t.solution)),
          el("pre", { class: "rt-code" }, el("code", {}, card.solution.replace(/\n$/, ""))),
          el("div", { html: explanationHtml() })),
        el("button", { type: "button", class: "btn btn-primary", onclick: () => finish("wrong") }, t.wrongNext)
      );
      after.querySelector("button").focus();
    }

    async function check() {
      if (state.done || state.solvedShown) return;
      if (!state.confidence) {
        setFeedback("info", `! ${t.needConfidence}`);
        confidence.querySelector("input").focus();
        return;
      }
      if (/_{6,}/.test(editor.value)) {
        setFeedback("info", `! ${t.gaps}`);
        return;
      }
      checkBtn.disabled = true;
      checkBtn.textContent = t.checking;
      try {
        await ensureR(card, announce);
        announce("");
        const r = await runAttempt(card, editor.value);
        state.attempts += 1;
        outputBox.replaceChildren();
        if (r.output) {
          outputBox.append(el("p", { class: "rt-help" }, t.output), el("pre", { class: "rt-code" }, el("code", {}, r.output)));
        }
        if (r.correct) {
          setFeedback("success", `✓ ${escapeHtml(r.message)}`);
          offerRating();
        } else {
          const msg = r.error ? `${t.error}: ${r.error}` : r.message;
          let html = `✗ ${escapeHtml(msg)}`;
          if (state.attempts === 1 && state.confidence === 3) {
            state.firstWrong = true;
            html += `<div class="rt-confident-error"><p>${t.confidentError}</p>${explanationHtml()}</div>`;
          }
          setFeedback("error", html);
        }
      } catch (e) {
        setFeedback("error", `✗ ${escapeHtml(t.loadingFailed(e.message || String(e)))}`);
      } finally {
        checkBtn.textContent = t.check;
        checkBtn.disabled = state.done;
      }
    }

    function offerRating() {
      state.done = true;
      checkBtn.disabled = true;
      hintBtn.hidden = true;
      solutionBtn.hidden = true;
      editor.readOnly = true;
      const easyLocked = state.hints >= 2;
      after.replaceChildren(
        el("fieldset", { class: "rt-rating" },
          el("legend", {}, t.rate),
          el("div", { class: "rt-rating-buttons" },
            el("button", { type: "button", class: "btn btn-outline-primary", disabled: easyLocked, "aria-describedby": easyLocked ? `${editorId}-easy` : null, onclick: () => finish("easy") }, t.easy),
            el("button", { type: "button", class: "btn btn-outline-primary", onclick: () => finish("ok") }, t.ok),
            el("button", { type: "button", class: "btn btn-outline-primary", onclick: () => finish("hard") }, t.hard)),
          easyLocked ? el("p", { class: "rt-help", id: `${editorId}-easy` }, t.easyLocked) : null)
      );
      after.querySelector("button:not([disabled])").focus();
    }

    function finish(result) {
      let item;
      P.update((data) => {
        item = schedule(data, id, result, { confidence: state.confidence, hints: state.hints, attempts: state.attempts });
      });
      session.answered += 1;
      if (result !== "wrong") session.solved += 1;
      const notes = [t.scheduled(item.box, formatDate(item.due))];
      if (item.due <= P.isoDate() && !session.requeued.has(id)) {
        session.requeued.add(id);
        session.queue.push(id);
        notes.push(t.again);
      }
      after.replaceChildren(
        el("p", { class: "rt-card-scheduled" }, notes.join(" ")),
        el("button", { type: "button", class: "btn btn-primary", onclick: () => { session.index += 1; showCard(); } }, t.next)
      );
      after.querySelector("button").focus();
    }

    const card_ = el("article", { class: "rt-card", "aria-labelledby": "rt-card-heading" },
      position, heading, source,
      el("div", { class: "rt-card-prompt", html: card.prompt[lang] }),
      confidence,
      el("label", { for: editorId, class: "rt-editor-label" }, t.code),
      editor,
      el("p", { class: "rt-help", id: `${editorId}-help` }, t.codeHelp),
      el("div", { class: "rt-card-actions" }, checkBtn, hintBtn, solutionBtn),
      hintsBox, feedback, outputBox, after,
      el("p", { class: "rt-card-pause" }, el("button", { type: "button", class: "btn btn-link", onclick: () => finishSession() }, t.pause)));
    heading.id = "rt-card-heading";
    stage.replaceChildren(card_);
    heading.focus();
  }

  // ---- Backup: export / import -------------------------------------------------
  function setupBackup() {
    const box = document.getElementById("rt-backup");
    if (!box) return;
    const msg = el("p", { class: "rt-backup-msg", role: "status", "aria-live": "polite" });
    const fileInput = el("input", { type: "file", id: "rt-import-file", accept: "application/json,.json", class: "rt-file" });
    const confirmBox = el("div", { class: "rt-backup-confirm", hidden: true });

    const exportBtn = el("button", { type: "button", class: "btn btn-outline-primary", onclick: () => {
      const blob = new Blob([JSON.stringify(P.load(), null, 2)], { type: "application/json" });
      const a = el("a", { href: URL.createObjectURL(blob), download: `rtrainer-progress-${P.isoDate()}.json` });
      document.body.append(a);
      a.click();
      setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 0);
    } }, t.export);

    fileInput.addEventListener("change", async () => {
      const file = fileInput.files[0];
      if (!file) return;
      let data;
      try {
        data = JSON.parse(await file.text());
      } catch (e) {
        data = null;
      }
      if (!L.validProgress(data)) {
        msg.textContent = `✗ ${t.importBad}`;
        fileInput.value = "";
        return;
      }
      const now = Object.keys(P.load().exercises).length;
      confirmBox.replaceChildren(
        el("p", {}, t.importConfirm(now, Object.keys(data.exercises).length)),
        el("button", { type: "button", class: "btn btn-primary", onclick: () => {
          P.save(data);
          confirmBox.hidden = true;
          msg.textContent = `✓ ${t.importDone}`;
          fileInput.value = "";
          if (!session) renderOverview();
        } }, t.importDo),
        " ",
        el("button", { type: "button", class: "btn btn-outline-secondary", onclick: () => {
          confirmBox.hidden = true;
          fileInput.value = "";
        } }, t.cancel)
      );
      confirmBox.hidden = false;
      confirmBox.querySelector("button").focus();
    });

    box.append(
      el("p", {}, t.backupText),
      el("div", { class: "rt-backup-actions" },
        exportBtn,
        fileInput,
        el("label", { for: "rt-import-file", class: "btn btn-outline-primary" }, t.importLabel)),
      confirmBox,
      msg
    );
  }

  setupBackup();
  loadCards()
    .then(renderOverview)
    .catch((e) => {
      stage.replaceChildren(el("p", {}, `✗ ${e.message}`));
    });
})();
