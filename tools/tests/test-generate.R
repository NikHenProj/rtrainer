test_that("a valid exercise has no problems", {
  expect_length(validate_exercise(toy_exercise(), list(toy = list()), "toy-beginner"), 0)
})

test_that("validate_exercise finds missing and wrong fields", {
  ds <- list(toy = list())
  ex <- toy_exercise()
  ex$hints <- NULL
  expect_match(validate_exercise(ex, ds), "missing field\\(s\\): hints")
  expect_match(validate_exercise(toy_exercise(id = "Toy_1"), ds), "kebab-case", all = FALSE)
  expect_match(validate_exercise(toy_exercise(kind = "essay"), ds), "`kind`", all = FALSE)
  expect_match(validate_exercise(toy_exercise(title = list(de = "Nur DE")), ds), "lacks text for: en", all = FALSE)
  expect_match(validate_exercise(toy_exercise(starter = "mean(toy$x)"), ds), "identical", all = FALSE)
  expect_match(validate_exercise(toy_exercise(kind = "debug"), ds), "misconception", all = FALSE)
  expect_match(validate_exercise(toy_exercise(kind = "complete"), ds), "______", all = FALSE)
  expect_match(validate_exercise(toy_exercise(check = list(type = "object")), ds), "needs `name`", all = FALSE)
  expect_match(validate_exercise(toy_exercise(check = list(type = "output", pattern = "(")), ds), "regex", all = FALSE)
  bad_mistake <- toy_exercise()
  bad_mistake$common_mistakes[[1]]$pattern <- "(["
  expect_match(validate_exercise(bad_mistake, ds), "not a valid regex", all = FALSE)
  expect_match(validate_exercise(toy_exercise(data = list("nope")), ds), "unknown dataset", all = FALSE)
  expect_match(validate_exercise(toy_exercise(), ds, "other-beginner"), "folder belongs", all = FALSE)
})

test_that("validate_quiz checks pass share and options", {
  expect_length(validate_quiz(toy_quiz()), 0)
  q <- toy_quiz()
  q$pass <- 80
  expect_match(validate_quiz(q), "`pass`", all = FALSE)
  q <- toy_quiz()
  q$questions[[1]]$options[[2]]$correct <- TRUE
  expect_match(validate_quiz(q), "multiple: true", all = FALSE)
  q$questions[[1]]$multiple <- TRUE
  expect_length(validate_quiz(q), 0)
  q$questions[[1]]$options[[1]]$correct <- FALSE
  q$questions[[1]]$options[[2]]$correct <- FALSE
  expect_match(validate_quiz(q), "no correct option", all = FALSE)
})

test_that("check_code round-trips the spec and mistakes", {
  code <- check_code(toy_exercise(), "de")
  expect_match(code, "^rt_check\\(")
  env <- new.env()
  env$.result <- 4
  env$.solution <- 4
  env$.user_code <- "mean(toy$x)"
  expect_true(eval(parse(text = code), envir = env)$correct)
  env$.result <- 2
  env$.user_code <- "median(toy$x)"
  expect_equal(eval(parse(text = code), envir = env)$message, "Nicht der Median.")
})

test_that("render_exercise emits quarto-live blocks for one exercise", {
  out <- render_exercise(toy_exercise(), 1, "de", list(toy = list(load = "toy <- 1")))
  expect_match(out, "#| exercise: toy_b_mean", fixed = TRUE)
  expect_match(out, "#| setup: true", fixed = TRUE)
  expect_match(out, "#| solution: true", fixed = TRUE)
  expect_match(out, "#| check: true", fixed = TRUE)
  expect_match(out, "Hinweis 1 von 1", fixed = TRUE)
  expect_match(out, "data-required=\"true\"", fixed = TRUE)
  expect_match(out, "toy <- 1", fixed = TRUE)
})

test_that("inline_md escapes HTML before formatting", {
  expect_equal(inline_md("`a < b` **x**"), "<code>a &lt; b</code> <strong>x</strong>")
})

test_that("generate writes lesson parts, course plan and review cards", {
  dir <- withr::local_tempdir()
  make_course(dir)
  files <- generate(dir, langs = "de")
  gen <- file.path(dir, "_generated", "de", "toy-beginner")
  expect_true(all(file.exists(file.path(gen, c("runtime.qmd", "header.qmd", "exercises.qmd", "quiz.qmd", "footer.qmd")))))
  plan <- readLines(file.path(dir, "_generated", "de", "course-plan.qmd"))
  expect_true(any(grepl("data-lesson=\"toy-beginner\"", plan)))
  expect_true(any(grepl("rt-cell-planned", plan)))
  footer <- paste(readLines(file.path(gen, "footer.qmd")), collapse = "\n")
  expect_match(footer, "Danach")
  expect_match(footer, "geplant")
  runtime <- paste(readLines(file.path(gen, "runtime.qmd")), collapse = "\n")
  expect_match(runtime, "options(webr.exercise.checker = rt_checker)", fixed = TRUE)
  cards <- jsonlite::read_json(file.path(dir, "assets", "review-cards.json"))
  expect_named(cards, "toy-b-mean")
})

test_that("generate stops on invalid content and lists all problems", {
  dir <- withr::local_tempdir()
  make_course(
    dir,
    exercises = list(toy_exercise(), toy_exercise(order = 2, kind = "debug")),
    front_matter = "webr:\n  packages: []"
  )
  err <- tryCatch(generate(dir), error = conditionMessage)
  expect_match(err, "duplicate exercise id")
  expect_match(err, "misconception")
  expect_match(err, "engine: markdown")
  expect_match(err, "resources lacks toy.csv")
})
