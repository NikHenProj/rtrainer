// Tests for assets/logic.js: node --test tests/js
const test = require("node:test");
const assert = require("node:assert/strict");
const L = require("../../assets/logic.js");

const progress = (extra) => Object.assign(L.emptyProgress(), extra || {});

test("addDays handles month ends and leap years", () => {
  assert.equal(L.addDays("2026-01-31", 1), "2026-02-01");
  assert.equal(L.addDays("2028-02-28", 1), "2028-02-29");
  assert.equal(L.addDays("2026-03-01", -1), "2026-02-28");
  assert.equal(L.addDays("2026-10-25", 0), "2026-10-25");
});

test("nextBox: easy up, ok stays, hard down, wrong to box 1, within 1-5", () => {
  assert.equal(L.nextBox(2, "easy"), 3);
  assert.equal(L.nextBox(5, "easy"), 5);
  assert.equal(L.nextBox(3, "ok"), 3);
  assert.equal(L.nextBox(3, "hard"), 2);
  assert.equal(L.nextBox(1, "hard"), 1);
  assert.equal(L.nextBox(4, "wrong"), 1);
});

test("easy with 2 or more hints counts as ok", () => {
  assert.equal(L.effectiveResult("easy", 1), "easy");
  assert.equal(L.effectiveResult("easy", 2), "ok");
  assert.equal(L.effectiveResult("hard", 3), "hard");
});

test("schedule sets box, due date by interval and history", () => {
  const data = progress({ review: { a: { box: 2, due: "2026-10-26" } } });
  const item = L.schedule(data, "a", "easy", { hints: 0, confidence: 2 }, "2026-10-26");
  assert.equal(item.box, 3);
  assert.equal(item.due, "2026-10-29");
  assert.equal(item.history.length, 1);
  assert.equal(item.history[0].result, "easy");

  const wrong = L.schedule(data, "a", "wrong", {}, "2026-10-29");
  assert.equal(wrong.box, 1);
  assert.equal(wrong.due, "2026-10-29"); // box 1: same day

  const capped = progress({ review: { b: { box: 1, due: "2026-10-26", history: Array(20).fill({ result: "ok" }) } } });
  assert.equal(L.schedule(capped, "b", "ok", {}, "2026-10-26").history.length, L.MAX_HISTORY);

  const locked = L.schedule(progress(), "c", "easy", { hints: 2 }, "2026-10-26");
  assert.equal(locked.box, 1); // easy locked -> ok -> box stays
});

test("streak counts consecutive days and breaks after a gap", () => {
  const data = progress();
  assert.equal(L.updateStreak(data, "2026-10-26").count, 1);
  assert.equal(L.updateStreak(data, "2026-10-26").count, 1); // same day
  assert.equal(L.updateStreak(data, "2026-10-27").count, 2);
  assert.equal(L.currentStreak(data, "2026-10-28"), 2); // yesterday still counts
  assert.equal(L.currentStreak(data, "2026-10-29"), 0); // gap
  assert.equal(L.updateStreak(data, "2026-10-29").count, 1);
  assert.equal(L.currentStreak(progress(), "2026-10-29"), 0);
});

test("dueQueue interleaves lessons and skips unknown or future cards", () => {
  const data = progress({
    review: {
      a1: { box: 1, due: "2026-10-20" },
      a2: { box: 1, due: "2026-10-25" },
      b1: { box: 1, due: "2026-10-24" },
      future: { box: 2, due: "2026-11-01" },
      gone: { box: 1, due: "2026-10-01" },
    },
  });
  const cards = { a1: { lesson: "A" }, a2: { lesson: "A" }, b1: { lesson: "B" }, future: { lesson: "B" } };
  assert.deepEqual(L.dueQueue(data, cards, "2026-10-26"), ["a1", "b1", "a2"]);
  assert.deepEqual(L.dueQueue(progress(), cards, "2026-10-26"), []);
  assert.deepEqual(L.dueIds(data, "2026-10-26", ["a1", "future"]), ["a1"]);
});

test("lessonStatus: not started, started, done", () => {
  assert.equal(L.lessonStatus(progress(), "x", ["e1"]), "not-started");
  assert.equal(L.lessonStatus(progress({ exercises: { e1: { solved: false } } }), "x", ["e1"]), "started");
  assert.equal(L.lessonStatus(progress({ lessons: { x: { completedAt: "t" } } }), "x", []), "done");
});

test("updateCompletion needs required exercises and the quiz", () => {
  const now = new Date(2026, 9, 26, 12);
  const data = progress({ exercises: { e1: { solved: true }, e2: { solved: false } } });
  assert.equal(L.updateCompletion(data, "x", ["e1", "e2"], ["e1", "e2", "opt"], true, now), false);
  data.exercises.e2.solved = true;
  assert.equal(L.updateCompletion(data, "x", ["e1", "e2"], ["e1", "e2", "opt"], true, now), false); // quiz missing
  data.quizzes.x = { passed: true };
  assert.equal(L.updateCompletion(data, "x", ["e1", "e2"], ["e1", "e2", "opt"], true, now), true);
  assert.deepEqual(data.review.opt, { box: 1, due: "2026-10-27" });
  assert.equal(L.updateCompletion(data, "x", ["e1", "e2"], [], true, now), false); // only once
});

test("updateCompletion keeps existing review items", () => {
  const data = progress({ exercises: { e1: { solved: true } }, review: { e1: { box: 4, due: "2026-11-30" } } });
  assert.equal(L.updateCompletion(data, "x", ["e1"], ["e1"], false, new Date(2026, 9, 26)), true);
  assert.equal(data.review.e1.box, 4);
});

test("validProgress accepts own format and rejects others", () => {
  assert.equal(L.validProgress(L.emptyProgress()), true);
  assert.equal(L.validProgress({ version: 2, exercises: {}, quizzes: {}, lessons: {}, review: {} }), false);
  assert.equal(L.validProgress({ version: 1, exercises: {} }), false);
  assert.equal(L.validProgress(null), false);
  assert.equal(L.validProgress([]), false);
});

test("nextLesson resumes a started lesson, else the next new one", () => {
  const lessons = { a: { exercises: ["a1"] }, b: { exercises: ["b1"] }, c: { exercises: [] } };
  const order = ["a", "b", "c"];
  assert.deepEqual(L.nextLesson(progress(), order, lessons), { id: "a", kind: "next" });
  const data = progress({ lessons: { a: { completedAt: "t" } }, exercises: { b1: { solved: false } } });
  assert.deepEqual(L.nextLesson(data, order, lessons), { id: "b", kind: "resume" });
  data.lessons.b = { completedAt: "t" };
  assert.deepEqual(L.nextLesson(data, order, lessons), { id: "c", kind: "next" });
  data.lessons.c = { completedAt: "t" };
  assert.equal(L.nextLesson(data, order, lessons), null);
});
