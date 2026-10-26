test_that("queue advances, requeues once and jumps", {
  q <- new_queue(c("a", "b", "c"))
  expect_equal(queue_current(q), "a")
  q <- queue_requeue(q, "a")
  expect_equal(q$ids, c("a", "b", "c", "a"))
  # already queued later: no duplicate
  expect_equal(queue_requeue(q, "a")$ids, q$ids)
  q <- queue_jump(q, "c")
  expect_equal(queue_current(q), "c")
  q <- queue_jump(q, "z")  # unknown id is inserted at the current position
  expect_equal(queue_current(q), "z")
  q <- new_queue("a") |> queue_advance() |> queue_advance()
  expect_true(queue_done(q))
  expect_null(queue_current(q))
  expect_true(queue_done(new_queue(character())))
})

test_that("requeue of the last exercise appends it", {
  q <- queue_advance(new_queue(c("a", "b")))
  expect_equal(queue_requeue(q, "b")$ids, c("a", "b", "b"))
})

test_that("filter_exercises combines topic, level, tags and due", {
  exs <- list(
    a = mk_ex("a", topic = "t1", tags = "x", level = 1L),
    b = mk_ex("b", topic = "t2", tags = "y", level = 2L),
    c = mk_ex("c", topic = "t1", tags = "y", level = 3L)
  )
  p <- new_progress()
  expect_equal(filter_exercises(exs, p), c("a", "b", "c"))
  expect_equal(filter_exercises(exs, p, topics = "t1"), c("a", "c"))
  expect_equal(filter_exercises(exs, p, levels = c("2", "3"), tags = "y"), c("b", "c"))
  expect_equal(filter_exercises(exs, p, only_due = TRUE), character())
  p <- record_attempt(p, exs$b, FALSE, now = as.POSIXct("2026-01-01 10:00:00"))
  expect_equal(filter_exercises(exs, p, only_due = TRUE, today = as.Date("2026-01-01")), "b")
})

test_that("random_exercise skips mastered and returns NULL if none left", {
  p <- new_progress()
  p$items$a <- list(solved = TRUE, box = 5L, interval = 21, seen = TRUE, due = "2026-01-01")
  expect_equal(random_exercise(c("a", "b"), p), "b")
  expect_null(random_exercise("a", p))
})

test_that("topic_progress counts solved and mastered per topic", {
  exs <- list(a = mk_ex("a", topic = "t1"), b = mk_ex("b", topic = "t1"), c = mk_ex("c", topic = "t2"))
  p <- new_progress()
  p$items$a <- list(solved = TRUE, box = 4L, interval = 7, seen = TRUE, due = "2026-01-01")
  p$items$c <- list(solved = TRUE, box = 1L, interval = 0, seen = TRUE, due = "2026-01-01")
  tp <- topic_progress(exs, p)
  expect_equal(tp$total, c(2L, 1L))
  expect_equal(tp$solved, c(1L, 1L))
  expect_equal(tp$mastered, c(1L, 0L))
})

test_that("feedback boxes use colour and symbol", {
  ok <- as.character(feedback_box("success", "Richtig!"))
  expect_match(ok, "alert-success")
  expect_match(ok, "✓")
  bad <- as.character(feedback_box("danger", "Falsch", "Detail"))
  expect_match(bad, "✗")
  expect_match(bad, 'role="alert"')
  expect_match(as.character(feedback_box("warning", "Achtung")), "!")
})

test_that("check_feedback elaborates only confident errors", {
  ex <- list(misconception = "Fehlvorstellung X", explanation = "Weil Y.")
  wrong <- list(correct = FALSE, message = "Falscher Wert")
  plain <- as.character(check_feedback(ex, wrong, confidence = 1))
  expect_no_match(plain, "Fehlvorstellung X")
  sure <- as.character(check_feedback(ex, wrong, confidence = 3))
  expect_match(sure, "rt-emphasis")
  expect_match(sure, "Fehlvorstellung X")
  expect_match(as.character(check_feedback(ex, list(correct = TRUE, message = "Richtig!"))), "alert-success")
  expect_no_match(as.character(check_feedback(ex, wrong, confidence = NA)), "rt-emphasis")
})

test_that("console_text joins output, messages, warnings and errors", {
  res <- list(output = "[1] 2\n", messages = "hallo\n", warnings = "vorsicht",
              error = "object 'z' not found", timed_out = FALSE)
  txt <- console_text(res)
  expect_match(txt, "[1] 2", fixed = TRUE)
  expect_match(txt, "Meldung: hallo")
  expect_match(txt, "Warnung: vorsicht")
  expect_match(txt, "Objekt `z`")
  expect_equal(console_text(list(output = "", messages = character(), warnings = character())),
               "(keine Ausgabe)")
})

test_that("exam_summary marks unanswered exercises", {
  exs <- list(a = list(title = "A", topic = "t"), b = list(title = "B", topic = "t"),
              c = list(title = "C", topic = "u"))
  s <- exam_summary(c("a", "b", "c"), list(a = TRUE, b = FALSE), exs)
  expect_equal(nrow(s), 3)
  expect_true(all(mapply(grepl, c("richtig", "falsch", "nicht bearbeitet"), s$Ergebnis)))
  expect_equal(nrow(exam_summary(character(), list(), exs)), 0)
})

test_that("format_remaining and hint_label", {
  expect_equal(format_remaining(125), "02:05")
  expect_equal(format_remaining(-3), "00:00")
  expect_equal(hint_label(1, 3), "Hinweis (1/3)")
  expect_equal(hint_label(0, 0), "Keine Hinweise")
})
