# Exercise checks for rtrainer.
#
# This file runs in two places: in the browser (webR, inlined into every
# lesson by tools/generate.R) and in normal R (tools/selftest.R). Keep it
# base R only.
#
# quarto-live calls getOption("webr.exercise.checker") with the user's code,
# result and environments; rt_checker() evaluates the exercise's check code
# (a call to rt_check(), written by the generator) with these values bound to
# `.result`, `.solution`, `.user_code`, `.envir_result` and `.envir_solution`.

rt_messages <- list(
  de = list(
    correct = "Richtig!",
    no_result = "Dein Code liefert noch kein Ergebnis. Läuft er ohne Fehler, und steht das Ergebnis in der letzten Zeile?",
    class = "Das Ergebnis hat den falschen Typ: erwartet %s, erhalten %s.",
    columns = "Die Spalten stimmen nicht: erwartet %s, erhalten %s.",
    col_order = "Die Spalten stehen in einer anderen Reihenfolge: erwartet %s.",
    rows = "Die Anzahl der Zeilen stimmt nicht: erwartet %d, erhalten %d.",
    column_values = "Die Werte in Spalte `%s` stimmen noch nicht.",
    length = "Die Länge stimmt nicht: erwartet %d, erhalten %d.",
    values = "Die Werte stimmen noch nicht.",
    htest = "Der Test liefert andere Werte (%s) als erwartet. Prüfe Variablen, Daten und Optionen.",
    htest_df = "Die Freiheitsgrade stimmen nicht: erwartet etwa %s, erhalten %s. Wie viele unabhängige Beobachtungen gehen in den Test ein?",
    missing_object = "Das Objekt `%s` fehlt. Hast du es mit `<-` gespeichert?",
    output = "Die Ausgabe enthält noch nicht das Erwartete.",
    check_error = "Beim Prüfen ist ein Fehler aufgetreten: %s"
  ),
  en = list(
    correct = "Correct!",
    no_result = "Your code does not return a result yet. Does it run without errors, and is the result on the last line?",
    class = "The result has the wrong type: expected %s, got %s.",
    columns = "The columns do not match: expected %s, got %s.",
    col_order = "The columns are in a different order: expected %s.",
    rows = "The number of rows does not match: expected %d, got %d.",
    column_values = "The values in column `%s` are not right yet.",
    length = "The length does not match: expected %d, got %d.",
    values = "The values are not right yet.",
    htest = "The test returns different values (%s) than expected. Check variables, data and options.",
    htest_df = "The degrees of freedom do not match: expected about %s, got %s. How many independent observations enter the test?",
    missing_object = "The object `%s` is missing. Did you save it with `<-`?",
    output = "The output does not contain what was expected yet.",
    check_error = "An error occurred while checking: %s"
  )
)

rt_msg <- function(key, lang = "de", ...) {
  template <- rt_messages[[lang]][[key]]
  if (length(list(...)) == 0) template else sprintf(template, ...)
}

rt_feedback <- function(correct, message) {
  list(
    correct = correct,
    type = if (correct) "success" else "error",
    message = message
  )
}

rt_collapse <- function(x) paste0("`", x, "`", collapse = ", ")

rt_num_equal <- function(x, y, tolerance) {
  isTRUE(all.equal(x, y, tolerance = tolerance, check.attributes = FALSE))
}

rt_plain_df <- function(x) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  for (col in names(x)) {
    if (is.factor(x[[col]])) x[[col]] <- as.character(x[[col]])
  }
  rownames(x) <- NULL
  x
}

rt_sort_rows <- function(x) {
  if (ncol(x) == 0 || nrow(x) < 2) {
    return(x)
  }
  x[do.call(order, unname(as.list(x))), , drop = FALSE]
}

# Compare a result with the expected value.
# Returns NULL when they match, otherwise a feedback message.
rt_compare <- function(result, expected, tolerance = 1e-6,
                       ignore_row_order = FALSE, ignore_col_order = TRUE,
                       lang = "de") {
  if (is.null(result)) {
    return(rt_msg("no_result", lang))
  }

  if (inherits(expected, "htest")) {
    if (!inherits(result, "htest")) {
      return(rt_msg("class", lang, "htest", class(result)[1]))
    }
    fields <- c("statistic", "parameter", "p.value")
    differs <- vapply(fields, function(field) {
      !rt_num_equal(result[[field]], expected[[field]], tolerance)
    }, logical(1))
    if (differs[["parameter"]] && length(expected$parameter) == 1 &&
      length(result$parameter) == 1) {
      return(rt_msg(
        "htest_df", lang,
        format(round(expected$parameter, 1)), format(round(result$parameter, 1))
      ))
    }
    if (any(differs)) {
      return(rt_msg("htest", lang, paste(fields[differs], collapse = ", ")))
    }
    return(NULL)
  }

  if (is.data.frame(expected)) {
    if (!is.data.frame(result)) {
      return(rt_msg("class", lang, "data frame", class(result)[1]))
    }
    result <- rt_plain_df(result)
    expected <- rt_plain_df(expected)
    if (!setequal(names(result), names(expected))) {
      return(rt_msg(
        "columns", lang, rt_collapse(names(expected)), rt_collapse(names(result))
      ))
    }
    if (!ignore_col_order && !identical(names(result), names(expected))) {
      return(rt_msg("col_order", lang, rt_collapse(names(expected))))
    }
    result <- result[names(expected)]
    if (nrow(result) != nrow(expected)) {
      return(rt_msg("rows", lang, nrow(expected), nrow(result)))
    }
    if (ignore_row_order) {
      result <- rt_sort_rows(result)
      expected <- rt_sort_rows(expected)
    }
    for (col in names(expected)) {
      same <- if (is.numeric(expected[[col]]) && is.numeric(result[[col]])) {
        rt_num_equal(result[[col]], expected[[col]], tolerance)
      } else {
        identical(as.character(result[[col]]), as.character(expected[[col]]))
      }
      if (!same) {
        return(rt_msg("column_values", lang, col))
      }
    }
    return(NULL)
  }

  if (is.numeric(expected)) {
    if (!is.numeric(result)) {
      return(rt_msg("class", lang, class(expected)[1], class(result)[1]))
    }
    if (length(result) != length(expected)) {
      return(rt_msg("length", lang, length(expected), length(result)))
    }
    if (!rt_num_equal(result, expected, tolerance)) {
      return(rt_msg("values", lang))
    }
    return(NULL)
  }

  if (!isTRUE(all.equal(result, expected, check.attributes = FALSE))) {
    return(rt_msg("values", lang))
  }
  NULL
}

# First matching common mistake (regex on the user's code), or NULL.
rt_match_mistake <- function(user_code, mistakes, lang = "de") {
  for (mistake in mistakes) {
    if (grepl(mistake$pattern, user_code, perl = TRUE)) {
      return(mistake$message[[lang]])
    }
  }
  NULL
}

# Check the current attempt. `spec` is the exercise's `check` field:
# type = "value" (last value vs. solution), "object" (object `name` in the
# user's environment vs. the solution's) or "output" (printed output matches
# regex `pattern`).
rt_check <- function(spec, mistakes = list(), lang = "de", env = parent.frame()) {
  problem <- tryCatch(
    switch(spec$type,
      value = rt_compare(
        get0(".result", env),
        get0(".solution", env),
        tolerance = spec$tolerance %||% 1e-6,
        ignore_row_order = isTRUE(spec$ignore_row_order),
        ignore_col_order = !isFALSE(spec$ignore_col_order),
        lang = lang
      ),
      object = {
        user_env <- get0(".envir_result", env)
        if (is.null(user_env) || !exists(spec$name, envir = user_env)) {
          rt_msg("missing_object", lang, spec$name)
        } else {
          rt_compare(
            get(spec$name, envir = user_env),
            get(spec$name, envir = get0(".envir_solution", env)),
            tolerance = spec$tolerance %||% 1e-6,
            ignore_row_order = isTRUE(spec$ignore_row_order),
            ignore_col_order = !isFALSE(spec$ignore_col_order),
            lang = lang
          )
        }
      },
      output = {
        printed <- paste(utils::capture.output(print(get0(".result", env))), collapse = "\n")
        if (grepl(spec$pattern, printed, perl = TRUE)) NULL else rt_msg("output", lang)
      },
      stop("Unknown check type: ", spec$type)
    ),
    error = function(e) rt_msg("check_error", lang, conditionMessage(e))
  )

  if (is.null(problem)) {
    return(rt_feedback(TRUE, rt_msg("correct", lang)))
  }
  mistake <- rt_match_mistake(get0(".user_code", env) %||% "", mistakes, lang)
  rt_feedback(FALSE, mistake %||% problem)
}

# Checker for quarto-live: options(webr.exercise.checker = rt_checker)
rt_checker <- function(label, user_code, check_code, envir_result, last_value,
                       solution = NULL, envir_solution = NULL, ...) {
  if (is.null(check_code)) {
    return(invisible(NULL))
  }
  check_env <- new.env(parent = globalenv())
  check_env$.result <- last_value
  check_env$.solution <- solution
  check_env$.user_code <- user_code
  check_env$.envir_result <- envir_result
  check_env$.envir_solution <- envir_solution
  eval(parse(text = check_code), envir = check_env)
}

if (!exists("%||%", mode = "function", envir = baseenv())) {
  `%||%` <- function(x, y) if (is.null(x)) y else x
}
