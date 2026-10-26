# Translate common R errors into short German explanations
translate_error <- function(msg, timed_out = FALSE) {
  if (timed_out) return(msg)
  rules <- list(
    c("object '(.+)' not found", "Das Objekt `\\1` gibt es nicht. Tippfehler oder noch nicht definiert?"),
    c("could not find function \"(.+)\"", "Die Funktion `\\1` ist nicht bekannt. Paket mit `library()` geladen oder Tippfehler?"),
    c("non-numeric argument to binary operator", "Du rechnest mit etwas Nicht-Numerischem (Text oder Faktor?). Pr\u00fcfe mit `str()`."),
    c("unexpected (.+)", "Syntaxfehler: unerwartetes `\\1`. Klammern, Kommas und Pipes pr\u00fcfen."),
    c("there is no package called .(.+).", "Das Paket `\\1` ist nicht installiert: `install.packages(\"\\1\")`.")
  )
  for (r in rules) {
    if (grepl(r[1], msg)) return(paste0("Fehler: ", sub(paste0(".*", r[1], ".*"), r[2], msg)))
  }
  paste0("Fehler: ", msg)
}

#' Line-based text diff for the feedback box
#'
#' Marks the first differing line and shows expected vs. got.
#' @param expected,got Character strings.
#' @export
text_diff <- function(expected, got) {
  e <- strsplit(trimws(expected), "\n")[[1]]
  g <- strsplit(trimws(got), "\n")[[1]]
  n <- max(length(e), length(g))
  e <- c(e, rep(NA_character_, n - length(e)))
  g <- c(g, rep(NA_character_, n - length(g)))
  bad <- which(is.na(e) | is.na(g) | trimws(e) != trimws(g))
  if (!length(bad)) return("Keine Unterschiede.")
  i <- bad[1]
  show <- function(x) if (is.na(x)) "(nichts)" else x
  sprintf("Erste Abweichung in Zeile %d:\n  erwartet: %s\n  bekommen: %s", i, show(e[i]), show(g[i]))
}

# Next hint (stepwise); returns NULL if exhausted
next_hint <- function(exercise, shown) {
  h <- exercise$hints
  if (shown >= length(h)) NULL else h[[shown + 1L]]
}

#' Elaborated feedback for confident errors
#'
#' Combines check message, misconception and explanation (shown after a wrong
#' answer that was given with high confidence).
#' @param exercise Exercise list.
#' @param check_result Result of [check_exercise()].
#' @export
elaborated_feedback <- function(exercise, check_result) {
  parts <- c(
    "Das hattest du sicher erwartet, es stimmt aber nicht:",
    check_result$message,
    if (nzchar(exercise$misconception)) paste0("H\u00e4ufige Fehlvorstellung: ", exercise$misconception),
    if (nzchar(exercise$explanation)) paste0("Erkl\u00e4rung: ", trimws(exercise$explanation))
  )
  paste(parts, collapse = "\n\n")
}
