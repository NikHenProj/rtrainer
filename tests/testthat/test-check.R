ex_df <- function(...) validate_exercise(modifyList(list(
  id = "t", topic = "x", title = "t", level = 1L, prompt = "p",
  solution = "data.frame(cyl = c(4, 6), m = c(26.7, 19.7))",
  check = list(type = "value", ignore_row_order = TRUE)), list(...)))

test_that("validation reports missing fields", {
  expect_error(validate_exercise(list(id = "a")), "Pflichtfelder")
  expect_error(validate_exercise(list(id = "A B", topic = "x", title = "t", level = 1,
                                      prompt = "p", solution = "1", check = list(type = "value"))), "id")
})

test_that("exercise kind is validated with default", {
  base <- list(id = "k", topic = "x", title = "t", level = 1L, prompt = "p",
               solution = "1", check = list(type = "value"))
  expect_equal(validate_exercise(base)$kind, "write")
  expect_error(validate_exercise(c(base, list(kind = "quiz"))), "kind")
  expect_equal(validate_exercise(c(base, list(kind = "debug")))$kind, "debug")
})

test_that("value check: right, wrong column, rounding", {
  ex <- ex_df()
  expect_true(check_exercise(ex, "data.frame(cyl = c(6, 4), m = c(19.7, 26.7))")$correct)
  r <- check_exercise(ex, "data.frame(cyl = c(4, 6), mean_mpg = c(26.7, 19.7))")
  expect_false(r$correct); expect_match(r$message, "`m` fehlt")
  r <- check_exercise(ex, "data.frame(cyl = c(4, 6), m = c(26.7, 19.74))")
  expect_match(r$message, "nicht gerundet")
})

test_that("data frame check reports NA mismatches in both directions", {
  y <- data.frame(a = c(1, NA))
  r <- compare_df(data.frame(a = c(1, 3)), y, list(), 1e-8)
  expect_false(r$ok); expect_match(r$message, "erwartet NA, bekommen 3")
  r <- compare_df(data.frame(a = c(NA_real_, NA)), y, list(), 1e-8)
  expect_false(r$ok); expect_match(r$message, "erwartet 1, bekommen NA")
})

test_that("runtime problems never crash", {
  ex <- ex_df(timeout = 2)
  expect_match(check_exercise(ex, "while (TRUE) {}")$message, "Zeitlimit")
  expect_false(check_exercise(ex, "stop('boom')")$correct)
  expect_false(check_exercise(ex, "q('no')")$correct)
  expect_match(check_exercise(ex, "foo + 1")$message, "foo")
})

test_that("common_mistakes hints also follow runtime errors", {
  ex <- ex_df(common_mistakes = list(list(pattern = "stop\\(", message = "Kein stop() hier.")))
  r <- check_exercise(ex, "stop('kaputt')")
  expect_false(r$correct)
  expect_match(r$message, "kaputt")
  expect_equal(r$details$mistake, "Kein stop() hier.")
  r <- check_exercise(ex, "log(-'a')")
  expect_false(r$correct)
  expect_null(r$details$mistake)
  expect_true(check_exercise(ex, "data.frame(cyl = c(4, 6), m = c(26.7, 19.7))")$correct)
})

test_that("function and ast checks", {
  ex <- validate_exercise(list(id = "f", topic = "x", title = "t", level = 1L, prompt = "p",
    solution = "sq <- function(x) x^2",
    check = list(type = "function", name = "sq",
                 tests = list(list(args = "list(2)", expect = "4"),
                              list(args = "list(numeric())", expect = "numeric()")))))
  expect_true(check_exercise(ex, "sq <- function(x) x * x")$correct)
  expect_false(check_exercise(ex, "sq <- function(x) 'a'")$correct)
  st <- list(type = "ast", forbid = "for", require = "purrr::map_dbl")
  expect_false(check_static(st, "for (i in 1:3) i")$correct)
  expect_true(check_static(st, "purrr::map_dbl(1:3, ~ .x)")$correct)
})

test_that("require applies to executed checks without forbid", {
  ex <- validate_exercise(list(id = "r", topic = "x", title = "t", level = 1L, prompt = "p",
    solution = "sq <- function(x) x^2; sq(sqrt(2))",
    check = list(type = "function", name = "sq", require = "sqrt",
                 tests = list(list(args = "list(3)", expect = "9")))))
  expect_true(check_exercise(ex, ex$solution)$correct)
  r <- check_exercise(ex, "sq <- function(x) x^2")
  expect_false(r$correct)
  expect_match(r$message, "sqrt")
  expect_false(check_exercise(ex, "sq <- function(x) x + 1; sqrt(2)")$correct)
})

test_that("require failures also show the matching common mistake", {
  ex <- validate_exercise(list(id = "r", topic = "x", title = "t", level = 1L, prompt = "p",
    solution = "sq <- function(x) sqrt(x)^4",
    check = list(type = "function", name = "sq", require = "sqrt",
                 tests = list(list(args = "list(3)", expect = "9"))),
    common_mistakes = list(list(pattern = "\\^\\s*2", message = "Quadrat statt Wurzel"))))
  r <- check_exercise(ex, "sq <- function(x) x^2")
  expect_false(r$correct)
  expect_match(r$message, "sqrt")
  expect_match(r$message, "Quadrat statt Wurzel")
})

test_that("predict answers must be value literals", {
  ex <- validate_exercise(list(id = "p", topic = "x", title = "t", level = 1L, prompt = "p",
    kind = "predict", setup = "x <- c(4, NA, 7, 1)", solution = "c(4, NA, 7)",
    check = list(type = "value")))
  expect_true(check_exercise(ex, "c(4, NA, 7)")$correct)
  expect_true(check_exercise(ex, "# Vorhersage\nc(4L, NA, 7L)")$correct)
  r <- check_exercise(ex, "x[x > 3]")
  expect_false(r$correct); expect_match(r$message, "als Wert")
  expect_false(check_exercise(ex, "y <- c(4, NA, 7); y")$correct)
  expect_false(check_exercise(ex, "c(4, 7)")$correct)
  expect_true(check_literal("factor(c('a', 'b'), levels = c('b', 'a'))")$correct)
  expect_true(check_literal("list(a = -1, b = TRUE, c = NULL)")$correct)
  expect_false(check_literal("c(1, ")$correct)
})

test_that("rtrainer_data() is available in the worker and in the package", {
  expect_true(file.exists(rtrainer_data("driving_sim.csv")))
  expect_error(rtrainer_data("missing.csv"))
  r <- run_code("nrow(read.csv(rtrainer_data('driving_sim.csv')))")
  expect_true(r$ok); expect_equal(r$value, 480)
  expect_false(run_code("rtrainer_data('missing.csv')")$ok)
})

test_that("worker code runs in the global environment", {
  ex <- list(setup = "d <- data.frame(x = 1:5, y = c(2, 4, 5, 4, 5))")
  # update() inside a function re-evaluates the call where only globals are visible
  code <- "refit <- function(m) update(m, . ~ 1)\ncoef(refit(lm(y ~ x, data = d)))"
  r <- run_code(code, ex)
  expect_true(r$ok)
  expect_equal(unname(r$value), 4)
  # the helper is not reported as a user object
  expect_setequal(names(r$env), c("d", "refit"))
  # an error in user code still fails cleanly
  expect_false(run_code("update(lm(y ~ x, data = nope))", ex)$ok)
})

test_that("bare y/n in exercise YAML stay strings", {
  f <- withr::local_tempfile(fileext = ".yml")
  writeLines(c("id: t", "topic: t", "title: t", "level: 1", "prompt: p", "solution: '1'",
               "check:", "  type: plot", "  mapping: {x: a, y: b}", "  layers:",
               "    point: [x, y]", "  flag: yes"), f)
  chk <- read_exercise(f)$check
  expect_equal(chk$mapping, list(x = "a", y = "b"))
  expect_equal(unlist(chk$layers$point), c("x", "y"))
  expect_true(chk$flag)
})

test_that("plot check compares layers, facets, scales and theme with the solution", {
  skip_if_not_installed("ggplot2")
  d <- "library(ggplot2)\nd <- data.frame(g = rep(c('b', 'a'), each = 5), v = c(1:5, 3:7) * 100)"
  base <- "ggplot(d, aes(v)) + geom_histogram(bins = 3)"
  ex <- list(id = "t-plot", setup = d, packages = "ggplot2",
             solution = paste(base, "+ facet_wrap(~ g) + scale_x_log10(breaks = c(100, 300)) +",
                              "theme_bw() + theme(legend.position = 'bottom')"),
             check = list(type = "plot", geoms = list("bar"), mapping = list(x = "v"),
                          facet = list("g"), scales = list("x"),
                          layers = list(bar = list("xmin", "count", "PANEL")),
                          theme = list("legend.position", "panel.background")))
  expect_true(check_exercise(ex, ex$solution)$correct)
  # equivalent code passes
  alt <- paste(base, "+ facet_grid(g ~ .) + scale_x_continuous(trans = 'log10', breaks = c(100, 300)) +",
               "theme_bw(base_size = 11) + theme(legend.position = 'bottom')")
  expect_true(check_exercise(ex, alt)$correct)
  expect_match(check_exercise(ex, "ggplot(d, aes(v)) + geom_point(aes(y = v))")$message, "geom_bar")
  expect_match(check_exercise(ex, paste(base, "+ facet_wrap(~ v)"))$message, "Facets nach `g`")
  r <- check_exercise(ex, paste(base, "+ facet_wrap(~ g) + scale_x_sqrt()"))
  expect_match(r$message, "Transformation log-10, bekommen Transformation sqrt")
  r <- check_exercise(ex, paste(base, "+ facet_wrap(~ g) + scale_x_log10()"))
  expect_match(r$message, "Achsenmarken")
  r <- check_exercise(ex, sub("bins = 3", "bins = 4", ex$solution))
  expect_match(r$message, "Layer `bar`")
  r <- check_exercise(ex, sub("theme_bw\\(\\) \\+ (theme\\(.*\\))", "\\1 + theme_bw()", ex$solution))
  expect_match(r$message, "`legend.position`: erwartet bottom, bekommen right")
  r <- check_exercise(ex, sub("theme_bw()", "theme_grey()", ex$solution, fixed = TRUE))
  expect_match(r$message, "`panel.background`")
})

test_that("plot check normalises colours and checks discrete order", {
  skip_if_not_installed("ggplot2")
  ex <- list(id = "t-fill", setup = "library(ggplot2)\nd <- data.frame(g = c('b', 'a'), v = 1:2)",
             packages = "ggplot2",
             solution = "ggplot(d, aes(factor(g, levels = c('b', 'a')), v)) + geom_col(fill = 'steelblue')",
             check = list(type = "plot", scales = list("x"), layers = list(col = list("x", "fill"))))
  expect_true(check_exercise(ex, "ggplot(d, aes(g, v)) + geom_col(fill = '#4682B4') + scale_x_discrete(limits = c('b', 'a'))")$correct)
  expect_match(check_exercise(ex, "ggplot(d, aes(g, v)) + geom_col(fill = 'steelblue')")$message, "Reihenfolge")
  r <- check_exercise(ex, "ggplot(d, aes(factor(g, levels = c('b', 'a')), v)) + geom_col(aes(fill = 'steelblue'))")
  expect_match(r$message, "Spalte `fill`")
})

test_that("check$post inspects the worker state after the code", {
  ex <- list(id = "t-post", setup = "f <- file.path(tempdir(), 'x.txt')",
             solution = "writeLines(c('a', 'b'), f)",
             check = list(type = "output", post = "length(readLines(f))",
                          post_message = "Datei falsch."))
  expect_true(check_exercise(ex, ex$solution)$correct)
  r <- check_exercise(ex, "writeLines('a', f)")
  expect_false(r$correct); expect_match(r$message, "Datei falsch. Erwartet: 2; bekommen: 1")
  r <- check_exercise(ex, "x <- 1")
  expect_false(r$correct); expect_match(r$message, "^Datei falsch\\. \\S")
})
