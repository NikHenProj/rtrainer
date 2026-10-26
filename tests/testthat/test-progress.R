test_that("progress survives save/load", {
  local_progress_dir()
  p <- load_progress()
  expect_length(p$items, 0)
  p <- record_attempt(p, mk_ex("a"), TRUE, now = as.POSIXct("2026-01-01 10:00:00"))
  p <- record_rating(p, "a", "easy", today = as.Date("2026-01-01"))
  save_progress(p)
  q <- load_progress()
  expect_equal(q$items$a$box, 2)
  expect_equal(q$items$a$due, "2026-01-02")
})

test_that("wrong answer resets to box 1 and is due now", {
  local_progress_dir()
  p <- new_progress()
  p <- record_attempt(p, mk_ex("a"), TRUE, now = as.POSIXct("2026-01-01 10:00:00"))
  p <- record_rating(p, "a", "easy", today = as.Date("2026-01-01"))
  p <- record_attempt(p, mk_ex("a"), FALSE, now = as.POSIXct("2026-01-05 10:00:00"))
  expect_equal(p$items$a$box, 1)
  expect_true("a" %in% due_ids(p, as.Date("2026-01-05")))
})

test_that("corrupt file falls back to empty with backup", {
  d <- local_progress_dir()
  writeLines("{not json", file.path(d, "progress.json"))
  expect_warning(p <- load_progress(), "besch")
  expect_length(p$items, 0)
  expect_true(file.exists(file.path(d, "progress.json.bak")))
})

test_that("stats: streak and weakest tags", {
  local_progress_dir()
  p <- new_progress()
  for (d in c("2026-01-01", "2026-01-02", "2026-01-03")) {
    p <- record_attempt(p, mk_ex("a", tags = c("x")), FALSE, now = as.POSIXct(paste(d, "09:00:00")))
    p <- record_attempt(p, mk_ex("b", tags = c("y")), TRUE, now = as.POSIXct(paste(d, "09:05:00")))
  }
  s <- progress_stats(p, today = as.Date("2026-01-03"))
  expect_equal(s$streak, 3L)
  expect_equal(s$weak_tags$tag[1], "x")
  expect_equal(progress_stats(new_progress())$streak, 0L)
})

test_that("pick_session mixes due and new, respects n", {
  local_progress_dir()
  exs <- setNames(lapply(1:12, function(i) mk_ex(paste0("e", i), level = (i %% 3) + 1L)), paste0("e", 1:12))
  p <- record_attempt(new_progress(), exs$e1, FALSE, now = as.POSIXct("2026-01-01 10:00:00"))
  s <- pick_session(exs, p, n = 5, today = as.Date("2026-01-02"), seed = 1)
  expect_length(s, 5)
  expect_equal(s[1], "e1")
  expect_false(anyDuplicated(s) > 0)
})

test_that("interleave_topics avoids neighbours of the same topic when possible", {
  tp <- c(a1 = "A", a2 = "A", b1 = "B", c1 = "C")
  out <- interleave_topics(c("a1", "a2", "b1", "c1"), tp)
  expect_setequal(out, names(tp))
  expect_false(any(tp[out][-1] == tp[out][-length(out)]))
})

test_that("easy rating with >= 2 hints is capped to ok", {
  p <- record_attempt(new_progress(), mk_ex("a"), TRUE, now = as.POSIXct("2026-01-01 10:00:00"))
  p <- record_rating(p, "a", "easy", today = as.Date("2026-01-01"), hints = 2L)
  expect_equal(p$items$a$box, 1)
})

test_that("calibration and confident errors", {
  p <- new_progress()
  p <- record_attempt(p, mk_ex("a"), FALSE, confidence = 3L, now = as.POSIXct("2026-01-01 09:00:00"))
  p <- record_attempt(p, mk_ex("b"), TRUE, confidence = 3L, now = as.POSIXct("2026-01-01 09:05:00"))
  s <- progress_stats(p, today = as.Date("2026-01-01"))
  expect_equal(s$calibration$rate, 0.5)
  expect_true(is_confident_error(FALSE, 3L))
  expect_false(is_confident_error(FALSE, NA))
  expect_false(is_confident_error(TRUE, 3L))
})
