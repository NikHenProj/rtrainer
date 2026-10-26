test_that("new_exercise creates a valid template", {
  d <- withr::local_tempdir()
  f <- new_exercise("mein-thema", "demo-1", dir = d)
  ex <- read_exercise(f)
  expect_equal(ex$id, "demo-1")
  expect_equal(ex$kind, "write")
  expect_error(new_exercise("mein-thema", "demo-1", dir = d), "existiert")
  res <- check_all_solutions(list(`demo-1` = ex), verbose = FALSE)
  expect_true(res$solution_ok)
})

test_that("text_diff finds first deviation", {
  expect_match(text_diff("a\nb", "a\nc"), "Zeile 2")
  expect_equal(text_diff("a", "a"), "Keine Unterschiede.")
})

test_that("elaborated feedback includes misconception and explanation", {
  ex <- list(misconception = "M", explanation = "E")
  out <- elaborated_feedback(ex, list(message = "falsch"))
  expect_match(out, "Fehlvorstellung: M")
  expect_match(out, "Erklärung: E")
})

# Exercises whose packages (Suggests) are installed
runnable <- function(exs) {
  Filter(function(ex) all(vapply(ex$packages, requireNamespace, TRUE, quietly = TRUE)), exs)
}

test_that("all shipped exercises pass their own checks", {
  skip_on_cran()
  exs <- runnable(Filter(function(ex) !ex$topic %in% c("mixed-models", "ggplot2", "reproduzierbarkeit"), load_exercises()))
  skip_if(length(exs) == 0, "no shipped exercises yet")
  res <- check_all_solutions(exs, verbose = FALSE)
  expect_true(all(res$solution_ok), info = paste(res$id[!res$solution_ok], collapse = ", "))
  expect_true(all(res$starter_fails | is.na(res$starter_fails)))
})

test_that("mixed-model exercises pass their own checks", {
  skip_on_cran()
  skip_if_not_installed("lme4")
  skip_if_not_installed("lmerTest")
  exs <- Filter(function(ex) ex$topic == "mixed-models", load_exercises())
  expect_length(exs, 8)
  res <- check_all_solutions(exs, verbose = FALSE)
  expect_true(all(res$solution_ok), info = paste(res$id[!res$solution_ok], collapse = ", "))
  expect_true(all(res$starter_fails))
})

test_that("ggplot2 exercises pass their own checks", {
  skip_on_cran()
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("dplyr")
  exs <- Filter(function(ex) ex$topic == "ggplot2", load_exercises())
  expect_length(exs, 6)
  res <- check_all_solutions(exs, verbose = FALSE)
  expect_true(all(res$solution_ok), info = paste(res$id[!res$solution_ok], collapse = ", "))
  expect_true(all(res$starter_fails))
})

test_that("reproducibility exercises pass their own checks", {
  skip_on_cran()
  for (p in c("here", "renv", "rmarkdown", "targets")) skip_if_not_installed(p)
  exs <- Filter(function(ex) ex$topic == "reproduzierbarkeit", load_exercises())
  expect_length(exs, 4)
  res <- check_all_solutions(exs, verbose = FALSE)
  expect_true(all(res$solution_ok), info = paste(res$id[!res$solution_ok], collapse = ", "))
  expect_true(all(res$starter_fails))
})

test_that("renv predict answer matches renv::dependencies()", {
  skip_if_not_installed("renv")
  ex <- Filter(function(ex) ex$id == "repro-renv-dependencies-predict", load_exercises())[[1]]
  withr::local_tempdir() |> withr::local_dir()
  env <- new.env()
  eval(parse(text = ex$setup), envir = env)
  deps <- renv::dependencies(env$proj, progress = FALSE, quiet = TRUE)
  expect_equal(sort(unique(deps$Package)), eval(parse(text = ex$solution)))
})
