#' Check user code against an exercise
#' @param exercise Exercise list.
#' @param user_code Character string.
#' @return list(correct, message, details)
#' @export
check_exercise <- function(exercise, user_code) {
  res <- function(ok, msg, details = list()) {
    list(correct = ok, message = msg, details = details)
  }
  if (!nzchar(trimws(user_code))) return(res(FALSE, "Du hast noch keinen Code geschrieben."))
  chk <- exercise$check

  # predict: the answer is a value literal, so running the shown code is no shortcut
  if (identical(exercise$kind, "predict") && chk$type == "value") {
    lit <- check_literal(user_code)
    if (!lit$correct) return(lit)
  }

  # Static checks need no execution
  if (chk$type %in% c("regex", "ast")) return(check_static(chk, user_code))

  user <- run_code(user_code, exercise)
  if (!user$ok) {
    out <- res(FALSE, translate_error(user$error, user$timed_out), list(error = user$error))
    return(add_mistake_hint(out, exercise$common_mistakes, user_code))
  }
  sol <- solution_result(exercise)

  out <- switch(chk$type,
    value = check_value(chk, user, sol),
    output = check_output(user, sol),
    object = check_object(chk, user, sol),
    `function` = check_function(chk, user),
    plot = check_plot(chk, user, sol)
  )
  if (out$correct && !is.null(chk$post)) out <- check_post(chk, user, sol)
  if (!out$correct) out <- add_mistake_hint(out, exercise$common_mistakes, user_code)
  if (out$correct && (!is.null(chk$forbid) || !is.null(chk$require))) {
    st <- check_static(list(type = "ast", forbid = chk$forbid, require = chk$require), user_code)
    if (!st$correct) return(add_mistake_hint(st, exercise$common_mistakes, user_code))
  }
  out
}

# The solution result only depends on the exercise definition, so it is
# cached per session (halves the time for "Pr\u00fcfen").
solution_cache <- new.env(parent = emptyenv())

solution_result <- function(exercise) {
  key <- rlang::hash(exercise[c("id", "solution", "setup", "packages", "seed", "timeout", "check")])
  if (!is.null(solution_cache[[key]])) return(solution_cache[[key]])
  sol <- run_code(exercise$solution, exercise)
  if (!sol$ok) {
    cli::cli_abort("Musterl\u00f6sung von {.val {exercise$id}} schl\u00e4gt fehl: {sol$error}")
  }
  solution_cache[[key]] <- sol
  sol
}

# check$post runs in the worker after the code (e.g. inspects a saved file);
# its value must match the solution's.
check_post <- function(chk, user, sol) {
  prefix <- chk$post_message %||% "Die Nachpr\u00fcfung schl\u00e4gt fehl."
  if (inherits(user$post, "post_error")) {
    return(list(correct = FALSE, message = paste(prefix, unclass(user$post)), details = list()))
  }
  cmp <- compare_values(user$post, sol$post, chk)
  if (cmp$ok) return(list(correct = TRUE, message = "Richtig!", details = cmp))
  fmt <- function(v) {
    v <- unlist(v)
    paste(if (is.null(names(v))) format(v) else paste(names(v), "=", format(v)), collapse = ", ")
  }
  list(correct = FALSE, details = cmp,
       message = sprintf("%s Erwartet: %s; bekommen: %s.", prefix, fmt(sol$post), fmt(user$post)))
}

# Appends the first matching common_mistakes message (also after runtime errors)
add_mistake_hint <- function(out, cm, code) {
  hint <- match_common_mistakes(cm, code)
  if (length(hint)) {
    out$message <- paste(out$message, hint, sep = "\n")
    out$details$mistake <- sub("^Hinweis: ", "", hint)
  }
  out
}

match_common_mistakes <- function(cm, code) {
  hit <- Filter(function(m) grepl(m$pattern, code, perl = TRUE), cm)
  if (length(hit)) paste0("Hinweis: ", hit[[1]]$message) else character()
}

# ---- value ----------------------------------------------------------------

check_value <- function(chk, user, sol) {
  if (!user$has_value) {
    return(list(correct = FALSE, details = list(),
                message = "Dein Code liefert keinen Wert. Der letzte Ausdruck muss das Ergebnis sein."))
  }
  cmp <- compare_values(user$value, sol$value, chk)
  list(correct = cmp$ok,
       message = if (cmp$ok) "Richtig!" else cmp$message,
       details = cmp)
}

compare_values <- function(x, y, chk = list()) {
  tol <- chk$tolerance %||% 1.5e-8
  if (is.data.frame(y)) {
    if (!is.data.frame(x)) {
      return(fail(sprintf("Erwartet wurde ein Data Frame, bekommen: %s.", class(x)[1])))
    }
    return(compare_df(x, y, chk, tol))
  }
  if (is.numeric(y) && is.numeric(x)) {
    r <- all.equal(unname(c(x)), unname(c(y)), tolerance = tol, check.attributes = FALSE)
    if (isTRUE(r)) return(list(ok = TRUE, message = "Richtig!"))
    return(fail(paste("Numerischer Unterschied:", paste(r, collapse = "; "))))
  }
  r <- all.equal(x, y, tolerance = tol,
                 check.attributes = !isTRUE(chk$ignore_attributes))
  if (isTRUE(r)) list(ok = TRUE, message = "Richtig!")
  else fail(paste("Ergebnis weicht ab:", paste(r, collapse = "; ")))
}

fail <- function(msg) list(ok = FALSE, message = msg)

compare_df <- function(x, y, chk, tol) {
  x <- as.data.frame(x); y <- as.data.frame(y)
  ex <- names(y); got <- names(x)
  missing <- setdiff(ex, got)
  if (length(missing)) {
    return(fail(sprintf("Spalte%s %s fehlt. Vorhanden sind: %s.",
                        if (length(missing) > 1) "n" else "",
                        paste0("`", missing, "`", collapse = ", "),
                        paste(got, collapse = ", "))))
  }
  extra <- setdiff(got, ex)
  if (length(extra)) {
    return(fail(sprintf("Unerwartete Spalte(n): %s. Erwartet: %s.",
                        paste0("`", extra, "`", collapse = ", "), paste(ex, collapse = ", "))))
  }
  if (!isTRUE(chk$ignore_col_order %||% FALSE) && !identical(got, ex)) {
    return(fail(sprintf("Spaltenreihenfolge stimmt nicht. Erwartet: %s.", paste(ex, collapse = ", "))))
  }
  x <- x[ex]
  if (nrow(x) != nrow(y)) {
    return(fail(sprintf("Falsche Zeilenanzahl: erwartet %d, bekommen %d.", nrow(y), nrow(x))))
  }
  if (isTRUE(chk$ignore_row_order)) {
    x <- x[do.call(order, unname(as.list(x))), , drop = FALSE]
    y <- y[do.call(order, unname(as.list(y))), , drop = FALSE]
  }
  for (col in ex) {
    cx <- x[[col]]; cy <- y[[col]]
    # Factor vs. character counts as equal content (labels are compared)
    if (is.factor(cx) != is.factor(cy) && all(c(class(cx)[1], class(cy)[1]) %in% c("factor", "character"))) {
      cx <- as.character(cx); cy <- as.character(cy)
    }
    if (!identical(class(cx)[1], class(cy)[1]) &&
        !(is.numeric(cx) && is.numeric(cy))) {
      return(fail(sprintf("Spalte `%s`: erwarteter Typ %s, bekommen %s.",
                          col, class(cy)[1], class(cx)[1])))
    }
    if (is.list(cy)) {
      if (!isTRUE(all.equal(cx, cy, tolerance = tol, check.attributes = FALSE))) {
        return(fail(sprintf("Listen-Spalte `%s` weicht ab.", col)))
      }
      next
    }
    bad <- which(!vapply(seq_along(cy), function(i) {
      a <- cx[i]; b <- cy[i]
      if (is.na(a) || is.na(b)) return(is.na(a) && is.na(b))
      if (is.numeric(a)) abs(a - b) <= tol * max(1, abs(b)) else identical(as.character(a), as.character(b))
    }, logical(1)))
    if (length(bad)) {
      i <- bad[1]
      rounding <- is.numeric(cy) && !is.na(cx[i]) && !is.na(cy[i]) && abs(cx[i] - cy[i]) < 0.5 &&
        abs(round(cx[i], 1) - cy[i]) < 1e-8
      return(fail(sprintf("Spalte `%s`, Zeile %d: erwartet %s, bekommen %s%s.",
                          col, i, format(cy[i]), format(cx[i]),
                          if (rounding) " (nicht gerundet?)" else "")))
    }
  }
  if (!isTRUE(chk$ignore_attributes %||% TRUE)) {
    r <- all.equal(attributes(x), attributes(y))
    if (!isTRUE(r)) return(fail(paste("Attribute weichen ab:", paste(r, collapse = "; "))))
  }
  list(ok = TRUE, message = "Richtig!")
}

# ---- output ---------------------------------------------------------------

norm_ws <- function(x) trimws(gsub("[[:space:]]+", " ", x))

check_output <- function(user, sol) {
  ok <- identical(norm_ws(user$output), norm_ws(sol$output))
  list(correct = ok,
       message = if (ok) "Richtig!" else paste("Ausgabe weicht ab.", text_diff(sol$output, user$output), sep = "\n"),
       details = list())
}

# ---- object ---------------------------------------------------------------

check_object <- function(chk, user, sol) {
  nm <- chk$name
  if (!nm %in% names(user$env)) {
    have <- names(user$env)
    return(list(correct = FALSE, details = list(),
                message = sprintf("Das Objekt `%s` existiert nicht. Vorhanden: %s.", nm,
                                  if (length(have)) paste(have, collapse = ", ") else "keine Objekte")))
  }
  obj <- user$env[[nm]]
  if (!is.null(chk$class) && !inherits(obj, chk$class)) {
    return(list(correct = FALSE, details = list(),
                message = sprintf("`%s` hat Klasse %s, erwartet wurde %s.", nm,
                                  paste(class(obj), collapse = "/"), chk$class)))
  }
  if (isTRUE(chk$compare_value)) {
    cmp <- compare_values(obj, sol$env[[nm]], chk)
    return(list(correct = cmp$ok, message = cmp$message, details = cmp))
  }
  list(correct = TRUE, message = "Richtig!", details = list())
}

# ---- function -------------------------------------------------------------

check_function <- function(chk, user) {
  nm <- chk$name
  f <- user$env[[nm]]
  if (!is.function(f)) {
    return(list(correct = FALSE, details = list(),
                message = sprintf("Es gibt keine Funktion `%s`. Definiere sie mit `%s <- function(...)`.", nm, nm)))
  }
  results <- lapply(seq_along(chk$tests), function(i) {
    t <- chk$tests[[i]]
    args <- if (is.character(t$args)) eval(parse(text = t$args)) else as.list(t$args)
    expected <- if (is.character(t$expect)) eval(parse(text = t$expect)) else t$expect
    got <- tryCatch(do.call(f, args), error = function(e) e)
    if (inherits(got, "error")) {
      return(list(i = i, ok = FALSE, msg = sprintf("Test %d: Fehler: %s", i, conditionMessage(got))))
    }
    cmp <- compare_values(got, expected, chk)
    list(i = i, ok = cmp$ok,
         msg = if (cmp$ok) sprintf("Test %d: bestanden", i)
               else sprintf("Test %d: erwartet %s, bekommen %s", i,
                            paste(format(expected), collapse = ", "), paste(format(got), collapse = ", ")))
  })
  ok <- all(vapply(results, `[[`, TRUE, "ok"))
  msgs <- vapply(results, function(r) paste(if (r$ok) "\u2713" else "\u2717", r$msg), "")
  list(correct = ok, message = paste(c(if (ok) "Richtig!" else "Nicht alle Tests bestanden:", msgs), collapse = "\n"),
       details = results)
}

# ---- regex / ast ----------------------------------------------------------

# Collect function names (calls) used in code via parse data
used_functions <- function(code) {
  pd <- tryCatch(utils::getParseData(parse(text = code, keep.source = TRUE)), error = function(e) NULL)
  if (is.null(pd)) return(NULL)
  fn <- pd$text[pd$token == "SYMBOL_FUNCTION_CALL"]
  loops <- pd$token[pd$token %in% c("FOR", "WHILE", "REPEAT")]
  unique(c(fn, c(FOR = "for", WHILE = "while", REPEAT = "repeat")[loops]))
}

check_static <- function(chk, code) {
  fns <- used_functions(code)
  if (is.null(fns)) {
    return(list(correct = FALSE, details = list(),
                message = "Der Code enth\u00e4lt einen Syntaxfehler und kann nicht geparst werden."))
  }
  strip <- function(v) sub("^.*::", "", unlist(v))
  forbid <- strip(chk$forbid); require <- strip(chk$require)
  bad <- intersect(fns, forbid)
  if (length(bad)) {
    return(list(correct = FALSE, details = list(),
                message = sprintf("Nicht erlaubt in dieser Aufgabe: %s.", paste0("`", bad, "`", collapse = ", "))))
  }
  need <- setdiff(require, fns)
  if (length(need)) {
    return(list(correct = FALSE, details = list(),
                message = sprintf("Verwende bitte: %s.", paste0("`", need, "`", collapse = ", "))))
  }
  if (!is.null(chk$pattern) && !grepl(chk$pattern, code, perl = TRUE)) {
    return(list(correct = FALSE, details = list(), message = chk$message %||% "Gesuchtes Muster fehlt."))
  }
  list(correct = TRUE, message = "Richtig!", details = list())
}

# ---- predict literals -----------------------------------------------------

literal_calls <- c("c", "list", "factor", "character", "numeric", "integer",
                   "logical", "-", "(")

# A predict answer may only contain constants and simple constructors
check_literal <- function(code) {
  pd <- tryCatch(utils::getParseData(parse(text = code, keep.source = TRUE)), error = function(e) NULL)
  if (is.null(pd)) {
    return(list(correct = FALSE, details = list(),
                message = "Die Antwort enth\u00e4lt einen Syntaxfehler und kann nicht geparst werden."))
  }
  calls <- setdiff(pd$text[pd$token == "SYMBOL_FUNCTION_CALL"], literal_calls)
  bad <- unique(c(calls, pd$text[pd$token %in% c("SYMBOL", "LEFT_ASSIGN", "EQ_ASSIGN", "RIGHT_ASSIGN")]))
  bad <- setdiff(bad, c("T", "F"))
  if (length(bad)) {
    return(list(correct = FALSE, details = list(bad = bad), message = paste0(
      "Gib das Ergebnis als Wert ein, z. B. `c(4, NA)`, `\"a\"` oder `list(x = 1)`, ",
      "nicht als Code. Nicht erlaubt: ", paste0("`", bad, "`", collapse = ", "), ".")))
  }
  list(correct = TRUE, message = "Richtig!", details = list())
}

# ---- plot -----------------------------------------------------------------

# Structural ggplot check. Besides geoms, mappings and facets, built layer
# data, scales and theme elements are compared with the solution's plot, so
# equivalent code (scale_x_log10() vs. trans = "log10") passes.
check_plot <- function(chk, user, sol) {
  get_plot <- function(r) if (!is.null(chk$name)) r$env[[chk$name]] else r$value
  p <- get_plot(user)
  no <- function(msg, ...) list(correct = FALSE, message = msg, details = list(...))
  if (!inherits(p, "ggplot")) {
    return(no("Es wurde kein ggplot-Objekt erzeugt (letzter Ausdruck bzw. Objekt pr\u00fcfen)."))
  }
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  want <- geom_class(unlist(chk$geoms))
  miss <- want[!tolower(want) %in% tolower(geoms)]
  if (length(miss)) {
    miss <- paste0("`geom_", tolower(sub("^Geom", "", miss)), "`")
    return(no(sprintf("Es fehlen Geoms: %s. Vorhanden: %s.", paste(miss, collapse = ", "),
                      if (length(geoms)) paste(geoms, collapse = ", ") else "keine"), geoms = geoms))
  }
  m <- c(as.list(p$mapping), unlist(lapply(unname(p$layers), function(l) as.list(l$mapping))))
  for (a in names(chk$mapping %||% list())) {
    got <- if (!is.null(m[[a]])) rlang::as_label(m[[a]]) else NA
    if (is.na(got) || got != chk$mapping[[a]]) {
      return(no(sprintf("Mapping `%s` sollte `%s` sein.", a, chk$mapping[[a]])))
    }
  }
  if (!is.null(chk$facet) && !isFALSE(chk$facet)) {
    if (inherits(p$facet, "FacetNull")) return(no("Es fehlt ein Facet (z. B. `facet_wrap()`)."))
    want_vars <- unlist(chk$facet)
    if (is.character(want_vars)) {
      vars <- facet_vars(p)
      if (!setequal(vars, want_vars)) {
        return(no(sprintf("Facets nach %s erwartet, vorhanden: %s.",
                          paste0("`", want_vars, "`", collapse = ", "),
                          if (length(vars)) paste0("`", vars, "`", collapse = ", ") else "keine")))
      }
    }
  }
  if (length(chk$layers) || length(chk$scales)) {
    build <- function(x) suppressWarnings(suppressMessages(ggplot2::ggplot_build(x)))
    ub <- tryCatch(build(p), error = function(e) e)
    if (inherits(ub, "error")) return(no(paste("Der Plot l\u00e4sst sich nicht aufbauen:", conditionMessage(ub))))
    sb <- build(get_plot(sol))
    for (a in unlist(chk$scales)) {
      out <- compare_scale(a, ub, sb)
      if (!is.null(out)) return(no(out))
    }
    for (g in names(chk$layers)) {
      out <- compare_layer(g, unlist(chk$layers[[g]]), ub, sb, chk$tolerance %||% 1e-6)
      if (!is.null(out)) return(no(out))
    }
  }
  for (el in unlist(chk$theme)) {
    out <- compare_theme_element(el, p, get_plot(sol))
    if (!is.null(out)) return(no(out))
  }
  list(correct = TRUE, message = "Richtig!", details = list(geoms = geoms))
}

geom_class <- function(g) {
  s <- sub("^geom_", "", g)
  if (!length(s)) return(character())
  paste0("Geom", toupper(substr(s, 1, 1)), substring(s, 2))
}

facet_vars <- function(p) {
  pr <- p$facet$params
  unique(c(names(pr$facets), names(pr$rows), names(pr$cols)))
}

# Built data of the first layer with geom `g`, restricted to `cols`
layer_frame <- function(b, g, cols) {
  i <- match(tolower(geom_class(g)), tolower(vapply(b$plot$layers, function(l) class(l$geom)[1], "")))
  if (is.na(i)) return(NULL)
  d <- b$data[[i]]
  d <- d[intersect(cols, names(d))]
  for (nm in names(d)) {
    if (nm %in% c("colour", "fill") && is.character(d[[nm]])) {
      rgba <- grDevices::col2rgb(d[[nm]], alpha = TRUE)
      d[[nm]] <- ifelse(is.na(d[[nm]]), NA,
                        grDevices::rgb(rgba[1, ], rgba[2, ], rgba[3, ], rgba[4, ], maxColorValue = 255))
    } else if (is.numeric(d[[nm]])) {
      d[[nm]] <- as.numeric(d[[nm]])
    }
  }
  as.data.frame(d)
}

compare_layer <- function(g, cols, ub, sb, tol) {
  ud <- layer_frame(ub, g, cols)
  sd <- layer_frame(sb, g, cols)
  if (is.null(ud)) return(sprintf("Es gibt keinen Layer mit `geom_%s`.", sub("^geom_", "", g)))
  cmp <- compare_df(ud, sd, list(ignore_row_order = TRUE, ignore_col_order = TRUE), tol)
  if (cmp$ok) NULL else sprintf("Layer `%s`: %s", sub("^geom_", "", g), cmp$message)
}

built_scale <- function(b, a) {
  if (a %in% c("x", "y")) b$layout[[paste0("panel_scales_", a)]][[1]] else b$plot$scales$get_scales(a)
}

compare_scale <- function(a, ub, sb) {
  us <- built_scale(ub, a)
  ss <- built_scale(sb, a)
  if (is.null(us)) return(sprintf("Es gibt keine Skala f\u00fcr `%s`.", a))
  show <- function(v) paste(v, collapse = ", ")
  trans <- function(s) if (inherits(s, "ScaleContinuous")) s$get_transformation()$name else "diskret"
  if (!identical(trans(us), trans(ss))) {
    return(sprintf("Skala `%s`: erwartet %s, bekommen %s.", a,
                   if (trans(ss) == "diskret") "diskret" else paste("Transformation", trans(ss)),
                   if (trans(us) == "diskret") "diskret" else paste("Transformation", trans(us))))
  }
  if (trans(ss) == "diskret" && !identical(as.character(us$get_limits()), as.character(ss$get_limits()))) {
    return(sprintf("Skala `%s`: Stufen/Reihenfolge erwartet %s, bekommen %s.", a,
                   show(ss$get_limits()), show(us$get_limits())))
  }
  ubr <- us$get_breaks(); sbr <- ss$get_breaks()
  same_breaks <- if (is.numeric(sbr)) {
    length(ubr) == length(sbr) && isTRUE(all.equal(as.numeric(ubr), as.numeric(sbr)))
  } else {
    identical(as.character(ubr), as.character(sbr))
  }
  if (!same_breaks || !identical(as.character(us$get_labels()), as.character(ss$get_labels()))) {
    return(sprintf("Skala `%s`: Achsenmarken erwartet %s, bekommen %s.", a,
                   show(ss$get_labels()), show(us$get_labels())))
  }
  NULL
}

compare_theme_element <- function(el, p, sp) {
  get <- function(x) ggplot2::calc_element(el, ggplot2::complete_theme(x$theme))
  ue <- get(p); se <- get(sp)
  # ggplot2 >= 4.0 elements are S7 objects whose properties are attributes
  props <- function(e) {
    if (!inherits(e, "S7_object")) return(if (is.list(e)) unclass(e) else e)
    a <- attributes(e)
    a[setdiff(names(a), c("class", "S7_class"))]
  }
  if (!identical(class(ue)[1], class(se)[1])) {
    return(sprintf("Theme-Element `%s`: erwartet %s, bekommen %s.", el, describe_element(se), describe_element(ue)))
  }
  r <- all.equal(props(ue), props(se))
  if (isTRUE(r)) return(NULL)
  if (is.atomic(se)) {
    return(sprintf("Theme-Element `%s`: erwartet %s, bekommen %s.", el, describe_element(se), describe_element(ue)))
  }
  up <- props(ue); sp2 <- props(se)
  diff <- Filter(function(n) !isTRUE(all.equal(up[[n]], sp2[[n]])), names(sp2))
  sprintf("Theme-Element `%s`: %s.", el, paste(vapply(diff, function(n) {
    sprintf("`%s` erwartet %s, bekommen %s", n, format(sp2[[n]])[1], format(up[[n]])[1])
  }, ""), collapse = "; "))
}

describe_element <- function(e) {
  if (is.null(e)) return("nichts")
  if (inherits(e, "S7_object")) return(sub("^ggplot2::", "", class(e)[1]))
  paste(format(e), collapse = ", ")
}

