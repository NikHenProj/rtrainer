test_that("wrong attempts log the matched mistake, correct ones do not", {
  p <- new_progress()
  p <- record_attempt(p, mk_ex("a"), FALSE, mistake = "nicht gerundet")
  p <- record_attempt(p, mk_ex("a"), TRUE, mistake = "ignoriert")
  p <- record_attempt(p, mk_ex("a"), FALSE, mistake = "")
  expect_equal(p$log[[1]]$mistake, "nicht gerundet")
  expect_null(p$log[[2]]$mistake)
  expect_null(p$log[[3]]$mistake)
})

test_that("error_journal ranks mistakes and falls back to misconception", {
  exs <- list(a = list(misconception = "Fehlvorstellung A"), b = list(misconception = ""))
  p <- new_progress()
  expect_equal(nrow(error_journal(p, exs)), 0)
  p <- record_attempt(p, mk_ex("a", topic = "t1"), FALSE)
  p <- record_attempt(p, mk_ex("b", topic = "t2"), FALSE, mistake = "M")
  p <- record_attempt(p, mk_ex("b", topic = "t2"), FALSE, mistake = "M")
  p <- record_attempt(p, mk_ex("b", topic = "t2"), FALSE)  # no text: skipped
  p <- record_attempt(p, mk_ex("a", topic = "t1"), TRUE)   # correct: skipped
  j <- error_journal(p, exs)
  expect_equal(j$mistake, c("M", "Fehlvorstellung A"))
  expect_equal(j$n, c(2L, 1L))
  expect_equal(j$topic, c("t2", "t1"))
})

test_that("activity_grid covers every day and counts attempts", {
  today <- as.Date("2026-10-25")  # a Sunday
  log <- data.frame(date = as.Date(c("2026-10-25", "2026-10-25", "2026-10-20", "2025-01-01")))
  g <- activity_grid(log, today, weeks = 2)
  expect_equal(nrow(g), 14)
  expect_equal(g$n[g$date == today], 2L)
  expect_equal(sum(g$n), 3L)  # out-of-range date ignored
  expect_true(all(g$weekday %in% 1:7))
  expect_equal(g$weekday[g$date == today], 7L)
  # same week index within a Monday-Sunday block
  expect_equal(length(unique(g$week[g$date >= as.Date("2026-10-19")])), 1)
  expect_equal(sum(activity_grid(data.frame(date = as.Date(character())), today)$n), 0)
})

test_that("record_note stores a trimmed note and survives save/load", {
  local_progress_dir()
  p <- record_note(new_progress(), "a", "  weil group_by gruppiert ")
  save_progress(p)
  expect_equal(load_progress()$items$a$note, "weil group_by gruppiert")
})

test_that("run_code saves plots only when plot_dir is given", {
  d <- withr::local_tempdir()
  r <- run_code("plot(1:3)", plot_dir = d)
  expect_length(r$plots, 1)
  expect_true(file.exists(r$plots))
  expect_length(run_code("plot(1:3)")$plots, 0)
  expect_length(run_code("1 + 1", plot_dir = d)$plots, 0)
  expect_length(run_code("stop('x')", plot_dir = d)$plots, 0)
})

test_that("solution result is cached and reused", {
  ex <- validate_exercise(list(id = "cache-test", topic = "t", title = "T", level = 1,
                               prompt = "p", solution = "Sys.getpid()", check = list(type = "value")))
  first <- solution_result(ex)
  expect_identical(solution_result(ex)$value, first$value)  # same pid = not re-run
  ex2 <- ex
  ex2$solution <- "Sys.getpid() + 0"
  expect_false(identical(solution_result(ex2)$value, first$value))
})

test_that("failing solution aborts and is not cached", {
  ex <- validate_exercise(list(id = "bad-sol", topic = "t", title = "T", level = 1,
                               prompt = "p", solution = "stop('kaputt')", check = list(type = "value")))
  expect_error(solution_result(ex), "kaputt")
  expect_error(solution_result(ex), "kaputt")
})

test_that("check_exercise reports the matched mistake in details", {
  ex <- fixture_exercises()[["fx-sum"]]
  r <- check_exercise(ex, "x <- 1:10\nsum(x[x %/% 2 == 0])")
  expect_false(r$correct)
  expect_match(r$details$mistake, "ganzzahlige Division")
  expect_true(check_exercise(ex, "sum(seq(2, 10, by = 2))")$correct)
})
