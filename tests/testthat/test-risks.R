# Regression tests for "Bekannte Risiken" in docs/SPEC.md

test_that("run_code captures last value, console output and plots", {
  r <- run_code("x <- 1:3\nprint('hi')\nmean(x)")
  expect_true(r$ok)
  expect_equal(r$value, 2)
  expect_match(r$output, "hi")
  r <- run_code("plot(1:3)")
  expect_true(r$ok)
  expect_true(any(vapply(r$results, inherits, TRUE, "recordedplot")))
  expect_false(run_code("invisible(NULL)\nstop('x')")$ok)
})

test_that("timeout is detected via error class, q() does not crash", {
  r <- run_code("Sys.sleep(5)", timeout = 1)
  expect_true(r$timed_out)
  expect_match(r$error, "Zeitlimit")
  r <- run_code("q('no')")
  expect_false(r$ok)
  expect_false(r$timed_out)
  expect_match(r$error, "beendet")
})

test_that("static checks see pkg::fun calls", {
  expect_setequal(used_functions("stringr::str_detect(x, 'a')"), "str_detect")
  st <- list(type = "ast", require = "stringr::str_detect", forbid = "grepl")
  expect_true(check_static(st, "stringr::str_detect(letters, 'a')")$correct)
  expect_false(check_static(st, "grepl('a', letters)")$correct)
  expect_match(check_static(st, "str_detect(")$message, "Syntaxfehler")
})

test_that("compare_df handles tibbles, integer/double and factors", {
  skip_if_not_installed("dplyr")
  y <- data.frame(g = c("a", "b"), n = c(1, 2))
  expect_true(compare_df(dplyr::tibble(g = c("a", "b"), n = 1:2), y, list(), 1e-8)$ok)
  expect_true(compare_df(data.frame(g = factor(c("a", "b")), n = 1:2), y, list(), 1e-8)$ok)
  expect_match(compare_df(data.frame(g = c("a", "c"), n = 1:2), y, list(), 1e-8)$message, "Zeile 2")
  expect_match(compare_df(data.frame(g = 1:2, n = 1:2), y, list(), 1e-8)$message, "Typ")
  grouped <- dplyr::group_by(dplyr::tibble(g = c("a", "b"), n = c(1, 2)), g)
  expect_true(compare_df(grouped, y, list(), 1e-8)$ok)
})

test_that("pick_session handles small pools, empty logs and one topic", {
  exs <- list(a = mk_ex("a"), b = mk_ex("b"))
  s <- pick_session(exs, new_progress(), n = 10, seed = 1)
  expect_setequal(s, c("a", "b"))
  expect_length(pick_session(exs, new_progress(), topics = "none"), 0)
  exs$c <- mk_ex("c", level = 2)  # double level from hand-written lists
  expect_length(pick_session(exs, new_progress(), n = 3), 3)
  expect_equal(progress_stats(new_progress())$streak, 0L)
})

test_that("interleave_topics handles empty input, one topic, and A-B-C-C", {
  expect_equal(interleave_topics(character(), character()), character())
  expect_equal(interleave_topics(c("a", "b"), c(a = "A", b = "A")), c("a", "b"))
  tp <- c(a = "A", b = "B", c1 = "C", c2 = "C")
  out <- interleave_topics(names(tp), tp)
  expect_false(any(tp[out][-1] == tp[out][-length(out)]))
})

test_that("starter ending in a pipe counts as not passed", {
  ex <- read_exercise(system.file("exercises", "02-dplyr", "group-summarise.yml",
                                  package = "rtrainer"))
  r <- check_exercise(ex, ex$starter)
  expect_false(r$correct)
  expect_match(r$message, "Syntaxfehler|unerwartet|Fehler")
})

test_that("common_mistakes regex of the example exercise", {
  ex <- read_exercise(system.file("exercises", "02-dplyr", "group-summarise.yml",
                                  package = "rtrainer"))
  cm <- ex$common_mistakes
  expect_length(match_common_mistakes(cm, "summarise(m = mean(mpg), n = n())"), 1)
  expect_length(match_common_mistakes(cm, "summarise(m = round(mean(mpg), 1), n = n())"), 0)
  expect_length(match_common_mistakes(cm, "summarise(m = round(mean(mpg), 2))"), 0)
})
