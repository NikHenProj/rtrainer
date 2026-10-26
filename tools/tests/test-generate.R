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
  expect_length(validate_exercise(toy_exercise(check = list(type = "plot", params = list("method"))), ds), 0)
  expect_match(validate_exercise(toy_exercise(check = list(type = "plot", params = list(1))), ds), "argument names", all = FALSE)
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
  single <- paste(readLines(file.path(gen, "exercise-toy-b-mean.qmd")), collapse = "\n")
  expect_match(single, "#ex-toy-b-mean", fixed = TRUE)
  expect_match(single, "Übung 1:", fixed = TRUE)
  plan <- readLines(file.path(dir, "_generated", "de", "course-plan.qmd"))
  expect_true(any(grepl("data-lesson=\"toy-beginner\"", plan)))
  expect_true(any(grepl("rt-cell-planned", plan)))
  footer <- paste(readLines(file.path(gen, "footer.qmd")), collapse = "\n")
  expect_match(footer, "Danach")
  expect_match(footer, "geplant")
  runtime <- paste(readLines(file.path(gen, "runtime.qmd")), collapse = "\n")
  expect_match(runtime, "options(webr.exercise.checker = rt_checker)", fixed = TRUE)
  cards <- jsonlite::read_json(file.path(dir, "assets", "review-cards.json"))
  expect_named(cards$cards, "toy-b-mean")
  expect_match(cards$checks, "rt_checker")
  expect_equal(cards$datasets$toy$file, "toy.csv")
  card <- cards$cards[["toy-b-mean"]]
  expect_equal(card$prompt$de, "<p>Berechne den Mittelwert von <code>x</code>.</p>")
  expect_equal(card$lesson_title$en, "Toy (Beginner)")
  expect_type(card$packages, "list") # JSON array even when empty
  expect_match(card$check$en, 'lang = "en"', fixed = TRUE)
})

test_that("generate stops on invalid content and lists all problems", {
  dir <- withr::local_tempdir()
  make_course(
    dir,
    exercises = list(toy_exercise(), toy_exercise(order = 2, kind = "debug")),
    front_matter = "webr:\n  packages: []"
  )
  err <- tryCatch(generate(dir, langs = "de"), error = conditionMessage)
  expect_match(err, "duplicate exercise id")
  expect_match(err, "misconception")
  expect_match(err, "engine: markdown")
  expect_match(err, "resources lacks toy.csv")
})

test_that("md_html splits paragraphs and escapes", {
  expect_equal(md_html("a `x`\nb\n\nc <d>"), "<p>a <code>x</code> b</p><p>c &lt;d&gt;</p>")
  expect_null(md_html(NULL))
})

test_that("md_html renders pipe tables, lists and quotes", {
  table <- md_html("Werte:\n\n| a | `b` |\n|---|---|\n| 1 | <2 |\n\nEnde")
  expect_equal(table, paste0(
    "<p>Werte:</p><table><thead><tr><th>a</th><th><code>b</code></th></tr></thead>",
    "<tbody><tr><td>1</td><td>&lt;2</td></tr></tbody></table><p>Ende</p>"
  ))
  expect_equal(md_html("- x\n- `y`"), "<ul><li>x</li><li><code>y</code></li></ul>")
  expect_equal(md_html("Frage\n1. ja\n2. nein\nAntwort"), "<p>Frage</p><ol><li>ja</li><li>nein</li></ol><p>Antwort</p>")
  expect_equal(md_html("> zitat\n> weiter\nText"), "<blockquote><p>zitat weiter</p></blockquote><p>Text</p>")
  expect_equal(md_html("| 1 | 2 |"), "<table><tbody><tr><td>1</td><td>2</td></tr></tbody></table>") # no header row
  expect_equal(md_html("a - b\n3. Mai"), "<p>a - b</p><ol><li>Mai</li></ol>")
})

test_that("English pages get English labels and checks", {
  out <- render_exercise(toy_exercise(), 2, "en", list(toy = list(load = "toy <- 1")))
  expect_match(out, "### Exercise 2: Mean", fixed = TRUE)
  expect_match(out, "Hint 1 of 1", fixed = TRUE)
  expect_match(out, 'lang = "en"', fixed = TRUE)
  expect_match(out, "Compute the mean", fixed = TRUE)
})

toy_package <- function() {
  list(
    name = "toypkg", url = "https://example.org",
    purpose = list(de = "Zweck", en = "Purpose"),
    functions = list(list(name = "f()", does = list(de = "macht", en = "does"), example = "f(1)")),
    pitfalls = list(list(de = "Falle", en = "Trap")),
    lessons = list("toy-beginner", "next-beginner")
  )
}

test_that("validate_package finds missing fields", {
  expect_length(validate_package(toy_package()), 0)
  p <- toy_package()
  p$functions <- list()
  expect_match(validate_package(p), "functions", all = FALSE)
  p <- toy_package()
  p$purpose$en <- NULL
  expect_match(validate_package(p), "lacks text for: en", all = FALSE)
  p <- toy_package()
  p$url <- NULL
  expect_match(validate_package(p), "url", all = FALSE)
})

test_that("render_packages links existing lessons and marks planned ones", {
  curriculum <- list(
    levels = list(list(id = "beginner", title = list(de = "Beginner", en = "Beginner"))),
    topics = list(
      list(slug = "toy", levels = list("beginner"), title = list(de = "Spielzeug", en = "Toy")),
      list(slug = "next", levels = list("beginner"), title = list(de = "Danach", en = "Next"))
    )
  )
  out <- render_packages(list(toy_package()), curriculum, list(`toy-beginner` = list()), "en")
  expect_match(out, "## toypkg {#pkg-toypkg .rt-package}", fixed = TRUE)
  expect_match(out, "[Toy (Beginner)](toy-beginner.html)", fixed = TRUE)
  expect_match(out, "Next (Beginner)", fixed = TRUE)
  expect_false(grepl("next-beginner.html", out, fixed = TRUE))
  expect_match(out, "- Trap", fixed = TRUE)
  expect_equal(render_packages(list(), curriculum, list(), "de"), "")
  two <- render_packages(list(toy_package(), utils::modifyList(toy_package(), list(name = "other"))), curriculum, list(), "de")
  expect_match(two, "- Falle\n\n## other", fixed = TRUE) # heading not swallowed by the list
})

test_that("glossary: validation, sorting by page language", {
  terms <- list(
    list(de = "Zebra", en = "Apple", meaning = list(de = "z", en = "a")),
    list(de = "Apfel", en = "Zoo", meaning = list(de = "a", en = "z"))
  )
  expect_length(validate_glossary(terms), 0)
  expect_match(validate_glossary(c(terms, terms[1])), "duplicate", all = FALSE)
  expect_match(validate_glossary(list(list(de = "x", meaning = list(de = "y", en = "y")))), "missing `en`", all = FALSE)
  curriculum <- list(levels = list(), topics = list())
  de <- render_glossary(terms, curriculum, list(), "de")
  expect_lt(regexpr("Apfel", de), regexpr("Zebra", de))
  en <- render_glossary(terms, curriculum, list(), "en")
  expect_lt(regexpr("Apple", en), regexpr("Zoo", en))
})

test_that("lesson.yml `langs` limits pages to the listed languages", {
  dir <- withr::local_tempdir()
  make_course(dir)
  lesson_file <- file.path(dir, "exercises", "toy", "beginner", "lesson.yml")
  err <- tryCatch(generate(dir, langs = c("de", "en")), error = conditionMessage)
  expect_match(err, "page en/toy-beginner.qmd is missing")

  meta <- yaml::read_yaml(lesson_file)
  meta$langs <- list("de")
  yaml::write_yaml(meta, lesson_file)
  generate(dir, langs = c("de", "en"))
  expect_true(file.exists(file.path(dir, "_generated", "de", "toy-beginner", "header.qmd")))
  expect_false(dir.exists(file.path(dir, "_generated", "en", "toy-beginner")))
  plan_en <- paste(readLines(file.path(dir, "_generated", "en", "course-plan.qmd")), collapse = "\n")
  expect_no_match(plan_en, "data-lesson=\"toy-beginner\"")
  expect_match(plan_en, "rt-cell-planned")
  card <- jsonlite::read_json(file.path(dir, "assets", "review-cards.json"))$cards[["toy-b-mean"]]
  expect_equal(unlist(card$lesson_langs), "de")

  meta$langs <- list("fr")
  yaml::write_yaml(meta, lesson_file)
  expect_error(generate(dir, langs = c("de", "en")), "`langs` must be a subset of de, en")
})

test_that("course plan numbers topics but not project rows", {
  curriculum <- list(
    levels = list(list(id = "beginner", title = list(de = "Beginner", en = "Beginner"))),
    topics = list(
      list(slug = "toy", levels = list("beginner"), title = list(de = "Spielzeug", en = "Toy")),
      list(slug = "project", kind = "project", levels = list("beginner"), title = list(de = "Mini-Projekt", en = "Mini project")),
      list(slug = "next", levels = list("beginner"), title = list(de = "Danach", en = "Next"))
    )
  )
  lessons <- list(`project-beginner` = list(meta = list(lesson = "project-beginner"), exercises = list()))
  plan <- render_course_plan(curriculum, lessons, "de")
  expect_match(plan, "<tr class=\"rt-plan-project\"><th scope=\"row\">Mini-Projekt</th>", fixed = TRUE)
  expect_match(plan, "<span class=\"rt-topic-no\">2</span> Danach", fixed = TRUE)
  expect_no_match(plan, "rt-topic-no\">3")
  expect_match(plan, "data-lesson=\"project-beginner\"", fixed = TRUE)
  expect_equal(level_sequence(curriculum, "beginner"), c("toy-beginner", "project-beginner", "next-beginner"))
})
