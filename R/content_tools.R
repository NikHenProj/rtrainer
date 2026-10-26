#' Self-test: every solution must pass, every starter must fail
#'
#' @param exercises Named list (default: all loaded exercises).
#' @param verbose Print progress with cli.
#' @return Data frame with one row per exercise.
#' @export
check_all_solutions <- function(exercises = load_exercises(), verbose = interactive()) {
  rows <- lapply(exercises, function(ex) {
    t0 <- Sys.time()
    sol <- tryCatch(check_exercise(ex, ex$solution),
                    error = function(e) list(correct = FALSE, message = conditionMessage(e)))
    st_ok <- if (nzchar(trimws(ex$starter))) {
      !isTRUE(tryCatch(check_exercise(ex, ex$starter)$correct, error = function(e) FALSE))
    } else NA
    res <- data.frame(id = ex$id, solution_ok = sol$correct, starter_fails = st_ok,
                      secs = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 2),
                      message = if (sol$correct) "" else sol$message)
    if (verbose) {
      if (isTRUE(res$solution_ok) && !isFALSE(res$starter_fails)) cli::cli_alert_success("{ex$id}")
      else cli::cli_alert_danger("{ex$id}: {res$message}")
    }
    res
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Create an exercise template
#'
#' @param topic Topic name, also used as subdirectory.
#' @param id Exercise id (`[a-z0-9_-]`).
#' @param dir Target base directory (default: current directory).
#' @return Path to the file (invisibly).
#' @export
new_exercise <- function(topic, id, dir = ".") {
  stopifnot(is.character(topic), is.character(id))
  target <- file.path(dir, topic)
  dir.create(target, recursive = TRUE, showWarnings = FALSE)
  f <- file.path(target, paste0(id, ".yml"))
  if (file.exists(f)) cli::cli_abort("Datei existiert bereits: {.file {f}}")
  tpl <- c(
    sprintf("id: %s", id),
    sprintf("topic: %s", topic),
    "title: Titel der Aufgabe",
    "level: 1                  # 1 = leicht, 2 = mittel, 3 = schwer",
    "kind: write               # write | predict | debug | complete",
    sprintf("tags: [%s]", topic),
    "packages: []              # z. B. [dplyr]",
    "seed: 1                   # f\u00fcr deterministische Auswertung",
    "prompt: |",
    "  Aufgabentext in Markdown.",
    "setup: |",
    "  # wird vor dem Nutzercode ausgef\u00fchrt (library(), Daten laden)",
    "starter: |",
    "  # dein Code",
    "solution: |",
    "  1 + 1",
    "hints:",
    "  - \"Hinweis 1 (grob)\"",
    "  - \"Hinweis 2 (konkret)\"",
    "explanation: |",
    "  Erkl\u00e4rung, die nach der L\u00f6sung angezeigt wird.",
    "misconception: \"\"         # h\u00e4ufige Fehlvorstellung hinter dem typischen Fehler",
    "check:",
    "  type: value              # value | output | object | function | regex | ast | plot",
    "  tolerance: 1.0e-8",
    "common_mistakes: []",
    "# - pattern: \"regex\"",
    "#   message: \"Gezielter Hinweis (erkl\u00e4rt, WARUM es falsch ist)\""
  )
  writeLines(tpl, f, useBytes = TRUE)
  cli::cli_alert_success("Vorlage erstellt: {.file {f}}")
  invisible(f)
}
