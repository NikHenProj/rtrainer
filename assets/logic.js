// rtrainer progress logic without DOM access: dates, Leitner boxes, streak,
// due cards, lesson status and completion. Used by progress.js and
// review.js in the browser and by tests/js/logic.test.js in Node.
(function (root) {
  "use strict";

  const VERSION = 1;
  const INTERVALS = [0, 1, 3, 7, 21]; // days until due, per box 1-5
  const MAX_HISTORY = 20;

  function emptyProgress() {
    return { version: VERSION, exercises: {}, quizzes: {}, lessons: {}, sections: {}, review: {} };
  }

  // Local calendar date as YYYY-MM-DD.
  function isoDate(date) {
    const d = date || new Date();
    const pad = (n) => String(n).padStart(2, "0");
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  }

  // Calendar arithmetic on YYYY-MM-DD (safe across daylight-saving changes).
  function addDays(iso, days) {
    const [y, m, d] = iso.split("-").map(Number);
    return isoDate(new Date(y, m - 1, d + days));
  }

  function nextBox(box, result) {
    if (result === "wrong") return 1;
    if (result === "easy") return Math.min(5, box + 1);
    if (result === "hard") return Math.max(1, box - 1);
    return box; // "ok"
  }

  // "Easy" is only allowed with fewer than 2 hints; otherwise it counts as "ok".
  function effectiveResult(result, hints) {
    return result === "easy" && hints >= 2 ? "ok" : result;
  }

  function updateStreak(data, today) {
    const s = data.streak || { count: 0, last: null };
    if (s.last === today) return s;
    data.streak = { count: s.last === addDays(today, -1) ? s.count + 1 : 1, last: today };
    return data.streak;
  }

  // A streak whose last day is before yesterday is broken.
  function currentStreak(data, today) {
    const s = data.streak;
    if (!s || !s.last) return 0;
    return s.last === today || s.last === addDays(today, -1) ? s.count : 0;
  }

  // Record one review answer: new box, due date, history entry, streak.
  function schedule(data, id, result, meta, today) {
    const m = meta || {};
    const res = effectiveResult(result, m.hints || 0);
    const item = data.review[id] || { box: 1, due: today };
    item.box = nextBox(item.box || 1, res);
    item.due = addDays(today, INTERVALS[item.box - 1]);
    item.last = today;
    item.history = (item.history || []).concat([Object.assign({ date: today, result: res }, m)]).slice(-MAX_HISTORY);
    data.review[id] = item;
    updateStreak(data, today);
    return item;
  }

  function dueIds(data, today, ids) {
    return Object.keys(data.review).filter(
      (id) => data.review[id].due <= today && (!ids || ids.includes(id))
    );
  }

  // Due cards (that still exist), interleaved by lesson, oldest due first.
  function dueQueue(data, cards, today) {
    const byLesson = {};
    Object.keys(data.review)
      .filter((id) => cards[id] && data.review[id].due <= today)
      .sort((a, b) => data.review[a].due.localeCompare(data.review[b].due) || a.localeCompare(b))
      .forEach((id) => {
        (byLesson[cards[id].lesson] = byLesson[cards[id].lesson] || []).push(id);
      });
    const lists = Object.values(byLesson);
    const queue = [];
    while (lists.some((l) => l.length)) lists.forEach((l) => l.length && queue.push(l.shift()));
    return queue;
  }

  // "done", "started" or "not-started".
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
  function updateCompletion(data, lesson, requiredIds, allIds, hasQuiz, now) {
    const entry = data.lessons[lesson] || (data.lessons[lesson] = {});
    if (entry.completedAt) return false;
    const solved = requiredIds.every((id) => data.exercises[id] && data.exercises[id].solved);
    const quizOk = !hasQuiz || Boolean(data.quizzes[lesson] && data.quizzes[lesson].passed);
    if (!(solved && quizOk)) return false;
    const date = now || new Date();
    entry.completedAt = date.toISOString();
    const tomorrow = addDays(isoDate(date), 1);
    (allIds || requiredIds).forEach((id) => {
      if (!data.review[id]) data.review[id] = { box: 1, due: tomorrow };
    });
    return true;
  }

  // Where to continue: the first started lesson on the recommended path,
  // otherwise the first one not started. Null when everything is done.
  function nextLesson(data, order, lessons) {
    const status = (id) => lessonStatus(data, id, (lessons[id] && lessons[id].exercises) || []);
    const started = order.find((id) => status(id) === "started");
    if (started) return { id: started, kind: "resume" };
    const fresh = order.find((id) => status(id) === "not-started");
    return fresh ? { id: fresh, kind: "next" } : null;
  }

  // Imported files must be rtrainer progress of a known version.
  function validProgress(data) {
    return Boolean(
      data && typeof data === "object" && data.version === VERSION &&
      ["exercises", "quizzes", "lessons", "review"].every((k) => data[k] && typeof data[k] === "object")
    );
  }

  const api = {
    VERSION, INTERVALS, MAX_HISTORY, emptyProgress, isoDate, addDays, nextBox, effectiveResult,
    updateStreak, currentStreak, schedule, dueIds, dueQueue, lessonStatus, updateCompletion, validProgress,
    nextLesson,
  };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.rtLogic = api;
})(this);
