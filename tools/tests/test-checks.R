test_that("rt_compare accepts equal numbers within tolerance", {
  expect_null(rt_compare(1 + 1e-9, 1))
  expect_match(rt_compare(1.1, 1), "Werte")
  expect_match(rt_compare(c(1, 2), 1), "Länge")
  expect_match(rt_compare(NULL, 1), "kein Ergebnis")
})

test_that("rt_compare handles data frames: row order, factors, columns", {
  expected <- data.frame(g = c("a", "b"), m = c(1, 2))
  shuffled <- data.frame(g = factor(c("b", "a")), m = c(2, 1))
  expect_null(rt_compare(shuffled, expected, ignore_row_order = TRUE))
  expect_match(rt_compare(shuffled, expected, ignore_row_order = FALSE), "Spalte `g`")
  expect_match(rt_compare(expected["g"], expected), "Spalten stimmen nicht")
  expect_match(rt_compare(expected[c("m", "g")], expected, ignore_col_order = FALSE), "Reihenfolge")
  expect_null(rt_compare(expected[c("m", "g")], expected, ignore_col_order = TRUE))
  expect_match(rt_compare(expected[1, ], expected), "Zeilen")
  expect_match(rt_compare(1, expected), "falschen Typ")
})

test_that("rt_compare compares htest results and explains wrong df", {
  df <- data.frame(y = c(1, 2, 3, 4, 5, 6, 7, 9), g = rep(c("a", "b"), each = 4))
  welch <- t.test(y ~ g, data = df)
  student <- t.test(y ~ g, data = df, var.equal = TRUE)
  expect_null(rt_compare(welch, welch))
  expect_match(rt_compare(student, welch), "Freiheitsgrade")
  expect_match(rt_compare(mean(df$y), welch), "htest")
  expect_match(rt_compare(student, welch, lang = "en"), "degrees of freedom")
})

test_that("rt_check reports success, mistakes and generic problems", {
  env <- new.env()
  env$.solution <- 5
  env$.result <- 5
  env$.user_code <- "mean(x)"
  mistakes <- list(list(pattern = "median\\(", message = list(de = "Nicht der Median.", en = "Not the median.")))
  expect_true(rt_check(list(type = "value"), mistakes, env = env)$correct)

  env$.result <- 4
  env$.user_code <- "median(x)"
  res <- rt_check(list(type = "value"), mistakes, env = env)
  expect_false(res$correct)
  expect_equal(res$message, "Nicht der Median.")
  expect_equal(rt_check(list(type = "value"), mistakes, lang = "en", env = env)$message, "Not the median.")

  env$.user_code <- "x[1]"
  expect_match(rt_check(list(type = "value"), mistakes, env = env)$message, "Werte")
})

test_that("rt_check object and output types; errors become feedback", {
  user <- new.env()
  sol <- new.env()
  sol$fit <- 3
  env <- new.env()
  env$.envir_result <- user
  env$.envir_solution <- sol
  expect_match(rt_check(list(type = "object", name = "fit"), env = env)$message, "`fit` fehlt")
  user$fit <- 3
  expect_true(rt_check(list(type = "object", name = "fit"), env = env)$correct)

  env$.result <- "p < .001"
  expect_true(rt_check(list(type = "output", pattern = "p < \\.001"), env = env)$correct)
  expect_false(rt_check(list(type = "output", pattern = "p = 0\\.5"), env = env)$correct)

  bad <- rt_check(list(type = "unknown"), env = env)
  expect_false(bad$correct)
  expect_match(bad$message, "Fehler")
})

test_that("rt_checker evaluates check code with quarto-live's arguments", {
  code <- 'rt_check(spec = list(type = "value"), mistakes = list(), lang = "de")'
  ok <- rt_checker("ex", "1 + 1", code, new.env(), last_value = 2, solution = 2)
  expect_true(ok$correct)
  wrong <- rt_checker("ex", "1", code, new.env(), last_value = 1, solution = 2)
  expect_false(wrong$correct)
  expect_null(rt_checker("ex", "1", NULL, new.env(), last_value = 1))
})
