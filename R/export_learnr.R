#' Export exercises as learnr tutorials
#'
#' Writes one learnr `.Rmd` per topic with prompt, setup chunk, exercise
#' chunk (starter code), hints, solution and a gradethis check. Checks of
#' type `value`, `object` and `output` are translated; other check types
#' (`function`, `regex`, `ast`, `plot`) and additional rules (`forbid`,
#' `require`, `post`) get a visible note instead. learnr and gradethis are
#' only needed to render the tutorials, not to export them.
#'
#' @param topics Topics to export (default: all).
#' @param path Target directory (created if missing).
#' @param exercises Named list of exercises (default: all loaded exercises).
#' @param overwrite Overwrite existing files?
#' @return Paths of the written `.Rmd` files (invisibly).
#' @export
#' @examples
#' \dontrun{
#' export_learnr("dplyr", "tutorials")
#' rmarkdown::run("tutorials/dplyr.Rmd")
#' }
export_learnr <- function(topics = NULL, path = ".", exercises = load_exercises(),
                          overwrite = FALSE) {
  all_topics <- unique(vapply(exercises, `[[`, "", "topic"))
  topics <- topics %||% all_topics
  unknown <- setdiff(topics, all_topics)
  if (length(unknown)) {
    cli::cli_abort(c(
      "Unbekannte Themen: {.val {unknown}}",
      i = "Vorhandene Themen: {.val {all_topics}}"
    ))
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  files <- file.path(path, paste0(gsub("[^A-Za-z0-9_-]", "_", topics), ".Rmd"))
  if (!overwrite && any(file.exists(files))) {
    cli::cli_abort("Datei existiert bereits: {.file {files[file.exists(files)]}} (`overwrite = TRUE`?)")
  }
  for (i in seq_along(topics)) {
    exs <- Filter(function(ex) identical(ex$topic, topics[[i]]), exercises)
    writeLines(learnr_rmd(topics[[i]], exs), files[[i]], useBytes = TRUE)
  }
  cli::cli_alert_success("{length(files)} Tutorial{?s} geschrieben: {.file {files}}")
  invisible(files)
}

learnr_rmd <- function(topic, exercises) {
  c(
    "---",
    sprintf("title: %s", yaml_quote(paste("rtrainer:", topic))),
    "output: learnr::tutorial",
    "runtime: shiny_prerendered",
    "---",
    "",
    "```{r setup, include = FALSE}",
    learnr_global_setup(),
    "```",
    "",
    unlist(lapply(exercises, learnr_exercise))
  )
}

yaml_quote <- function(x) sprintf("\"%s\"", gsub("([\"\\\\])", "\\\\\\1", x))

# Helpers mirror the rtrainer check engine (compare_values(), check_output())
learnr_global_setup <- function() {
  c(
    "library(learnr)",
    "library(gradethis)",
    "gradethis::gradethis_setup()",
    "rtrainer_data <- function(name) {",
    "  f <- system.file(\"extdata\", name, package = \"rtrainer\")",
    "  if (!nzchar(f)) stop(\"Datei nicht gefunden: \", name, call. = FALSE)",
    "  f",
    "}",
    "rt_equal <- function(x, y, tolerance = 1.5e-8, ignore_row_order = FALSE,",
    "                     ignore_col_order = FALSE, ignore_attributes = FALSE) {",
    "  if (is.data.frame(x) && is.data.frame(y)) {",
    "    x <- as.data.frame(x)",
    "    y <- as.data.frame(y)",
    "    if (ignore_col_order && setequal(names(x), names(y))) x <- x[names(y)]",
    "    if (ignore_row_order && identical(names(x), names(y))) {",
    "      x <- x[do.call(order, unname(x)), , drop = FALSE]",
    "      y <- y[do.call(order, unname(y)), , drop = FALSE]",
    "    }",
    "    rownames(x) <- rownames(y) <- NULL",
    "  } else if (is.numeric(x) && is.numeric(y)) {",
    "    x <- unname(c(x))",
    "    y <- unname(c(y))",
    "  }",
    "  isTRUE(all.equal(x, y, tolerance = tolerance, check.attributes = !ignore_attributes))",
    "}",
    "rt_output <- function(code, env, seed = 1) {",
    "  set.seed(seed)",
    "  out <- utils::capture.output(source(exprs = parse(text = code),",
    "    local = new.env(parent = env), echo = FALSE, print.eval = TRUE))",
    "  trimws(gsub(\"[[:space:]]+\", \" \", paste(out, collapse = \"\\n\")))",
    "}"
  )
}

kind_labels <- c(write = "Schreiben", predict = "Vorhersagen", debug = "Reparieren",
                 complete = "Erg\u00e4nzen")

learnr_exercise <- function(ex) {
  id <- ex$id
  setup <- c(
    if (length(ex$packages)) sprintf("library(%s)", ex$packages),
    sprintf("set.seed(%s)", ex$seed),
    if (nzchar(ex$setup)) ex$setup
  )
  hints <- unlist(lapply(seq_along(ex$hints), function(i) {
    learnr_chunk(sprintf("%s-hint-%d", id, i), paste("#", split_lines(ex$hints[[i]])))
  }))
  grader <- learnr_check(ex)
  notes <- learnr_notes(ex, has_check = !is.null(grader))
  c(
    sprintf("## %s", ex$title),
    "",
    sprintf("*%s \u00b7 Level %s*", kind_labels[[ex$kind]], ex$level),
    "",
    escape_knitr_md(split_lines(ex$prompt)),
    "",
    if (length(notes)) c(paste(">", notes), ""),
    learnr_chunk(paste0(id, "-setup"), setup),
    learnr_chunk(id, if (nzchar(ex$starter)) ex$starter else "",
                 sprintf("exercise = TRUE, exercise.timelimit = %s", ex$timeout)),
    hints,
    learnr_chunk(paste0(id, "-solution"), ex$solution),
    if (!is.null(grader)) learnr_chunk(paste0(id, "-check"), grader),
    if (nzchar(ex$explanation)) {
      c("<details><summary>Erkl\u00e4rung</summary>", "",
        escape_knitr_md(split_lines(ex$explanation)), "", "</details>", "")
    }
  )
}

learnr_chunk <- function(label, code, options = NULL) {
  code <- split_lines(code)
  fence <- grepl(knitr_patterns$begin, code) | grepl(knitr_patterns$end, code)
  if (any(fence)) {
    cli::cli_abort("Chunk {.val {label}} enth\u00e4lt eine Zeile, die knitr als Chunk-Grenze liest: {.code {code[fence][1]}}")
  }
  header <- if (is.null(options)) label else paste0(label, ", ", options)
  c(sprintf("```{r %s}", header), code, "```", "")
}

# knitr's own markdown patterns (all_patterns$md), copied to avoid a dependency
knitr_patterns <- list(
  begin = "^[\t >]*```+\\s*\\{([a-zA-Z0-9_]+( *[ ,].*)?)\\}\\s*$",
  end = "^[\t >]*```+\\s*$",
  inline = "`r[ #]([^`]+)\\s*`"
)

# Markdown that shows Rmd source (e.g. in prompts) must not be run by knitr:
# chunk headers get the documented `r ''` prefix, inline code is emitted
# literally through an inline expression.
escape_knitr_md <- function(x) {
  m <- gregexpr(knitr_patterns$inline, x, perl = TRUE)
  regmatches(x, m) <- lapply(regmatches(x, m), function(hits) {
    if (!length(hits)) return(hits)
    lit <- gsub("`", "\\\\x60", gsub("'", "\\\\'", gsub("\\\\", "\\\\\\\\", hits)))
    sprintf("`r '%s'`", lit)
  })
  chunk <- grepl(knitr_patterns$begin, x)
  x[chunk] <- paste0("`r ''`", x[chunk])
  x
}

split_lines <- function(x) {
  x <- unlist(strsplit(paste(x, collapse = "\n"), "\n", fixed = TRUE))
  if (length(x) && !nzchar(x[length(x)])) x <- x[-length(x)]
  x
}

learnr_check <- function(ex) {
  chk <- ex$check
  tol <- chk$tolerance %||% 1.5e-8
  eq_args <- sprintf(
    "tolerance = %s, ignore_row_order = %s, ignore_col_order = %s, ignore_attributes = %s",
    format(tol), isTRUE(chk$ignore_row_order), isTRUE(chk$ignore_col_order),
    isTRUE(chk$ignore_attributes)
  )
  body <- switch(chk$type,
    value = c(
      sprintf("  if (rt_equal(.result, .solution, %s)) pass(\"Richtig!\")", eq_args),
      "  fail(\"Das Ergebnis weicht von der Musterl\u00f6sung ab.\")"
    ),
    output = c(
      sprintf("  if (identical(rt_output(.user_code, .envir_prep, %s),", ex$seed),
      sprintf("                rt_output(.solution_code, .envir_prep, %s))) {", ex$seed),
      "    pass(\"Richtig!\")",
      "  }",
      "  fail(\"Die Ausgabe weicht von der Musterl\u00f6sung ab.\")"
    ),
    object = learnr_check_object(chk, eq_args),
    NULL
  )
  if (is.null(body)) return(NULL)
  c("grade_this({", body, "})")
}

learnr_check_object <- function(chk, eq_args) {
  nm <- deparse(chk$name)
  c(
    # gradethis evaluates the solution lazily; .envir_solution is filled afterwards
    "  invisible(.solution)",
    sprintf("  if (!exists(%s, envir = .envir_result, inherits = FALSE)) {", nm),
    sprintf("    fail(\"Das Objekt `%s` existiert nicht.\")", chk$name),
    "  }",
    sprintf("  obj <- get(%s, envir = .envir_result)", nm),
    if (!is.null(chk$class)) {
      sprintf("  if (!inherits(obj, %s)) fail(\"`%s` hat nicht die Klasse %s.\")",
              deparse(chk$class), chk$name, chk$class)
    },
    if (isTRUE(chk$compare_value)) {
      c(sprintf("  if (!rt_equal(obj, get(%s, envir = .envir_solution), %s)) {", nm, eq_args),
        sprintf("    fail(\"`%s` weicht von der Musterl\u00f6sung ab.\")", chk$name),
        "  }")
    },
    "  pass(\"Richtig!\")"
  )
}

learnr_notes <- function(ex, has_check) {
  chk <- ex$check
  c(
    if (!has_check) {
      sprintf("**Hinweis:** Der Check-Typ `%s` wird in learnr nicht automatisch gepr\u00fcft. Vergleiche dein Ergebnis mit der L\u00f6sung.", chk$type)
    },
    if (length(chk$forbid)) {
      sprintf("**Hinweis:** Nicht verwenden: %s (wird hier nicht gepr\u00fcft).",
              paste0("`", unlist(chk$forbid), "`", collapse = ", "))
    },
    if (length(chk$require)) {
      sprintf("**Hinweis:** Verwende: %s (wird hier nicht gepr\u00fcft).",
              paste0("`", unlist(chk$require), "`", collapse = ", "))
    },
    if (!is.null(chk$post)) {
      "**Hinweis:** rtrainer pr\u00fcft zus\u00e4tzlich eine Nachbedingung, die hier fehlt."
    }
  )
}
