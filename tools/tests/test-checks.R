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

test_that("rt_compare checks factor levels, their order and values", {
  expected <- factor(c("v", "a", "h"), levels = c("a", "v", "h"))
  expect_null(rt_compare(expected, expected))
  expect_match(rt_compare(factor(c("v", "a", "h")), expected), "Stufen.*erwartet `a`, `v`, `h`")
  expect_match(rt_compare(c("v", "a", "h"), expected), "falschen Typ")
  swapped <- factor(c("a", "v", "h"), levels = c("a", "v", "h"))
  expect_match(rt_compare(swapped, expected), "Werte")
  expect_match(rt_compare(factor("a"), expected, lang = "en"), "levels")
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

test_that("rt_compare compares gtsummary tables by content, not by call", {
  skip_if_not_installed("gtsummary")
  d <- data.frame(
    g = rep(c("a", "b"), each = 12),
    x = (1:24)^1.5,
    s = rep(c("f", "m"), 12)
  )
  expected <- gtsummary::tbl_summary(d, by = g, include = c(x, s))
  same <- gtsummary::tbl_summary(d[c("g", "x", "s")], by = g)
  expect_null(rt_compare(same, expected))
  expect_match(rt_compare(gtsummary::tbl_summary(d, by = g, include = x), expected), "andere Variablen")
  expect_match(rt_compare(gtsummary::tbl_summary(d[-24, ], by = g, include = c(x, s)), expected), "Tabellenkopf")
  mean_sd <- gtsummary::tbl_summary(
    d, by = g, include = c(x, s), statistic = gtsummary::all_continuous() ~ "{mean} ({sd})"
  )
  expect_match(rt_compare(mean_sd, expected), "Kennwerte")
  expect_match(rt_compare(d, expected), "gtsummary")
  expect_match(rt_compare(mean_sd, expected, lang = "en"), "statistics")
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

test_that("rt_check re-evaluates the code when quarto-live passes the wrong last value", {
  code <- 'rt_check(spec = list(type = "value"), mistakes = list(), lang = "de")'
  env <- new.env()
  env$d <- data.frame(a = 1:2)
  asis <- structure("<table></table>", class = "knit_asis")
  ok <- rt_checker("ex", "d[1, , drop = FALSE]", code, env, last_value = asis,
                   solution = data.frame(a = 1L))
  expect_true(ok$correct)
  wrong <- rt_checker("ex", "d", code, env, last_value = asis, solution = data.frame(a = 1L))
  expect_false(wrong$correct)
  broken <- rt_checker("ex", "stop('x')", code, env, last_value = asis, solution = data.frame(a = 1L))
  expect_match(broken$message, "Typ")
  rt_checker("ex", "y <- 1\nd", code, env, last_value = asis, solution = data.frame(a = 1L))
  expect_false(exists("y", envir = env, inherits = FALSE))
  # print methods that return cat()'s NULL, e.g. report()
  cat_print <- rt_checker("ex", "d$a", code, env, last_value = NULL, solution = 1:2)
  expect_true(cat_print$correct)
  # code ending in an assignment still has no result
  assigned <- rt_checker("ex", "z <- d$a", code, env, last_value = NULL, solution = 1:2)
  expect_false(assigned$correct)
  expect_match(assigned$message, "kein Ergebnis")
  # an unrelated last value (seen after loading psych in webR)
  stray <- rt_checker("ex", "d$a", code, env, last_value = 1L, solution = 1:2)
  expect_true(stray$correct)
})

test_that("rt_compare_plot accepts the same plot written differently", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = c(1, 2, 3, 4), y = c(2, 4, 3, 5), g = c("a", "a", "b", "b"))
  expected <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = g)) +
    ggplot2::geom_point() +
    ggplot2::geom_smooth(method = "lm", se = FALSE)
  # mapping split between ggplot() and the layer, named arguments
  written <- ggplot2::ggplot(d, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_point(ggplot2::aes(colour = g)) +
    ggplot2::geom_smooth(ggplot2::aes(colour = g), method = "lm", se = FALSE)
  expect_null(rt_compare_plot(written, expected, params = list("method", "se")))
})

test_that("rt_compare_plot names wrong layers, mappings, settings and params", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = c(1, 2, 3, 4), y = c(2, 4, 3, 5), g = c("a", "a", "b", "b"))
  base <- ggplot2::ggplot(d, ggplot2::aes(g, y))
  expected <- base + ggplot2::geom_boxplot(fill = "steelblue")
  expect_match(rt_compare_plot(base + ggplot2::geom_point(), expected), "geom_boxplot")
  expect_match(rt_compare_plot(base, expected), "erhalten keine")
  mapped <- base + ggplot2::geom_boxplot(ggplot2::aes(fill = "steelblue"))
  expect_match(rt_compare_plot(mapped, expected), "Ebene 1 \\(geom_boxplot\\).*`fill = \"steelblue\"`")
  expect_match(rt_compare_plot(base + ggplot2::geom_boxplot(), expected), "festen Einstellungen")

  smooth <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_smooth(method = "lm", se = FALSE)
  loess <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_smooth(method = "loess", se = FALSE)
  expect_match(rt_compare_plot(loess, smooth, params = list("method")), "Argument `method`")
  expect_null(rt_compare_plot(loess, smooth))
  expect_match(rt_compare_plot(loess, smooth, params = list("method"), lang = "en"), "argument `method`")
})

test_that("rt_compare_plot checks facets, scales and optionally data", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = c(1, 2, 3, 4) * 100, g = c("a", "a", "b", "b"))
  hist <- ggplot2::ggplot(d, ggplot2::aes(x)) + ggplot2::geom_histogram(bins = 5)
  expected <- hist + ggplot2::facet_wrap(~g) + ggplot2::scale_x_log10()
  expect_match(rt_compare_plot(hist + ggplot2::scale_x_log10(), expected), "facet_wrap\\(g\\)")
  expect_match(rt_compare_plot(hist + ggplot2::facet_wrap(~g), expected), "log-10")
  expect_null(rt_compare_plot(hist + ggplot2::facet_wrap(ggplot2::vars(g)) + ggplot2::scale_x_log10(), expected))

  other <- ggplot2::ggplot(d[1:3, ], ggplot2::aes(x)) + ggplot2::geom_histogram(bins = 5)
  expect_null(rt_compare_plot(other, hist))
  expect_match(rt_compare_plot(other, hist, check_data = TRUE), "Daten des Plots")
})

test_that("rt_compare_plot checks layer positions", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = c("a", "a", "b", "b"), y = 1:4, g = c("u", "v", "u", "v"))
  base <- ggplot2::ggplot(d, ggplot2::aes(x, y, fill = g))
  expected <- base + ggplot2::geom_col(position = "dodge")
  expect_null(rt_compare_plot(base + ggplot2::geom_col(position = ggplot2::position_dodge()), expected))
  expect_match(rt_compare_plot(base + ggplot2::geom_col(), expected), "Position.*position_dodge.*position_stack")
  expect_match(rt_compare_plot(base + ggplot2::geom_col(), expected, lang = "en"), "position")
  # default positions of different geoms are compared as they are
  jitter <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_jitter()
  expect_null(rt_compare_plot(jitter, jitter))
})

test_that("rt_compare_plot checks a layer's own data, e.g. reference lines", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = 1:3, y = c(10, 20, 30))
  base <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point()
  expected <- base + ggplot2::geom_hline(yintercept = 25, linetype = "dashed")
  expect_null(rt_compare_plot(base + ggplot2::geom_hline(yintercept = 25, linetype = "dashed"), expected))
  expect_match(
    rt_compare_plot(base + ggplot2::geom_hline(yintercept = 20, linetype = "dashed"), expected),
    "Ebene 2 \\(geom_hline\\).*Daten"
  )
  # layers that inherit the plot data are not compared without check_data
  other <- ggplot2::ggplot(d[1:2, ], ggplot2::aes(x, y)) + ggplot2::geom_point() +
    ggplot2::geom_hline(yintercept = 25, linetype = "dashed")
  expect_null(rt_compare_plot(other, expected))
})

test_that("rt_check plot type: last value, named object, no plot", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = c(1, 2), y = c(3, 4))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point()
  env <- new.env()
  env$.result <- p
  env$.solution <- p
  expect_true(rt_check(list(type = "plot"), env = env)$correct)

  env$.result <- d
  wrong <- rt_check(list(type = "plot"), env = env)
  expect_false(wrong$correct)
  expect_match(wrong$message, "kein ggplot")

  user <- new.env()
  sol <- new.env()
  sol$fig <- p
  env$.envir_result <- user
  env$.envir_solution <- sol
  expect_match(rt_check(list(type = "plot", name = "fig"), env = env)$message, "`fig`")
  user$fig <- p
  expect_true(rt_check(list(type = "plot", name = "fig"), env = env)$correct)
})
