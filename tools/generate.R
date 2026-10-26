# Generate lesson building blocks from the exercise YAML files.
#
#   Rscript tools/generate.R
#
# Reads curriculum.yml, data/datasets.yml and exercises/<slug>/<level>/
# (lesson.yml, quiz.yml, one YAML per exercise) and writes, per language,
# _generated/<lang>/<lesson>/{runtime,header,exercises,quiz,footer}.qmd,
# _generated/<lang>/{course-plan,packages,glossary}.qmd and
# assets/review-cards.json (cards for the review page).
# Lesson pages (<lang>/<lesson>.qmd) include these files.
# Stops with a list of problems if any exercise, quiz or lesson is invalid.

langs <- c("de", "en")
kinds <- c("write", "interpret", "debug", "complete", "predict")
check_types <- c("value", "object", "output")
levels_all <- c("beginner", "intermediate", "expert")

labels <- list(
  de = list(
    course_plan = "Kursplan",
    exercise = "Übung",
    required = "Pflicht",
    optional = "Vertiefung",
    hint = "Hinweis %d von %d",
    solution = "Lösung",
    explanation = "Erklärung",
    misconception = "Typische Fehlvorstellung",
    kinds = c(
      write = "Code schreiben", interpret = "Ausgabe deuten",
      debug = "Fehler finden", complete = "Lücken füllen",
      predict = "Ergebnis vorhersagen"
    ),
    minutes = "%d Minuten",
    duration = "Dauer",
    prerequisites = "Voraussetzungen",
    none = "keine",
    packages = "Pakete",
    data = "Daten",
    goals = "Lernziele",
    planned = "geplant",
    not_offered = "nicht vorgesehen",
    status_not_started = "nicht begonnen",
    status_started = "begonnen",
    status_done = "abgeschlossen",
    topic = "Thema",
    back = "Zurück",
    next_lesson = "Weiter",
    question = "Frage %d von %d",
    check_answer = "Antwort prüfen",
    select_all = "Mehrere Antworten möglich.",
    quiz_intro = "Bestanden ab %d %% richtigen Antworten. Du kannst beliebig oft neu antworten.",
    quiz_result = "Ergebnis",
    exercise_caption = "Übung %d",
    pkg_purpose = "Wofür",
    pkg_functions = "Kernfunktionen",
    pkg_pitfalls = "Stolperfallen",
    pkg_docs = "Dokumentation",
    pkg_lessons = "In Lektionen",
    glossary_term = "Deutsch",
    glossary_other = "Englisch",
    glossary_meaning = "Bedeutung",
    glossary_lesson = "Lektion"
  ),
  en = list(
    course_plan = "Course plan",
    exercise = "Exercise",
    required = "Required",
    optional = "Optional",
    hint = "Hint %d of %d",
    solution = "Solution",
    explanation = "Explanation",
    misconception = "Common misconception",
    kinds = c(
      write = "Write code", interpret = "Interpret output",
      debug = "Find the bug", complete = "Fill the gaps",
      predict = "Predict the result"
    ),
    minutes = "%d minutes",
    duration = "Duration",
    prerequisites = "Prerequisites",
    none = "none",
    packages = "Packages",
    data = "Data",
    goals = "Learning goals",
    planned = "planned",
    not_offered = "not offered",
    status_not_started = "not started",
    status_started = "started",
    status_done = "completed",
    topic = "Topic",
    back = "Back",
    next_lesson = "Next",
    question = "Question %d of %d",
    check_answer = "Check answers",
    select_all = "Select all that apply.",
    quiz_intro = "Passed with at least %d %% correct answers. You can answer again as often as you like.",
    quiz_result = "Result",
    exercise_caption = "Exercise %d",
    pkg_purpose = "What for",
    pkg_functions = "Core functions",
    pkg_pitfalls = "Pitfalls",
    pkg_docs = "Documentation",
    pkg_lessons = "Used in lessons",
    glossary_term = "English",
    glossary_other = "German",
    glossary_meaning = "Meaning",
    glossary_lesson = "Lesson"
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x

read_yaml_file <- function(path) {
  yaml::read_yaml(path, eval.expr = FALSE)
}

lesson_id_parts <- function(lesson) {
  level <- regmatches(lesson, regexpr("[a-z]+$", lesson))
  list(slug = sub(paste0("-", level, "$"), "", lesson), level = level)
}

has_text <- function(x) is.character(x) && length(x) == 1 && nzchar(trimws(x))

# Problems with a bilingual field ({de, en}); empty if fine.
check_bilingual <- function(x, field) {
  if (!is.list(x)) {
    return(sprintf("`%s` must have `de` and `en` texts", field))
  }
  missing <- setdiff(c("de", "en"), names(Filter(has_text, x)))
  if (length(missing) > 0) {
    sprintf("`%s` lacks text for: %s", field, paste(missing, collapse = ", "))
  } else {
    character()
  }
}

regex_ok <- function(pattern) {
  !inherits(try(suppressWarnings(grepl(pattern, "", perl = TRUE)), silent = TRUE), "try-error")
}

# Validate one exercise; returns a character vector of problems.
validate_exercise <- function(ex, datasets = list(), lesson = NULL) {
  problems <- character()
  add <- function(...) problems <<- c(problems, ...)

  required_fields <- c(
    "id", "lesson", "order", "title", "kind", "required", "prompt",
    "starter", "solution", "hints", "explanation", "check"
  )
  missing <- setdiff(required_fields, names(ex))
  if (length(missing) > 0) {
    return(sprintf("missing field(s): %s", paste(missing, collapse = ", ")))
  }

  if (!grepl("^[a-z0-9]+(-[a-z0-9]+)*$", ex$id)) {
    add("`id` must be lower-case kebab-case")
  }
  if (!is.null(lesson) && !identical(ex$lesson, lesson)) {
    add(sprintf("`lesson` is `%s` but the folder belongs to `%s`", ex$lesson, lesson))
  }
  if (!ex$kind %in% kinds) {
    add(sprintf("`kind` must be one of: %s", paste(kinds, collapse = ", ")))
  }
  if (!is.logical(ex$required) || length(ex$required) != 1) {
    add("`required` must be true or false")
  }
  for (field in c("title", "prompt", "explanation")) {
    add(check_bilingual(ex[[field]], field))
  }
  for (field in c("starter", "solution")) {
    if (!has_text(ex[[field]])) add(sprintf("`%s` must be non-empty code", field))
  }
  if (identical(trimws(ex$starter), trimws(ex$solution))) {
    add("`starter` is identical to `solution`")
  }
  if (!is.list(ex$hints) || length(ex$hints) == 0) {
    add("`hints` needs at least one hint")
  } else {
    for (i in seq_along(ex$hints)) add(check_bilingual(ex$hints[[i]], sprintf("hints[%d]", i)))
  }
  if (identical(ex$kind, "debug")) {
    if (is.null(ex$misconception)) {
      add("`debug` exercises need a `misconception`")
    }
  }
  if (!is.null(ex$misconception)) add(check_bilingual(ex$misconception, "misconception"))
  if (identical(ex$kind, "complete") && !grepl("______", ex$starter, fixed = TRUE)) {
    add("`complete` exercises need gaps `______` in `starter`")
  }

  check <- ex$check
  if (!is.list(check) || !isTRUE(check$type %in% check_types)) {
    add(sprintf("`check$type` must be one of: %s", paste(check_types, collapse = ", ")))
  } else if (check$type == "object" && !has_text(check$name)) {
    add("`check` of type `object` needs `name`")
  } else if (check$type == "output" && !(has_text(check$pattern) && regex_ok(check$pattern))) {
    add("`check` of type `output` needs a valid regex `pattern`")
  }

  for (i in seq_along(ex$common_mistakes)) {
    mistake <- ex$common_mistakes[[i]]
    if (!has_text(mistake$pattern) || !regex_ok(mistake$pattern)) {
      add(sprintf("common_mistakes[%d]: `pattern` is not a valid regex", i))
    }
    add(check_bilingual(mistake$message, sprintf("common_mistakes[%d].message", i)))
  }

  unknown_data <- setdiff(unlist(ex$data), names(datasets))
  if (length(unknown_data) > 0) {
    add(sprintf("unknown dataset(s): %s", paste(unknown_data, collapse = ", ")))
  }
  problems
}

validate_quiz <- function(quiz) {
  problems <- character()
  add <- function(...) problems <<- c(problems, ...)
  if (!is.numeric(quiz$pass) || quiz$pass <= 0 || quiz$pass > 1) {
    add("`pass` must be a share between 0 and 1")
  }
  if (length(quiz$questions) == 0) add("quiz needs at least one question")
  for (i in seq_along(quiz$questions)) {
    q <- quiz$questions[[i]]
    where <- sprintf("questions[%d]", i)
    if (!has_text(q$id)) add(sprintf("%s: missing `id`", where))
    add(check_bilingual(q$prompt, paste0(where, ".prompt")))
    n_correct <- sum(vapply(q$options, function(o) isTRUE(o$correct), logical(1)))
    if (length(q$options) < 2) add(sprintf("%s: needs at least two options", where))
    if (n_correct == 0) add(sprintf("%s: no correct option", where))
    if (n_correct > 1 && !isTRUE(q$multiple)) {
      add(sprintf("%s: several correct options need `multiple: true`", where))
    }
    for (j in seq_along(q$options)) {
      o <- q$options[[j]]
      add(check_bilingual(o$text, sprintf("%s.options[%d].text", where, j)))
      add(check_bilingual(o$explain, sprintf("%s.options[%d].explain", where, j)))
    }
  }
  problems
}

# Read a lesson folder: metadata, exercises (sorted by `order`) and quiz.
read_lesson <- function(dir) {
  files <- sort(list.files(dir, pattern = "\\.ya?ml$", full.names = TRUE))
  meta_file <- file.path(dir, "lesson.yml")
  quiz_file <- file.path(dir, "quiz.yml")
  exercise_files <- setdiff(files, c(meta_file, quiz_file))
  exercises <- lapply(exercise_files, function(path) {
    ex <- read_yaml_file(path)
    ex$.path <- path
    ex
  })
  order <- vapply(exercises, function(ex) as.numeric(ex$order %||% Inf), numeric(1))
  list(
    meta = read_yaml_file(meta_file),
    exercises = exercises[order(order)],
    quiz = if (file.exists(quiz_file)) read_yaml_file(quiz_file) else NULL,
    dir = dir
  )
}

read_course <- function(root = ".") {
  lesson_dirs <- dirname(list.files(
    file.path(root, "exercises"),
    pattern = "^lesson\\.yml$", recursive = TRUE, full.names = TRUE
  ))
  lessons <- lapply(lesson_dirs, read_lesson)
  names(lessons) <- vapply(lessons, function(l) l$meta$lesson, character(1))
  list(
    root = root,
    curriculum = read_yaml_file(file.path(root, "curriculum.yml")),
    datasets = read_yaml_file(file.path(root, "data", "datasets.yml")),
    lessons = lessons
  )
}

# Front matter of a .qmd file as a list.
read_front_matter <- function(path) {
  lines <- readLines(path, warn = FALSE)
  fences <- which(lines == "---")
  if (length(fences) < 2 || fences[1] != 1) {
    return(list())
  }
  yaml::yaml.load(paste(lines[(fences[1] + 1):(fences[2] - 1)], collapse = "\n"))
}

validate_course <- function(course, langs = c("de")) {
  problems <- character()
  ids <- character()
  topics <- vapply(course$curriculum$topics, function(t) t$slug, character(1))
  for (lesson_id in names(course$lessons)) {
    lesson <- course$lessons[[lesson_id]]
    rel <- function(path) sub(paste0("^", course$root, "/?"), "", path)
    parts <- lesson_id_parts(lesson_id)
    expected_dir <- file.path("exercises", parts$slug, parts$level)
    if (!grepl(paste0(expected_dir, "$"), lesson$dir)) {
      problems <- c(problems, sprintf("%s: lesson.yml must live in %s", lesson_id, expected_dir))
    }
    if (!parts$slug %in% topics || !parts$level %in% levels_all) {
      problems <- c(problems, sprintf("%s: not a topic x level of curriculum.yml", lesson_id))
    }
    for (ex in lesson$exercises) {
      p <- validate_exercise(ex, course$datasets, lesson_id)
      problems <- c(problems, if (length(p) > 0) paste0(rel(ex$.path), ": ", p))
      ids <- c(ids, ex$id)
      extra <- setdiff(c(unlist(ex$packages), unlist(ex$data)), c(lesson$meta$packages, lesson$meta$data))
      if (length(extra) > 0) {
        problems <- c(problems, sprintf(
          "%s: packages/data not listed in lesson.yml: %s", rel(ex$.path), paste(extra, collapse = ", ")
        ))
      }
    }
    if (!is.null(lesson$quiz)) {
      p <- validate_quiz(lesson$quiz)
      problems <- c(problems, if (length(p) > 0) paste0(lesson_id, "/quiz.yml: ", p))
    }
    for (lang in langs) {
      page <- file.path(course$root, lang, paste0(lesson_id, ".qmd"))
      if (!file.exists(page)) {
        problems <- c(problems, sprintf("%s: page %s is missing", lesson_id, rel(page)))
        next
      }
      fm <- read_front_matter(page)
      if (!identical(fm$engine, "markdown")) {
        problems <- c(problems, sprintf(
          "%s: needs `engine: markdown` (otherwise Quarto tries Jupyter for {webr} blocks)", rel(page)
        ))
      }
      missing_pkgs <- setdiff(lesson$meta$packages, unlist(fm$webr$packages))
      if (length(missing_pkgs) > 0) {
        problems <- c(problems, sprintf(
          "%s: webr.packages lacks %s", rel(page), paste(missing_pkgs, collapse = ", ")
        ))
      }
      data_files <- vapply(lesson$meta$data, function(d) course$datasets[[d]]$file %||% "", character(1))
      missing_res <- data_files[!vapply(data_files, function(f) any(grepl(f, unlist(fm$resources), fixed = TRUE)), logical(1))]
      if (length(missing_res) > 0) {
        problems <- c(problems, sprintf(
          "%s: resources lacks %s", rel(page), paste(missing_res, collapse = ", ")
        ))
      }
    }
  }
  dupes <- unique(ids[duplicated(ids)])
  if (length(dupes) > 0) {
    problems <- c(problems, sprintf("duplicate exercise id(s): %s", paste(dupes, collapse = ", ")))
  }
  problems
}

# ---- Rendering helpers ------------------------------------------------------

exercise_label <- function(id) gsub("-", "_", id)

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\"", "&quot;", x, fixed = TRUE)
}

# Minimal inline Markdown for raw HTML: `code`, **bold**, *italic*.
inline_md <- function(x) {
  x <- html_escape(trimws(x))
  x <- gsub("`([^`]+)`", "<code>\\1</code>", x)
  x <- gsub("\\*\\*([^*]+)\\*\\*", "<strong>\\1</strong>", x)
  gsub("\\*([^*]+)\\*", "<em>\\1</em>", x)
}

# Paragraphs (blank-line separated) of inline Markdown as HTML.
md_html <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  paragraphs <- strsplit(trimws(x), "\n[ \t]*\n")[[1]]
  paste0("<p>", vapply(gsub("\n", " ", paragraphs), inline_md, character(1)), "</p>", collapse = "")
}

bilingual_html <- function(x) {
  if (is.null(x)) NULL else list(de = md_html(x$de), en = md_html(x$en))
}

deparse_one <- function(x) paste(deparse(x, width.cutoff = 500L), collapse = "\n")

# The R call run by quarto-live's checker (and the self-test).
check_code <- function(ex, lang) {
  spec <- ex$check
  mistakes <- lapply(ex$common_mistakes %||% list(), function(m) {
    list(pattern = m$pattern, message = m$message)
  })
  sprintf(
    "rt_check(\n  spec = %s,\n  mistakes = %s,\n  lang = \"%s\"\n)",
    deparse_one(spec), deparse_one(mistakes), lang
  )
}

data_loader <- function(data, datasets) {
  paste(vapply(unlist(data), function(d) trimws(datasets[[d]]$load), character(1)), collapse = "\n")
}

fence <- function(header, code, options = character()) {
  opts <- if (length(options) > 0) paste0("#| ", options, collapse = "\n") else NULL
  paste(c(paste0("```", header), opts, sub("\n+$", "", code), "```"), collapse = "\n")
}

lesson_url <- function(lesson_id) paste0(lesson_id, ".html")

topic_of <- function(curriculum, slug) {
  Filter(function(t) identical(t$slug, slug), curriculum$topics)[[1]]
}

level_title <- function(curriculum, level, lang) {
  Filter(function(l) identical(l$id, level), curriculum$levels)[[1]]$title[[lang]]
}

lesson_title <- function(curriculum, lesson_id, lang) {
  parts <- lesson_id_parts(lesson_id)
  topic <- topic_of(curriculum, parts$slug)
  if (is.null(topic)) lesson_id else topic$title[[lang]]
}

# ---- Generated parts --------------------------------------------------------

render_runtime <- function(lesson, datasets, checks_file = "tools/checks.R") {
  code <- c(
    "# rtrainer runtime: checks (tools/checks.R) and data",
    readLines(checks_file, warn = FALSE),
    "options(webr.exercise.checker = rt_checker)",
    data_loader(lesson$meta$data, datasets)
  )
  fence("{webr}", paste(code, collapse = "\n"), c("include: false", "autorun: true"))
}

render_exercise <- function(ex, n, lang, datasets) {
  l <- labels[[lang]]
  label <- exercise_label(ex$id)
  n_hints <- length(ex$hints)
  badge <- if (isTRUE(ex$required)) l$required else l$optional
  hints <- vapply(seq_len(n_hints), function(i) {
    sprintf(
      "::: {.hint exercise=\"%s\"}\n**%s:** %s\n:::",
      label, sprintf(l$hint, i, n_hints), trimws(ex$hints[[i]][[lang]])
    )
  }, character(1))
  misconception <- if (!is.null(ex$misconception)) {
    sprintf("\n**%s:** %s\n", l$misconception, trimws(ex$misconception[[lang]]))
  } else {
    ""
  }
  setup_code <- paste(c(data_loader(ex$data, datasets), ex$setup), collapse = "\n")

  paste(c(
    sprintf(
      "::: {#ex-%s .rt-exercise data-exercise=\"%s\" data-required=\"%s\" data-kind=\"%s\"}",
      ex$id, ex$id, tolower(isTRUE(ex$required)), ex$kind
    ),
    "",
    sprintf("### %s %d: %s {.rt-exercise-title}", l$exercise, n, trimws(ex$title[[lang]])),
    "",
    sprintf(
      "[%s]{.rt-tag .rt-tag-%s} [%s]{.rt-tag}",
      badge, if (isTRUE(ex$required)) "required" else "optional", l$kinds[[ex$kind]]
    ),
    "",
    trimws(ex$prompt[[lang]]),
    "",
    fence("{webr}", setup_code, c("setup: true", sprintf("exercise: %s", label))),
    "",
    fence("{webr}", ex$starter, c(
      sprintf("exercise: %s", label),
      sprintf("caption: \"%s\"", sprintf(l$exercise_caption, n))
    )),
    "",
    hints,
    "",
    sprintf("::: {.solution exercise=\"%s\"}", label),
    sprintf("**%s**", l$solution),
    "",
    fence("{webr}", ex$solution, c(sprintf("exercise: %s", label), "solution: true")),
    misconception,
    sprintf("**%s:** %s", l$explanation, trimws(ex$explanation[[lang]])),
    ":::",
    "",
    fence("{webr}", check_code(ex, lang), c(sprintf("exercise: %s", label), "check: true")),
    "",
    ":::"
  ), collapse = "\n")
}

render_exercises <- function(lesson, lang, datasets) {
  parts <- vapply(seq_along(lesson$exercises), function(i) {
    render_exercise(lesson$exercises[[i]], i, lang, datasets)
  }, character(1))
  paste(parts, collapse = "\n\n")
}

render_quiz <- function(quiz, lesson_id, lang) {
  l <- labels[[lang]]
  n <- length(quiz$questions)
  questions <- vapply(seq_len(n), function(i) {
    q <- quiz$questions[[i]]
    type <- if (isTRUE(q$multiple)) "checkbox" else "radio"
    options <- vapply(seq_along(q$options), function(j) {
      o <- q$options[[j]]
      input_id <- sprintf("%s-%d", q$id, j)
      sprintf(
        paste0(
          "<li class=\"rt-quiz-option\" data-correct=\"%s\">",
          "<input type=\"%s\" id=\"%s\" name=\"%s\" value=\"%d\">",
          "<label for=\"%s\">%s</label>",
          "<div class=\"rt-quiz-explain\" hidden>%s</div></li>"
        ),
        tolower(isTRUE(o$correct)), type, input_id, q$id, j,
        input_id, inline_md(o$text[[lang]]), inline_md(o$explain[[lang]])
      )
    }, character(1))
    paste0(
      sprintf("<fieldset class=\"rt-quiz-question\" data-question=\"%s\">", q$id),
      sprintf(
        "<legend><span class=\"rt-quiz-count\">%s</span> %s</legend>",
        sprintf(l$question, i, n), inline_md(q$prompt[[lang]])
      ),
      if (isTRUE(q$multiple)) sprintf("<p class=\"rt-quiz-note\">%s</p>", l$select_all) else "",
      "<ul class=\"rt-quiz-options\">", paste(options, collapse = ""), "</ul>",
      "<div class=\"rt-quiz-feedback\" role=\"status\" aria-live=\"polite\"></div>",
      "</fieldset>"
    )
  }, character(1))
  paste0(
    "```{=html}\n",
    sprintf(
      "<form class=\"rt-quiz\" data-lesson=\"%s\" data-pass=\"%s\" novalidate>\n",
      lesson_id, quiz$pass
    ),
    sprintf("<p class=\"rt-quiz-intro\">%s</p>\n", sprintf(l$quiz_intro, round(quiz$pass * 100))),
    paste(questions, collapse = "\n"),
    sprintf("\n<button type=\"submit\" class=\"btn btn-primary rt-quiz-submit\">%s</button>\n", l$check_answer),
    "<div class=\"rt-quiz-result\" role=\"status\" aria-live=\"polite\"></div>\n",
    "</form>\n```"
  )
}

render_header <- function(lesson, curriculum, course_lessons, lang) {
  l <- labels[[lang]]
  parts <- lesson_id_parts(lesson$meta$lesson)
  prereqs <- unlist(lesson$meta$prerequisites)
  prereq_html <- if (length(prereqs) == 0) {
    l$none
  } else {
    paste(vapply(prereqs, function(p) {
      title <- sprintf(
        "%s (%s)", lesson_title(curriculum, p, lang),
        level_title(curriculum, lesson_id_parts(p)$level, lang)
      )
      if (p %in% names(course_lessons)) {
        sprintf("<a href=\"%s\">%s</a>", lesson_url(p), html_escape(title))
      } else {
        sprintf("%s <span class=\"rt-muted\">(%s)</span>", html_escape(title), l$planned)
      }
    }, character(1)), collapse = ", ")
  }
  goals <- paste0("<li>", vapply(lesson$meta$goals[[lang]], inline_md, character(1)), "</li>", collapse = "")
  paste0(
    "```{=html}\n",
    sprintf("<nav class=\"rt-breadcrumb\" aria-label=\"Breadcrumb\"><ol>"),
    sprintf("<li><a href=\"index.html\">%s</a></li>", l$course_plan),
    sprintf("<li><a href=\"index.html#level-%s\">%s</a></li>", parts$level, level_title(curriculum, parts$level, lang)),
    sprintf(
      "<li><span aria-current=\"page\">%s</span></li></ol></nav>\n",
      html_escape(lesson_title(curriculum, lesson$meta$lesson, lang))
    ),
    sprintf("<div class=\"rt-lesson-meta\" data-lesson=\"%s\">", lesson$meta$lesson),
    "<dl>",
    sprintf("<div><dt>%s</dt><dd>%s</dd></div>", l$duration, sprintf(l$minutes, lesson$meta$minutes)),
    sprintf("<div><dt>%s</dt><dd>%s</dd></div>", l$prerequisites, prereq_html),
    sprintf(
      "<div><dt>%s</dt><dd>%s</dd></div>", l$packages,
      paste0("<code>", unlist(lesson$meta$packages), "</code>", collapse = ", ")
    ),
    sprintf(
      "<div><dt>%s</dt><dd>%s</dd></div>", l$data,
      paste0("<code>", unlist(lesson$meta$data), "</code>", collapse = ", ")
    ),
    "</dl>",
    sprintf("<div class=\"rt-goals\"><p class=\"rt-goals-title\">%s</p><ul>%s</ul></div>", l$goals, goals),
    "</div>\n```"
  )
}

# Lessons of a level in curriculum order.
level_sequence <- function(curriculum, level) {
  slugs <- vapply(Filter(function(t) level %in% unlist(t$levels), curriculum$topics), function(t) t$slug, character(1))
  paste0(slugs, "-", level)
}

render_footer <- function(lesson, curriculum, course_lessons, lang) {
  l <- labels[[lang]]
  parts <- lesson_id_parts(lesson$meta$lesson)
  sequence <- level_sequence(curriculum, parts$level)
  pos <- match(lesson$meta$lesson, sequence)
  link <- function(id, rel, label, arrow_first) {
    if (is.na(id)) {
      return(sprintf(
        "<a class=\"rt-pager-%s\" href=\"index.html\" rel=\"%s\"><span class=\"rt-pager-label\">%s</span><span class=\"rt-pager-title\">%s</span></a>",
        rel, rel, label, l$course_plan
      ))
    }
    title <- html_escape(lesson_title(curriculum, id, lang))
    if (id %in% names(course_lessons)) {
      sprintf(
        "<a class=\"rt-pager-%s\" href=\"%s\" rel=\"%s\"><span class=\"rt-pager-label\">%s</span><span class=\"rt-pager-title\">%s</span></a>",
        rel, lesson_url(id), rel, label, title
      )
    } else {
      sprintf(
        "<span class=\"rt-pager-%s rt-pager-disabled\" aria-disabled=\"true\"><span class=\"rt-pager-label\">%s</span><span class=\"rt-pager-title\">%s <span class=\"rt-muted\">(%s)</span></span></span>",
        rel, label, title, l$planned
      )
    }
  }
  prev_id <- if (pos > 1) sequence[pos - 1] else NA
  next_id <- if (pos < length(sequence)) sequence[pos + 1] else NA
  paste0(
    "```{=html}\n<nav class=\"rt-pager\" aria-label=\"", l$back, " / ", l$next_lesson, "\">",
    link(prev_id, "prev", paste("&larr;", l$back), TRUE),
    link(next_id, "next", paste(l$next_lesson, "&rarr;"), FALSE),
    "</nav>\n```"
  )
}

render_course_plan <- function(curriculum, course_lessons, lang) {
  l <- labels[[lang]]
  level_ids <- vapply(curriculum$levels, function(x) x$id, character(1))
  header <- paste0(
    sprintf("<th scope=\"col\">%s</th>", l$topic),
    paste0(sprintf(
      "<th scope=\"col\" id=\"level-%s\">%s</th>",
      level_ids, vapply(level_ids, level_title, character(1), curriculum = curriculum, lang = lang)
    ), collapse = "")
  )
  rows <- vapply(seq_along(curriculum$topics), function(i) {
    topic <- curriculum$topics[[i]]
    cells <- vapply(level_ids, function(level) {
      lesson_id <- paste0(topic$slug, "-", level)
      if (!level %in% unlist(topic$levels)) {
        return(sprintf("<td class=\"rt-cell rt-cell-none\"><span class=\"visually-hidden\">%s</span></td>", l$not_offered))
      }
      if (!lesson_id %in% names(course_lessons)) {
        return(sprintf("<td class=\"rt-cell rt-cell-planned\"><span class=\"rt-status-text\">%s</span></td>", l$planned))
      }
      sprintf(
        paste0(
          "<td class=\"rt-cell rt-cell-active\" data-lesson=\"%s\">",
          "<a href=\"%s\"><span class=\"rt-status\" data-status=\"not-started\">",
          "<span class=\"rt-status-icon\" aria-hidden=\"true\"></span>",
          "<span class=\"rt-status-text\">%s</span></span>",
          "<span class=\"rt-due\" hidden></span>",
          "<span class=\"visually-hidden\"> – %s, %s</span></a></td>"
        ),
        lesson_id, lesson_url(lesson_id), l$status_not_started,
        html_escape(topic$title[[lang]]), level_title(curriculum, level, lang)
      )
    }, character(1))
    sprintf(
      "<tr><th scope=\"row\"><span class=\"rt-topic-no\">%d</span> %s</th>%s</tr>",
      i, html_escape(topic$title[[lang]]), paste(cells, collapse = "")
    )
  }, character(1))

  # Recommended path: level by level, topics in curriculum order.
  order <- unlist(lapply(level_ids, level_sequence, curriculum = curriculum))
  order <- order[order %in% names(course_lessons)]
  course_json <- jsonlite::toJSON(list(
    order = I(order),
    lessons = lapply(course_lessons, function(lesson) {
      id <- lesson$meta$lesson
      list(
        title = sprintf(
          "%s (%s)", lesson_title(curriculum, id, lang),
          level_title(curriculum, lesson_id_parts(id)$level, lang)
        ),
        required = I(vapply(Filter(function(ex) isTRUE(ex$required), lesson$exercises), function(ex) ex$id, character(1))),
        exercises = I(vapply(lesson$exercises, function(ex) ex$id, character(1)))
      )
    })
  ), auto_unbox = TRUE)

  paste0(
    "```{=html}\n<div class=\"rt-plan-wrap\"><table class=\"rt-plan\">",
    "<thead><tr>", header, "</tr></thead><tbody>",
    paste(rows, collapse = ""),
    "</tbody></table></div>\n",
    "<script type=\"application/json\" id=\"rt-course\">", course_json, "</script>\n```"
  )
}

review_cards <- function(course, checks_file) {
  cards <- list()
  for (lesson in course$lessons) {
    parts <- lesson_id_parts(lesson$meta$lesson)
    lesson_titles <- lapply(c(de = "de", en = "en"), function(lang) {
      sprintf(
        "%s (%s)", lesson_title(course$curriculum, lesson$meta$lesson, lang),
        level_title(course$curriculum, parts$level, lang)
      )
    })
    for (ex in lesson$exercises) {
      cards[[ex$id]] <- list(
        id = ex$id,
        lesson = ex$lesson,
        lesson_title = lesson_titles,
        kind = ex$kind,
        kind_label = list(de = labels$de$kinds[[ex$kind]], en = labels$en$kinds[[ex$kind]]),
        required = isTRUE(ex$required),
        title = ex$title,
        prompt = bilingual_html(ex$prompt),
        packages = I(as.character(unlist(ex$packages))),
        data = I(as.character(unlist(ex$data))),
        setup = paste(c(data_loader(ex$data, course$datasets), ex$setup), collapse = "\n"),
        starter = ex$starter,
        solution = ex$solution,
        hints = lapply(ex$hints, bilingual_html),
        explanation = bilingual_html(ex$explanation),
        misconception = bilingual_html(ex$misconception),
        check = list(de = check_code(ex, "de"), en = check_code(ex, "en"))
      )
    }
  }
  list(
    version = 1,
    checks = paste(readLines(checks_file, warn = FALSE), collapse = "\n"),
    datasets = lapply(course$datasets, function(d) list(file = d$file, load = d$load)),
    cards = cards
  )
}

# ---- Package profiles and glossary ------------------------------------------

read_packages <- function(root) {
  files <- sort(list.files(file.path(root, "content", "packages"), pattern = "\\.ya?ml$", full.names = TRUE))
  lapply(files, read_yaml_file)
}

read_glossary <- function(root) {
  path <- file.path(root, "content", "glossary.yml")
  if (file.exists(path)) read_yaml_file(path)$terms else list()
}

validate_package <- function(pkg) {
  problems <- character()
  add <- function(...) problems <<- c(problems, ...)
  if (!has_text(pkg$name)) add("missing `name`")
  if (!has_text(pkg$url)) add("missing `url`")
  add(check_bilingual(pkg$purpose, "purpose"))
  if (length(pkg$functions) == 0) add("needs at least one entry in `functions`")
  for (i in seq_along(pkg$functions)) {
    f <- pkg$functions[[i]]
    if (!has_text(f$name)) add(sprintf("functions[%d]: missing `name`", i))
    add(check_bilingual(f$does, sprintf("functions[%d].does", i)))
  }
  for (i in seq_along(pkg$pitfalls)) add(check_bilingual(pkg$pitfalls[[i]], sprintf("pitfalls[%d]", i)))
  problems
}

validate_glossary <- function(terms) {
  problems <- character()
  for (i in seq_along(terms)) {
    term <- terms[[i]]
    where <- sprintf("terms[%d]", i)
    for (field in c("de", "en")) {
      if (!has_text(term[[field]])) problems <- c(problems, sprintf("%s: missing `%s`", where, field))
    }
    problems <- c(problems, check_bilingual(term$meaning, paste0(where, ".meaning")))
  }
  keys <- vapply(terms, function(t) tolower(t$en %||% ""), character(1))
  dupes <- unique(keys[duplicated(keys)])
  if (length(dupes) > 0) problems <- c(problems, sprintf("duplicate term(s): %s", paste(dupes, collapse = ", ")))
  problems
}

lesson_links <- function(lessons, curriculum, course_lessons, lang) {
  lessons <- unlist(lessons)
  if (length(lessons) == 0) {
    return(labels[[lang]]$none)
  }
  paste(vapply(lessons, function(id) {
    title <- sprintf(
      "%s (%s)", lesson_title(curriculum, id, lang),
      level_title(curriculum, lesson_id_parts(id)$level, lang)
    )
    if (id %in% names(course_lessons)) sprintf("[%s](%s)", title, lesson_url(id)) else title
  }, character(1)), collapse = ", ")
}

render_packages <- function(packages, curriculum, course_lessons, lang) {
  l <- labels[[lang]]
  if (length(packages) == 0) {
    return("")
  }
  overview <- c(
    sprintf("| | %s |", l$pkg_purpose),
    "|---|---|",
    vapply(packages, function(p) {
      sprintf("| [%s](#pkg-%s) | %s |", p$name, p$name, gsub("\n", " ", trimws(p$purpose[[lang]])))
    }, character(1))
  )
  profiles <- vapply(packages, function(p) {
    functions <- vapply(p$functions, function(f) {
      example <- if (has_text(f$example)) paste0("\n\n", fence("r", f$example)) else ""
      sprintf("`%s`\n: %s%s", f$name, trimws(f$does[[lang]]), gsub("\n", "\n    ", example))
    }, character(1))
    pitfalls <- vapply(p$pitfalls %||% list(), function(x) paste0("- ", trimws(x[[lang]])), character(1))
    paste(c(
      sprintf("## %s {#pkg-%s .rt-package}", p$name, p$name),
      "",
      trimws(p$purpose[[lang]]),
      "",
      sprintf(
        "**%s:** <%s> · **%s:** %s",
        l$pkg_docs, p$url, l$pkg_lessons, lesson_links(p$lessons, curriculum, course_lessons, lang)
      ),
      "",
      sprintf("### %s", l$pkg_functions),
      "",
      paste(functions, collapse = "\n\n"),
      "",
      if (length(pitfalls) > 0) c(sprintf("### %s", l$pkg_pitfalls), "", pitfalls) else NULL
    ), collapse = "\n")
  }, character(1))
  paste(c(paste(overview, collapse = "\n"), profiles), collapse = "\n\n")
}

render_glossary <- function(terms, curriculum, course_lessons, lang) {
  l <- labels[[lang]]
  other <- if (lang == "de") "en" else "de"
  terms <- terms[order(tolower(vapply(terms, function(t) t[[lang]], character(1))))]
  rows <- vapply(terms, function(t) {
    sprintf(
      "| **%s** | %s | %s | %s |",
      t[[lang]], t[[other]], gsub("\n", " ", trimws(t$meaning[[lang]])),
      lesson_links(t$lessons, curriculum, course_lessons, lang)
    )
  }, character(1))
  paste(c(
    sprintf("| %s | %s | %s | %s |", l$glossary_term, l$glossary_other, l$glossary_meaning, l$glossary_lesson),
    "|---|---|---|---|",
    rows
  ), collapse = "\n")
}

write_file <- function(text, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(text, path, useBytes = TRUE)
  invisible(path)
}

generate <- function(root = ".", out = file.path(root, "_generated"), langs = c("de", "en")) {
  course <- read_course(root)
  packages <- read_packages(root)
  glossary <- read_glossary(root)
  package_problems <- unlist(lapply(packages, function(p) {
    found <- validate_package(p)
    if (length(found) > 0) paste0("content/packages/", p$name %||% "?", ".yml: ", found)
  }))
  glossary_problems <- validate_glossary(glossary)
  problems <- c(
    validate_course(course, langs),
    package_problems,
    if (length(glossary_problems) > 0) paste0("content/glossary.yml: ", glossary_problems)
  )
  if (length(problems) > 0) {
    stop("Invalid course content:\n", paste0("- ", problems, collapse = "\n"), call. = FALSE)
  }
  unlink(out, recursive = TRUE)
  written <- character()
  for (lang in langs) {
    for (lesson in course$lessons) {
      dir <- file.path(out, lang, lesson$meta$lesson)
      written <- c(
        written,
        write_file(render_runtime(lesson, course$datasets, file.path(root, "tools", "checks.R")), file.path(dir, "runtime.qmd")),
        write_file(render_header(lesson, course$curriculum, course$lessons, lang), file.path(dir, "header.qmd")),
        write_file(render_exercises(lesson, lang, course$datasets), file.path(dir, "exercises.qmd")),
        write_file(render_footer(lesson, course$curriculum, course$lessons, lang), file.path(dir, "footer.qmd"))
      )
      if (!is.null(lesson$quiz)) {
        written <- c(written, write_file(render_quiz(lesson$quiz, lesson$meta$lesson, lang), file.path(dir, "quiz.qmd")))
      }
    }
    written <- c(
      written,
      write_file(render_course_plan(course$curriculum, course$lessons, lang), file.path(out, lang, "course-plan.qmd")),
      write_file(render_packages(packages, course$curriculum, course$lessons, lang), file.path(out, lang, "packages.qmd")),
      write_file(render_glossary(glossary, course$curriculum, course$lessons, lang), file.path(out, lang, "glossary.qmd"))
    )
  }
  cards_path <- file.path(root, "assets", "review-cards.json")
  dir.create(dirname(cards_path), showWarnings = FALSE)
  jsonlite::write_json(
    review_cards(course, file.path(root, "tools", "checks.R")),
    cards_path,
    auto_unbox = TRUE, pretty = TRUE, null = "null"
  )
  invisible(c(written, cards_path))
}

if (sys.nframe() == 0L) {
  files <- generate(".")
  n_ex <- length(jsonlite::read_json("assets/review-cards.json")$cards)
  cat(sprintf("Generated %d files, %d exercises.\n", length(files), n_ex))
}
