// rtrainer lesson page: section navigation with check marks, exercise
// results (read from quarto-live's feedback DOM), knowledge check, completion.
(function () {
  "use strict";

  const TEXT = {
    de: {
      sections: "Abschnitte",
      position: (i, n) => `Abschnitt ${i} von ${n}`,
      solved: "gelöst",
      done: "erledigt",
      open: "offen",
      progress: (s, n, quiz) =>
        `Fortschritt: ${s} von ${n} Pflichtübungen gelöst, Wissenscheck ${quiz}.`,
      quizPassed: "bestanden",
      quizOpen: "offen",
      completed: "Lektion abgeschlossen. Die Übungen sind ab morgen in der Wiederholung.",
      questionRight: "Richtig.",
      questionWrong: "Noch nicht richtig. Lies die Erklärungen zu den Antworten.",
      questionEmpty: "Keine Antwort gewählt.",
      result: (r, n, pct, passed, pass) =>
        `${r} von ${n} richtig (${pct} %). ` +
        (passed ? "Bestanden ✓" : `Zum Bestehen brauchst du mindestens ${pass} %.`),
    },
    en: {
      sections: "Sections",
      position: (i, n) => `Section ${i} of ${n}`,
      solved: "solved",
      done: "done",
      open: "open",
      progress: (s, n, quiz) =>
        `Progress: ${s} of ${n} required exercises solved, knowledge check ${quiz}.`,
      quizPassed: "passed",
      quizOpen: "open",
      completed: "Lesson completed. Its exercises enter review from tomorrow.",
      questionRight: "Correct.",
      questionWrong: "Not quite. Read the explanations of the answers.",
      questionEmpty: "No answer selected.",
      result: (r, n, pct, passed, pass) =>
        `${r} of ${n} correct (${pct}%). ` +
        (passed ? "Passed ✓" : `You need at least ${pass}% to pass.`),
    },
  };

  const P = window.rtProgress;
  const meta = document.querySelector(".rt-lesson-meta[data-lesson]");
  if (!P || !meta) return;

  const lang = (document.documentElement.lang || "de").slice(0, 2);
  const t = TEXT[lang] || TEXT.de;
  const lesson = meta.dataset.lesson;
  const exercises = Array.from(document.querySelectorAll(".rt-exercise[data-exercise]"));
  const allIds = exercises.map((el) => el.dataset.exercise);
  const requiredIds = exercises
    .filter((el) => el.dataset.required === "true")
    .map((el) => el.dataset.exercise);
  const quiz = document.querySelector(".rt-quiz");

  // ---- Layout: breadcrumb above the title -------------------------------
  const breadcrumb = document.querySelector(".rt-breadcrumb");
  const titleBlock = document.querySelector("#title-block-header");
  if (breadcrumb && titleBlock) titleBlock.prepend(breadcrumb);

  // ---- Progress line in the lesson box ----------------------------------
  const progressLine = document.createElement("p");
  progressLine.className = "rt-lesson-progress";
  progressLine.setAttribute("role", "status");
  meta.appendChild(progressLine);

  function renderProgressLine(data) {
    const solved = requiredIds.filter((id) => data.exercises[id] && data.exercises[id].solved);
    const quizDone = data.quizzes[lesson] && data.quizzes[lesson].passed;
    const entry = data.lessons[lesson] || {};
    progressLine.textContent = entry.completedAt
      ? t.completed
      : t.progress(solved.length, requiredIds.length, quizDone ? t.quizPassed : t.quizOpen);
  }

  // ---- Section navigation (left column) ---------------------------------
  const sections = Array.from(document.querySelectorAll("main section.level2[id]"));
  const nav = document.createElement("nav");
  nav.className = "rt-sections";
  nav.setAttribute("aria-label", t.sections);
  const position = document.createElement("p");
  position.className = "rt-sections-position";
  position.setAttribute("aria-live", "polite");
  nav.appendChild(position);
  const list = document.createElement("ol");
  nav.appendChild(list);
  const items = sections.map((section) => {
    const heading = section.querySelector("h2");
    const li = document.createElement("li");
    const a = document.createElement("a");
    a.href = `#${section.id}`;
    const check = document.createElement("span");
    check.className = "rt-check";
    check.setAttribute("aria-hidden", "true");
    const label = document.createElement("span");
    label.textContent = heading ? heading.textContent.trim() : section.id;
    const state = document.createElement("span");
    state.className = "visually-hidden";
    a.append(check, label, state);
    li.appendChild(a);
    list.appendChild(li);
    return { section, a, check, state };
  });

  // Own column left of the text (wide screens only, see CSS); on narrow
  // screens Quarto's collapsible table of contents takes over.
  const content = document.querySelector("#quarto-content");
  if (content) {
    const column = document.createElement("div");
    column.className = "rt-sections-col";
    column.appendChild(nav);
    content.prepend(column);
  }

  function sectionDone(data, section) {
    if (section.querySelector(".rt-exercise")) {
      return requiredIds.every((id) => data.exercises[id] && data.exercises[id].solved);
    }
    if (section.querySelector(".rt-quiz")) {
      return Boolean(data.quizzes[lesson] && data.quizzes[lesson].passed);
    }
    return (data.sections[lesson] || []).includes(section.id);
  }

  function renderSections(data) {
    items.forEach(({ section, check, state }) => {
      const done = sectionDone(data, section);
      check.dataset.done = String(done);
      state.textContent = `, ${done ? t.done : t.open}`;
    });
  }

  function setCurrent(index) {
    items.forEach((item, i) => {
      if (i === index) item.a.setAttribute("aria-current", "true");
      else item.a.removeAttribute("aria-current");
    });
    position.textContent = t.position(index + 1, items.length);
    window.rtCurrentSection = index > 0 ? sections[index].id : "";
  }

  function onScroll() {
    const line = window.innerHeight * 0.35;
    let current = 0;
    sections.forEach((section, i) => {
      if (section.getBoundingClientRect().top <= line) current = i;
    });
    if (window.innerHeight + window.scrollY >= document.body.scrollHeight - 4) {
      current = sections.length - 1;
    }
    setCurrent(current);
  }

  // A text section counts as read once its end has been on screen.
  const seen = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      const id = entry.target.dataset.rtSection;
      seen.unobserve(entry.target);
      P.update((data) => {
        const list = data.sections[lesson] || (data.sections[lesson] = []);
        if (!list.includes(id)) list.push(id);
        markStarted(data);
      });
    });
  });
  sections.forEach((section) => {
    if (section.querySelector(".rt-exercise, .rt-quiz")) return;
    const end = document.createElement("span");
    end.dataset.rtSection = section.id;
    end.setAttribute("aria-hidden", "true");
    section.appendChild(end);
    seen.observe(end);
  });

  function markStarted(data) {
    const entry = data.lessons[lesson] || (data.lessons[lesson] = {});
    if (!entry.startedAt) entry.startedAt = new Date().toISOString();
  }

  // ---- Exercises: read quarto-live feedback ------------------------------
  function exerciseStatusEl(el) {
    let status = el.querySelector(".rt-exercise-status");
    if (!status) {
      status = document.createElement("span");
      status.className = "rt-exercise-status rt-status";
      status.dataset.status = "done";
      status.innerHTML = '<span class="rt-status-icon" aria-hidden="true"></span><span class="rt-status-text"></span>';
      const title = el.querySelector(".rt-exercise-title");
      (title || el).appendChild(status);
    }
    return status;
  }

  function renderExercises(data) {
    exercises.forEach((el) => {
      const record = data.exercises[el.dataset.exercise];
      const solved = Boolean(record && record.solved);
      el.dataset.solved = String(solved);
      if (solved) exerciseStatusEl(el).querySelector(".rt-status-text").textContent = t.solved;
    });
  }

  function recordGrade(el, correct) {
    const id = el.dataset.exercise;
    P.update((data) => {
      const record = data.exercises[id] || (data.exercises[id] = { attempts: 0, hints: 0, solved: false });
      record.attempts += 1;
      record.lastAt = new Date().toISOString();
      if (correct && !record.solved) {
        record.solved = true;
        record.solvedAt = record.lastAt;
      }
      markStarted(data);
      P.updateCompletion(data, lesson, requiredIds, allIds, Boolean(quiz));
    });
  }

  function recordHints(el) {
    const shown = el.querySelectorAll(".exercise-hint:not(.d-none)").length;
    const id = el.dataset.exercise;
    P.update((data) => {
      const record = data.exercises[id] || (data.exercises[id] = { attempts: 0, hints: 0, solved: false });
      record.hints = Math.max(record.hints || 0, shown);
    });
  }

  // Check messages mark code with backticks; show it as code.
  function formatGrade(grade) {
    const walker = document.createTreeWalker(grade, NodeFilter.SHOW_TEXT);
    const nodes = [];
    let node;
    while ((node = walker.nextNode())) if (node.nodeValue.includes("`")) nodes.push(node);
    nodes.forEach((n) => {
      const span = document.createElement("span");
      n.nodeValue.split(/(`[^`]+`)/).forEach((part) => {
        if (/^`[^`]+`$/.test(part)) {
          const code = document.createElement("code");
          code.textContent = part.slice(1, -1);
          span.append(code);
        } else if (part) {
          span.append(document.createTextNode(part));
        }
      });
      n.replaceWith(span);
    });
  }

  exercises.forEach((el) => {
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((m) => {
        if (m.type === "attributes" && m.target.classList.contains("exercise-hint")) {
          recordHints(el);
        }
        m.addedNodes.forEach((node) => {
          if (!(node instanceof HTMLElement)) return;
          const grade = node.classList.contains("exercise-grade") ? node : node.querySelector(".exercise-grade");
          if (grade) {
            formatGrade(grade);
            recordGrade(el, grade.classList.contains("alert-success"));
          }
        });
      });
    });
    observer.observe(el, { childList: true, subtree: true, attributes: true, attributeFilter: ["class"] });
  });

  // ---- Knowledge check ----------------------------------------------------
  function gradeQuestion(fieldset, reveal) {
    const options = Array.from(fieldset.querySelectorAll(".rt-quiz-option"));
    const chosen = options.filter((o) => o.querySelector("input").checked);
    const correct = options.every(
      (o) => (o.dataset.correct === "true") === o.querySelector("input").checked
    );
    if (reveal) {
      options.forEach((o) => {
        const checked = o.querySelector("input").checked;
        const isCorrect = o.dataset.correct === "true";
        o.dataset.result = checked ? (isCorrect ? "right" : "wrong") : isCorrect ? "missed" : "";
        o.querySelector(".rt-quiz-explain").hidden = !(checked || isCorrect);
      });
      fieldset.querySelector(".rt-quiz-feedback").textContent =
        chosen.length === 0 ? t.questionEmpty : correct ? t.questionRight : t.questionWrong;
    }
    return { correct, answer: chosen.map((o) => o.querySelector("input").value) };
  }

  function renderQuizResult(result, passShare) {
    const box = quiz.querySelector(".rt-quiz-result");
    const pct = Math.round(result.score * 100);
    box.dataset.passed = String(result.passed);
    box.textContent = t.result(result.right, result.total, pct, result.passed, Math.round(passShare * 100));
  }

  if (quiz) {
    const passShare = Number(quiz.dataset.pass || 0.8);
    const questions = Array.from(quiz.querySelectorAll(".rt-quiz-question"));

    // Restore the last answers and their evaluation.
    const saved = P.load().quizzes[lesson];
    if (saved && saved.answers) {
      questions.forEach((q) => {
        const answer = saved.answers[q.dataset.question] || [];
        q.querySelectorAll("input").forEach((input) => {
          input.checked = answer.includes(input.value);
        });
        gradeQuestion(q, true);
      });
      renderQuizResult(saved, passShare);
    }

    quiz.addEventListener("submit", (event) => {
      event.preventDefault();
      const answers = {};
      let right = 0;
      questions.forEach((q) => {
        const graded = gradeQuestion(q, true);
        answers[q.dataset.question] = graded.answer;
        if (graded.correct) right += 1;
      });
      const result = {
        right,
        total: questions.length,
        score: right / questions.length,
        passed: right / questions.length >= passShare - 1e-9,
        answers,
        at: new Date().toISOString(),
      };
      P.update((data) => {
        data.quizzes[lesson] = result;
        markStarted(data);
        P.updateCompletion(data, lesson, requiredIds, allIds, true);
      });
      renderQuizResult(result, passShare);
    });
  }

  // ---- Translate quarto-live's fixed English labels ---------------------
  const UI = {
    de: {
      "Run Code": "Ausführen",
      "Start Over": "Neu beginnen",
      "Show Hint": "Hinweis zeigen",
      "Next Hint": "Nächster Hinweis",
      "Show Solution": "Lösung zeigen",
      "Please replace ______ with valid code.": "Ersetze die Lücken ______ durch Code.",
    },
  };
  const ui = UI[lang];

  function translate(root) {
    if (!ui || !(root instanceof HTMLElement)) return;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      const key = node.nodeValue.trim();
      if (ui[key]) node.nodeValue = node.nodeValue.replace(key, ui[key]);
    }
  }

  if (ui) {
    new MutationObserver((mutations) => {
      mutations.forEach((m) => m.addedNodes.forEach(translate));
    }).observe(document.querySelector("main") || document.body, { childList: true, subtree: true });
    translate(document.querySelector("main"));
  }

  // ---- Wire up -------------------------------------------------------------
  function renderAll(data) {
    renderSections(data);
    renderExercises(data);
    renderProgressLine(data);
  }

  P.update(markStarted);
  renderAll(P.load());
  document.addEventListener("rt-progress", (e) => renderAll(e.detail));
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();
})();
