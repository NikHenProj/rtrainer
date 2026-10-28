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

test_that("rt_compare checks column types only with check_types", {
  expected <- data.frame(g = factor(c("touch", "voice"), levels = c("touch", "voice")), n = c(1, 2))
  as_text <- data.frame(g = c("touch", "voice"), n = 1:2)
  expect_null(rt_compare(as_text, expected))
  expect_match(rt_compare(as_text, expected, check_types = TRUE), "Spalte `g` hat den Typ character, erwartet: factor")
  expect_match(rt_compare(as_text, expected, check_types = TRUE, lang = "en"), "Column `g` has type character")
  as_factor <- transform(as_text, g = factor(g, levels = c("touch", "voice")))
  expect_null(rt_compare(as_factor, expected, check_types = TRUE)) # integer and double both numeric
  other_levels <- transform(as_text, g = factor(g, levels = c("voice", "touch")))
  expect_match(rt_compare(other_levels, expected, check_types = TRUE), "Stufen")
  dates <- data.frame(d = as.Date("2026-01-01"))
  expect_null(rt_compare(dates, dates, check_types = TRUE)) # unknown types are not checked
  env <- new.env()
  env$.envir_result <- list2env(list(x = as_text))
  env$.envir_solution <- list2env(list(x = expected))
  expect_match(rt_problem(list(type = "object", name = "x", check_types = TRUE), "de", env), "Typ character")
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

test_that("rt_compare_plot compares patchwork combinations plot by plot and their layout", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("patchwork")
  library(patchwork)
  d <- data.frame(g = c("a", "a", "b", "b"), y = 1:4)
  p1 <- ggplot2::ggplot(d, ggplot2::aes(g, y)) + ggplot2::geom_point()
  p2 <- ggplot2::ggplot(d, ggplot2::aes(g, y)) + ggplot2::geom_boxplot()
  expected <- p1 + p2 + plot_layout(guides = "collect") + plot_annotation(tag_levels = "A")
  # same combination, written with the operators in another order
  written <- (p1 | p2) + plot_annotation(tag_levels = "A") + plot_layout(guides = "collect")
  expect_null(rt_compare_plot(written, expected))

  expect_match(rt_compare_plot(p1, expected), "patchwork")
  expect_match(rt_compare_plot(p1 + p2 + p1, expected), "3 statt 2")
  swapped <- p2 + p1 + plot_layout(guides = "collect") + plot_annotation(tag_levels = "A")
  expect_match(rt_compare_plot(swapped, expected), "^Plot 1 der Kombination: Die Ebenen")
  expect_match(rt_compare_plot(p1 + p2 + plot_layout(guides = "collect"), expected), "tag_levels")
  stacked <- p1 / p2 + plot_layout(guides = "collect") + plot_annotation(tag_levels = "A")
  expect_match(rt_compare_plot(stacked, expected, lang = "en"), "arrangement")
  # a single plot is still compared as before
  expect_null(rt_compare_plot(p1, p1))
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
  # geom_jitter() equals geom_point() with jitter, whatever the layer is called
  point_jitter <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point(position = "jitter")
  expect_null(rt_compare_plot(point_jitter, jitter))
  point <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point()
  expect_match(rt_compare_plot(point, jitter), "Position.*position_jitter.*position_identity")
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

test_that("rt_compare compares lavaan models through their parameters", {
  skip_if_not_installed("lavaan")
  skip_if_not_installed("parameters")
  d <- lavaan::HolzingerSwineford1939
  model <- "visual =~ x1 + x2 + x3\ntextual =~ x4 + x5 + x6"
  expected <- lavaan::cfa(model, data = d)
  # Same model written differently (other order, own data copy): accepted.
  same <- lavaan::cfa("textual =~ x4 + x5 + x6\nvisual =~ x1 + x2 + x3", data = d[names(d)])
  expect_null(rt_compare(same, expected))
  # Item missing: names the parameter.
  fewer <- lavaan::cfa("visual =~ x1 + x2 + x3\ntextual =~ x4 + x5", data = d)
  expect_match(rt_compare(fewer, expected), "Fehlt: `textual =~ x6`\\. Zusätzlich: keine")
  # Long lists are cut after four parameters.
  one_factor <- lavaan::cfa("visual =~ x1 + x2 + x3 + x4 + x5 + x6", data = d)
  expect_match(rt_compare(one_factor, expected), "`textual ~~ visual`\\. Zusätzlich: `visual =~ x4`")
  three <- lavaan::cfa(paste(model, "\nspeed =~ x7 + x8 + x9"), data = d)
  expect_match(rt_compare(expected, three), "Fehlt: (`[^`]+`, ){4}…\\.")
  # Same parameters, other values (one item reversed).
  reversed <- transform(d, x2 = 10 - x2)
  expect_match(rt_compare(lavaan::cfa(model, data = reversed), expected), "andere Werte \\(`Coefficient`\\)")
  expect_match(rt_compare(lm(x1 ~ x2, d), expected, lang = "en"), "expected lavaan, got lm")
})

test_that("rt_compare compares afex ANOVAs by terms, F and df", {
  skip_if_not_installed("afex")
  skip_if_not_installed("parameters")
  d <- data.frame(
    id = factor(rep(1:12, each = 3)),
    cond = factor(rep(c("a", "b", "c"), 12)),
    y = c(5, 6, 8, 4, 6, 7, 6, 6, 9, 5, 7, 8, 3, 5, 6, 5, 5, 8, 4, 6, 9, 6, 7, 7, 5, 6, 8, 4, 5, 7, 6, 8, 9, 5, 6, 7)
  )
  quiet <- function(x) suppressMessages(suppressWarnings(x))
  expected <- quiet(afex::aov_ez("id", "y", d, within = "cond"))
  expect_null(rt_compare(quiet(afex::aov_car(y ~ cond + Error(id / cond), d)), expected))
  # Ignoring the repeated measures: other term structure or other F.
  between <- quiet(afex::aov_ez("id", "y", transform(d, id = factor(seq_len(nrow(d)))), between = "cond"))
  expect_false(is.null(rt_compare(between, expected)))
  d_other <- transform(d, y = y + c(0, 0, 3))
  expect_match(rt_compare(quiet(afex::aov_ez("id", "y", d_other, within = "cond")), expected), "`F`")
})
