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
    column_type = "Spalte `%s` hat den Typ %s, erwartet: %s.",
    length = "Die Länge stimmt nicht: erwartet %d, erhalten %d.",
    values = "Die Werte stimmen noch nicht.",
    levels = "Die Stufen (`levels`) stimmen nicht: erwartet %s, erhalten %s.",
    htest = "Der Test liefert andere Werte (%s) als erwartet. Prüfe Variablen, Daten und Optionen.",
    htest_df = "Die Freiheitsgrade stimmen nicht: erwartet etwa %s, erhalten %s. Wie viele unabhängige Beobachtungen gehen in den Test ein?",
    missing_object = "Das Objekt `%s` fehlt. Hast du es mit `<-` gespeichert?",
    output = "Die Ausgabe enthält noch nicht das Erwartete.",
    plot_class = "Das Ergebnis ist kein ggplot. Steht der Plot in der letzten Zeile (bzw. im Objekt `%s`)?",
    plot_layers = "Die Ebenen stimmen nicht: erwartet %s, erhalten %s.",
    plot_mapping = "Ebene %d (%s): Die Zuordnung (`aes()`) stimmt nicht. Erwartet %s, erhalten %s.",
    plot_setting = "Ebene %d (%s): Die festen Einstellungen außerhalb von `aes()` stimmen nicht. Erwartet %s, erhalten %s.",
    plot_param = "Ebene %d (%s): Das Argument `%s` stimmt nicht.",
    plot_position = "Ebene %d (%s): Die Position stimmt nicht: erwartet `%s`, erhalten `%s`.",
    plot_layer_data = "Ebene %d (%s): Die Daten dieser Ebene stimmen nicht (z. B. der Wert einer Referenzlinie).",
    plot_facet = "Die Aufteilung in Panels (facet) stimmt nicht: erwartet %s, erhalten %s.",
    plot_scale = "Die Skalen stimmen nicht: erwartet %s, erhalten %s.",
    plot_data = "Die Daten des Plots stimmen nicht: %s",
    plot_patchwork = "Erwartet ist eine Kombination mehrerer Plots (patchwork), z. B. `p1 + p2`.",
    plot_patch_count = "Die Kombination enthält %d statt %d Plots.",
    plot_patch = "Plot %d der Kombination: %s",
    plot_patch_layout = "Die Anordnung der Kombination stimmt nicht (`plot_layout()`: Spalten, Zeilen, Legenden) oder die Teilbilder sind anders gekennzeichnet (`plot_annotation(tag_levels = )`).",
    none = "keine",
    table_variables = "Die Tabelle enthält andere Variablen: erwartet %s, erhalten %s.",
    table_header = "Der Tabellenkopf stimmt nicht (Gruppenspalten oder N je Gruppe). Prüfe `by` und die Daten.",
    table_values = "Die Kennwerte in der Tabelle stimmen noch nicht. Prüfe `statistic`, `type` und die Daten.",
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
    column_type = "Column `%s` has type %s, expected: %s.",
    length = "The length does not match: expected %d, got %d.",
    values = "The values are not right yet.",
    levels = "The levels do not match: expected %s, got %s.",
    htest = "The test returns different values (%s) than expected. Check variables, data and options.",
    htest_df = "The degrees of freedom do not match: expected about %s, got %s. How many independent observations enter the test?",
    missing_object = "The object `%s` is missing. Did you save it with `<-`?",
    output = "The output does not contain what was expected yet.",
    plot_class = "The result is not a ggplot. Is the plot on the last line (or in the object `%s`)?",
    plot_layers = "The layers do not match: expected %s, got %s.",
    plot_mapping = "Layer %d (%s): the mapping (`aes()`) does not match. Expected %s, got %s.",
    plot_setting = "Layer %d (%s): the fixed settings outside `aes()` do not match. Expected %s, got %s.",
    plot_param = "Layer %d (%s): the argument `%s` does not match.",
    plot_position = "Layer %d (%s): the position does not match: expected `%s`, got `%s`.",
    plot_layer_data = "Layer %d (%s): the data of this layer do not match (e.g. the value of a reference line).",
    plot_facet = "The panels (facets) do not match: expected %s, got %s.",
    plot_scale = "The scales do not match: expected %s, got %s.",
    plot_data = "The plot data do not match: %s",
    plot_patchwork = "A combination of several plots (patchwork) is expected, e.g. `p1 + p2`.",
    plot_patch_count = "The combination contains %d instead of %d plots.",
    plot_patch = "Plot %d of the combination: %s",
    plot_patch_layout = "The arrangement of the combination does not match (`plot_layout()`: columns, rows, legends) or the panels are tagged differently (`plot_annotation(tag_levels = )`).",
    none = "none",
    table_variables = "The table contains other variables: expected %s, got %s.",
    table_header = "The table header does not match (group columns or N per group). Check `by` and the data.",
    table_values = "The statistics in the table are not right yet. Check `statistic`, `type` and the data.",
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

# Column types for check_types: factor (with the same levels), numeric
# (integer and double alike), character, logical; other types are not checked.
rt_type_name <- function(x) {
  if (is.factor(x)) {
    "factor"
  } else if (is.numeric(x)) {
    "numeric"
  } else if (is.character(x)) {
    "character"
  } else if (is.logical(x)) {
    "logical"
  } else {
    NA_character_
  }
}

rt_column_type <- function(result, expected, col, lang) {
  want <- rt_type_name(expected)
  got <- rt_type_name(result)
  if (is.na(want)) {
    return(NULL)
  }
  if (!identical(want, got)) {
    return(rt_msg("column_type", lang, col, if (is.na(got)) class(result)[1] else got, want))
  }
  if (want == "factor" && !identical(levels(result), levels(expected))) {
    return(rt_msg("levels", lang, rt_collapse(levels(expected)), rt_collapse(levels(result))))
  }
  NULL
}

# Compare a result with the expected value.
# Returns NULL when they match, otherwise a feedback message.
rt_compare <- function(result, expected, tolerance = 1e-6,
                       ignore_row_order = FALSE, ignore_col_order = TRUE,
                       check_types = FALSE, lang = "de") {
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

  if (inherits(expected, "gtsummary")) {
    return(rt_compare_gtsummary(result, expected, lang))
  }

  if (is.data.frame(expected)) {
    if (!is.data.frame(result)) {
      return(rt_msg("class", lang, "data frame", class(result)[1]))
    }
    if (!setequal(names(result), names(expected))) {
      return(rt_msg(
        "columns", lang, rt_collapse(names(expected)), rt_collapse(names(result))
      ))
    }
    if (check_types) {
      for (col in names(expected)) {
        problem <- rt_column_type(result[[col]], expected[[col]], col, lang)
        if (!is.null(problem)) {
          return(problem)
        }
      }
    }
    result <- rt_plain_df(result)
    expected <- rt_plain_df(expected)
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

  if (is.factor(expected)) {
    if (!is.factor(result)) {
      return(rt_msg("class", lang, "factor", class(result)[1]))
    }
    if (!identical(levels(result), levels(expected))) {
      return(rt_msg("levels", lang, rt_collapse(levels(expected)), rt_collapse(levels(result))))
    }
    if (length(result) != length(expected)) {
      return(rt_msg("length", lang, length(expected), length(result)))
    }
    if (!identical(as.character(result), as.character(expected))) {
      return(rt_msg("values", lang))
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

# ggplot2 objects are inspected with `$` only, so this stays base R.
rt_snake <- function(x) tolower(gsub("([a-z0-9])([A-Z])", "\\1_\\2", x))

rt_aes_text <- function(x) {
  expr <- if (inherits(x, "formula")) unclass(x)[[2]] else x
  paste(deparse(expr), collapse = " ")
}

# Effective mapping of a layer: plot mapping (if inherited) + layer mapping,
# as named character vector aesthetic = expression, sorted by name.
rt_layer_mapping <- function(plot, layer) {
  mapping <- list()
  if (isTRUE(layer$inherit.aes)) mapping <- unclass(plot$mapping)
  for (aes_name in names(layer$mapping)) mapping[[aes_name]] <- layer$mapping[[aes_name]]
  out <- vapply(mapping, rt_aes_text, character(1))
  out[order(names(out))]
}

rt_layer_settings <- function(layer) {
  settings <- vapply(layer$aes_params, function(x) paste(format(x), collapse = ", "), character(1))
  settings[order(names(settings))]
}

rt_format_pairs <- function(x, lang) {
  if (length(x) == 0) {
    return(rt_msg("none", lang))
  }
  paste0("`", names(x), " = ", x, "`", collapse = ", ")
}

rt_facet_text <- function(plot) {
  facet <- plot$facet
  type <- rt_snake(class(facet)[1])
  if (type == "facet_null") {
    return(rt_msg("none", "en"))
  }
  vars <- c(names(facet$params$facets), names(facet$params$rows), names(facet$params$cols))
  sprintf("%s(%s)", type, paste(vars, collapse = ", "))
}

rt_scale_text <- function(plot) {
  scales <- plot$scales$scales
  if (length(scales) == 0) {
    return(character(0))
  }
  out <- vapply(scales, function(scale) {
    transform <- tryCatch(scale$get_transformation()$name, error = function(e) NULL)
    transform <- transform %||% tryCatch(scale$trans$name, error = function(e) NULL)
    paste0(scale$aesthetics[1], if (!is.null(transform)) paste0(" (", transform, ")"))
  }, character(1))
  sort(out)
}

# Compare a ggplot with the expected one: layers (geoms, in order), mapping,
# fixed settings, position and own data per layer, facets, scales; optionally
# named layer parameters (`params`, e.g. method, se) and the plot data.
# Layout and tags of a patchwork; `$` works for S3 and S7 ggplot objects.
# Rows and columns are resolved as patchwork does, so `p1 | p2` (nrow = 1)
# equals `p1 + p2` (automatic grid).
rt_patch_layout <- function(p) {
  patches <- p$patches
  dims <- ggplot2::wrap_dims(length(p), patches$layout$nrow, patches$layout$ncol)
  list(
    dims = as.integer(dims), byrow = patches$layout$byrow %||% TRUE,
    guides = patches$layout$guides, tags = patches$annotation$tag_levels
  )
}

rt_compare_plot <- function(result, expected, params = NULL, check_data = FALSE,
                            name = NULL, lang = "de") {
  if (!inherits(result, "ggplot")) {
    return(rt_msg("plot_class", lang, name %||% "p"))
  }
  # patchwork: compare each plot of the combination, then the layout.
  if (inherits(expected, "patchwork")) {
    if (!inherits(result, "patchwork")) {
      return(rt_msg("plot_patchwork", lang))
    }
    if (length(result) != length(expected)) {
      return(rt_msg("plot_patch_count", lang, length(result), length(expected)))
    }
    for (i in seq_along(expected)) {
      problem <- rt_compare_plot(result[[i]], expected[[i]], params, check_data, name, lang)
      if (!is.null(problem)) {
        return(rt_msg("plot_patch", lang, i, problem))
      }
    }
    if (!identical(rt_patch_layout(result), rt_patch_layout(expected))) {
      return(rt_msg("plot_patch_layout", lang))
    }
    return(NULL)
  }
  geoms <- function(p) vapply(p$layers, function(l) rt_snake(class(l$geom)[1]), character(1))
  result_geoms <- geoms(result)
  expected_geoms <- geoms(expected)
  if (!identical(result_geoms, expected_geoms)) {
    shown <- function(x) if (length(x) == 0) rt_msg("none", lang) else rt_collapse(x)
    return(rt_msg("plot_layers", lang, shown(expected_geoms), shown(result_geoms)))
  }
  for (i in seq_along(expected$layers)) {
    got <- result$layers[[i]]
    want <- expected$layers[[i]]
    mapping_got <- rt_layer_mapping(result, got)
    mapping_want <- rt_layer_mapping(expected, want)
    if (!identical(mapping_got, mapping_want)) {
      return(rt_msg(
        "plot_mapping", lang, i, expected_geoms[i],
        rt_format_pairs(mapping_want, lang), rt_format_pairs(mapping_got, lang)
      ))
    }
    settings_got <- rt_layer_settings(got)
    settings_want <- rt_layer_settings(want)
    if (!identical(names(settings_got), names(settings_want))) {
      return(rt_msg(
        "plot_setting", lang, i, expected_geoms[i],
        rt_format_pairs(settings_want, lang), rt_format_pairs(settings_got, lang)
      ))
    }
    position_got <- rt_snake(class(got$position)[1])
    position_want <- rt_snake(class(want$position)[1])
    if (!identical(position_got, position_want)) {
      return(rt_msg("plot_position", lang, i, expected_geoms[i], position_want, position_got))
    }
    # Layers with their own data (geom_hline(yintercept = 180), annotate()).
    if (is.data.frame(want$data) &&
      !(is.data.frame(got$data) && is.null(rt_compare(got$data, want$data, ignore_row_order = TRUE, lang = lang)))) {
      return(rt_msg("plot_layer_data", lang, i, expected_geoms[i]))
    }
    for (param in unlist(params)) {
      value <- function(l) l$stat_params[[param]] %||% l$geom_params[[param]]
      if (!isTRUE(all.equal(value(got), value(want)))) {
        return(rt_msg("plot_param", lang, i, expected_geoms[i], param))
      }
    }
  }
  if (!identical(rt_facet_text(result), rt_facet_text(expected))) {
    return(rt_msg("plot_facet", lang, rt_facet_text(expected), rt_facet_text(result)))
  }
  if (!identical(rt_scale_text(result), rt_scale_text(expected))) {
    shown <- function(x) if (length(x) == 0) rt_msg("none", lang) else rt_collapse(x)
    return(rt_msg("plot_scale", lang, shown(rt_scale_text(expected)), shown(rt_scale_text(result))))
  }
  if (isTRUE(check_data)) {
    problem <- rt_compare(result$data, expected$data, ignore_row_order = TRUE, lang = lang)
    if (!is.null(problem)) {
      return(rt_msg("plot_data", lang, problem))
    }
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
# gtsummary tables: same variables, same visible header, same formatted cells.
# The objects themselves differ in calls and environments, so they are not compared.
rt_compare_gtsummary <- function(result, expected, lang = "de") {
  if (!inherits(result, "gtsummary")) {
    return(rt_msg("class", lang, "gtsummary", class(result)[1]))
  }
  variables <- function(x) unique(x$table_body$variable)
  if (!identical(variables(result), variables(expected))) {
    return(rt_msg(
      "table_variables", lang,
      rt_collapse(variables(expected)), rt_collapse(variables(result))
    ))
  }
  header <- function(x) {
    h <- x$table_styling$header
    h$label[!h$hide]
  }
  if (!identical(header(result), header(expected))) {
    return(rt_msg("table_header", lang))
  }
  body <- function(x) rt_plain_df(gtsummary::as_tibble(x, col_labels = FALSE))
  if (!identical(body(result), body(expected))) {
    return(rt_msg("table_values", lang))
  }
  NULL
}

# type = "value" (last value vs. solution), "object" (object `name` in the
# user's environment vs. the solution's) or "output" (printed output matches
# regex `pattern`) or "plot" (ggplot vs. the solution's: layers, aes(),
# settings, facets, scales; optional `params`, `check_data`, and `name` for
# a plot stored in an object instead of the last value).
rt_problem <- function(spec, lang, env) {
  tryCatch(
    switch(spec$type,
      value = rt_compare(
        get0(".result", env),
        get0(".solution", env),
        tolerance = spec$tolerance %||% 1e-6,
        ignore_row_order = isTRUE(spec$ignore_row_order),
        ignore_col_order = !isFALSE(spec$ignore_col_order),
        check_types = isTRUE(spec$check_types),
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
            check_types = isTRUE(spec$check_types),
            lang = lang
          )
        }
      },
      output = {
        printed <- paste(utils::capture.output(print(get0(".result", env))), collapse = "\n")
        if (grepl(spec$pattern, printed, perl = TRUE)) NULL else rt_msg("output", lang)
      },
      plot = {
        if (is.null(spec$name)) {
          result <- get0(".result", env)
          expected <- get0(".solution", env)
        } else {
          result <- get0(spec$name, envir = get0(".envir_result", env) %||% emptyenv())
          expected <- get0(spec$name, envir = get0(".envir_solution", env) %||% emptyenv())
        }
        rt_compare_plot(
          result, expected,
          params = spec$params,
          check_data = isTRUE(spec$check_data),
          name = spec$name,
          lang = lang
        )
      },
      stop("Unknown check type: ", spec$type)
    ),
    error = function(e) rt_msg("check_error", lang, conditionMessage(e))
  )
}

# Evaluate the user's code again in a child of their environment. quarto-live
# hands over what printing returned, which is not always the value: rendered
# HTML for objects with a knit_print() method (gtsummary), NULL for print
# methods that return cat() (report), and on the first run after loading
# psych an unrelated value. Only a visible value counts, so code ending in an
# assignment still has no result. Returns NULL when there is nothing to use.
rt_reevaluate <- function(env) {
  user_env <- get0(".envir_result", env)
  user_code <- get0(".user_code", env)
  if (!is.environment(user_env) || !is.character(user_code)) {
    return(NULL)
  }
  tryCatch(
    {
      res <- withVisible(eval(parse(text = user_code), envir = new.env(parent = user_env)))
      if (res$visible) list(value = res$value) else NULL
    },
    error = function(e) NULL
  )
}

rt_check <- function(spec, mistakes = list(), lang = "de", env = parent.frame()) {
  problem <- rt_problem(spec, lang, env)
  if (!is.null(problem) && identical(spec$type, "value")) {
    again <- rt_reevaluate(env)
    if (!is.null(again)) {
      retry_env <- new.env(parent = env)
      retry_env$.result <- again$value
      problem <- rt_problem(spec, lang, retry_env)
    }
  }

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
