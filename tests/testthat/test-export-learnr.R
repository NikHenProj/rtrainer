quiet_export <- function(...) suppressMessages(export_learnr(...))

rmd_chunks <- function(lines) {
  starts <- grep("^```\\{r ", lines)
  ends <- grep("^```$", lines)
  lapply(starts, function(s) {
    e <- min(ends[ends > s])
    list(header = sub("^```\\{r (.*)\\}$", "\\1", lines[s]),
         label = sub("^```\\{r ([^,}]+).*$", "\\1", lines[s]),
         code = lines[seq_len(e - s - 1) + s])
  })
}

test_that("export_learnr writes one tutorial per selected topic", {
  d <- withr::local_tempdir()
  exs <- fixture_exercises()
  f <- quiet_export(c("base", "strings"), d, exercises = exs)
  expect_equal(basename(f), c("base.Rmd", "strings.Rmd"))
  expect_false(file.exists(file.path(d, "plots.Rmd")))

  lines <- readLines(f[[1]], encoding = "UTF-8")
  expect_identical(lines[1:5], c("---", "title: \"rtrainer: base\"", "output: learnr::tutorial",
                                 "runtime: shiny_prerendered", "---"))
  expect_length(grep("^## ", lines), 1)
  chunks <- rmd_chunks(lines)
  labels <- vapply(chunks, `[[`, "", "label")
  expect_identical(labels, c("setup", "fx-sum-setup", "fx-sum", "fx-sum-hint-1", "fx-sum-hint-2",
                             "fx-sum-hint-3", "fx-sum-solution", "fx-sum-check"))
  ex_chunk <- chunks[[which(labels == "fx-sum")]]
  expect_match(ex_chunk$header, "exercise = TRUE, exercise.timelimit = 10", fixed = TRUE)
  expect_identical(ex_chunk$code, "x <- 1:10")
  expect_match(paste(chunks[[which(labels == "fx-sum-check")]]$code, collapse = "\n"),
               "rt_equal(.result, .solution", fixed = TRUE)
  for (ch in chunks) expect_no_error(parse(text = ch$code))
})

test_that("unsupported check types get a note instead of a check chunk", {
  d <- withr::local_tempdir()
  f <- quiet_export("plots", d, exercises = fixture_exercises())
  lines <- readLines(f, encoding = "UTF-8")
  labels <- vapply(rmd_chunks(lines), `[[`, "", "label")
  expect_false("fx-plot-check" %in% labels)
  expect_true("fx-plot" %in% labels)
  expect_true(any(grepl("Check-Typ `ast` wird in learnr nicht automatisch", lines, fixed = TRUE)))
  expect_true(any(grepl("Verwende: `hist`", lines, fixed = TRUE)))
})

test_that("object checks compare the named object", {
  ex <- validate_exercise(list(
    id = "obj", topic = "t", title = "Objekt", level = 1, prompt = "p",
    solution = "res <- 1", check = list(type = "object", name = "res", class = "numeric",
                                        compare_value = TRUE)
  ))
  code <- learnr_check(ex)
  expect_no_error(parse(text = code))
  code <- paste(code, collapse = "\n")
  expect_match(code, "exists(\"res\", envir = .envir_result", fixed = TRUE)
  expect_match(code, "inherits(obj, \"numeric\")", fixed = TRUE)
  expect_match(code, "get(\"res\", envir = .envir_solution)", fixed = TRUE)
})

test_that("export_learnr rejects unknown topics and existing files", {
  d <- withr::local_tempdir()
  exs <- fixture_exercises()
  expect_error(quiet_export(c("base", "gibtsnicht"), d, exercises = exs), "gibtsnicht")
  expect_false(file.exists(file.path(d, "base.Rmd")))
  quiet_export("base", d, exercises = exs)
  expect_error(quiet_export("base", d, exercises = exs), "existiert bereits")
  expect_no_error(quiet_export("base", d, exercises = exs, overwrite = TRUE))
})

test_that("chunk fences inside exercise code are refused", {
  expect_error(learnr_chunk("x", c("a <- 1", "```")), "Chunk-Grenze")
})

test_that("Rmd source shown in prompts survives knitting unchanged", {
  skip_if_not_installed("knitr")
  src <- c("````", "```{r, include = FALSE}", "x <- 1", "```", "",
           "M = `r m` ms, `r 'a\\b'`", "````")
  d <- withr::local_tempdir()
  out <- knitr::knit(text = escape_knitr_md(src), quiet = TRUE, envir = new.env())
  expect_identical(split_lines(out), src)
})

test_that("all package exercises export to parseable tutorials", {
  d <- withr::local_tempdir()
  exs <- load_exercises()
  f <- quiet_export(path = d, exercises = exs)
  expect_length(f, length(unique(vapply(exs, `[[`, "", "topic"))))
  n <- sum(vapply(f, function(x) length(grep("^## ", readLines(x, encoding = "UTF-8"))), 1L))
  expect_equal(n, length(exs))
  for (x in f) {
    chunks <- rmd_chunks(readLines(x, encoding = "UTF-8"))
    # starters may be incomplete on purpose (complete/debug), all other chunks must parse
    chunks <- Filter(function(ch) !grepl("exercise = TRUE", ch$header, fixed = TRUE), chunks)
    for (ch in chunks) expect_no_error(parse(text = ch$code))
  }
})

test_that("generated gradethis checks pass the solution and fail wrong code", {
  skip_if_not_installed("gradethis")
  withr::local_package("gradethis")
  exs <- fixture_exercises()
  glob <- paste(learnr_global_setup()[-(1:3)], collapse = "\n")
  grade <- function(ex, code) {
    utils::capture.output(
      m <- gradethis::mock_this_exercise(.user_code = !!code, .solution_code = !!ex$solution,
                                         setup_global = !!glob)
    )
    grader <- eval(parse(text = paste(learnr_check(ex), collapse = "\n")))
    isTRUE(grader(m)$correct)
  }
  expect_true(grade(exs[["fx-sum"]], exs[["fx-sum"]]$solution))
  expect_false(grade(exs[["fx-sum"]], "sum(1:10)"))
  expect_true(grade(exs[["fx-print"]], "cat('Hallo', 'Welt\\n')"))
  expect_false(grade(exs[["fx-print"]], "print('Hallo Welt')"))
})

test_that("exported tutorial renders", {
  skip_if_not(rmarkdown::pandoc_available(), "Pandoc fehlt")
  skip_if_not_installed("learnr")
  skip_if_not_installed("gradethis")
  d <- withr::local_tempdir()
  f <- quiet_export("base", d, exercises = fixture_exercises())
  out <- rmarkdown::render(f, quiet = TRUE, envir = new.env())
  expect_true(file.exists(out))
})
