# Pure helpers for the Shiny app. Kept free of reactives so they can be
# tested directly; app_server() only wires them together.

# ---- session queue --------------------------------------------------------

new_queue <- function(ids) list(ids = as.character(ids), pos = 1L)

queue_current <- function(q) if (q$pos <= length(q$ids)) q$ids[[q$pos]] else NULL

queue_done <- function(q) q$pos > length(q$ids)

queue_advance <- function(q) {
  q$pos <- min(q$pos + 1L, length(q$ids) + 1L)
  q
}

# Show an exercise again later in this session (Box-1 repetition after a
# confident error). No-op if it is already queued after the current one.
queue_requeue <- function(q, id) {
  later <- if (q$pos < length(q$ids)) q$ids[(q$pos + 1L):length(q$ids)] else character()
  if (!id %in% later) q$ids <- c(q$ids, id)
  q
}

queue_jump <- function(q, id) {
  i <- match(id, q$ids)
  if (is.na(i)) {
    q$ids <- append(q$ids, id, after = q$pos - 1L)
  } else {
    q$pos <- i
  }
  q
}

# ---- exercise filtering ---------------------------------------------------

filter_exercises <- function(exercises, p, topics = NULL, levels = NULL, tags = NULL,
                             only_due = FALSE, today = Sys.Date()) {
  keep <- vapply(exercises, function(e) {
    (!length(topics) || e$topic %in% topics) &&
      (!length(levels) || as.integer(e$level) %in% as.integer(levels)) &&
      (!length(tags) || any(e$tags %in% tags))
  }, logical(1))
  ids <- names(exercises)[keep]
  if (isTRUE(only_due)) ids <- intersect(ids, due_ids(p, today))
  ids
}

random_exercise <- function(ids, p) {
  open <- ids[!vapply(ids, is_mastered, logical(1), p = p)]
  if (!length(open)) return(NULL)
  open[sample.int(length(open), 1L)]
}

topic_progress <- function(exercises, p) {
  topic <- vapply(exercises, `[[`, "", "topic")
  solved <- vapply(names(exercises), function(i) isTRUE(p$items[[i]]$solved), logical(1))
  mastered <- vapply(names(exercises), is_mastered, logical(1), p = p)
  tp <- sort(unique(topic))
  data.frame(
    topic = tp,
    total = as.integer(table(factor(topic, tp))),
    solved = vapply(tp, function(t) sum(solved[topic == t]), 0L),
    mastered = vapply(tp, function(t) sum(mastered[topic == t]), 0L),
    row.names = NULL
  )
}

# ---- feedback -------------------------------------------------------------

feedback_status <- function(correct, warning = FALSE) {
  if (warning) "warning" else if (isTRUE(correct)) "success" else "danger"
}

# Colour AND symbol, so the status never relies on colour alone
feedback_box <- function(status = c("success", "danger", "warning"), title, body = NULL,
                         emphasis = FALSE) {
  status <- match.arg(status)
  icon <- c(success = "\u2713", danger = "\u2717", warning = "!")[[status]]
  shiny::div(
    class = paste0("alert alert-", status, " rt-feedback", if (emphasis) " rt-emphasis"),
    role = if (status == "danger") "alert" else "status",
    shiny::span(class = "rt-icon", `aria-hidden` = "true", icon),
    shiny::strong(title),
    if (length(body) && any(nzchar(body))) shiny::pre(class = "rt-msg", paste(body, collapse = "\n"))
  )
}

check_feedback <- function(exercise, result, confidence = NA) {
  if (isTRUE(result$correct)) {
    return(feedback_box("success", "Richtig!", if (result$message != "Richtig!") result$message))
  }
  if (is_confident_error(result$correct, confidence)) {
    return(feedback_box("danger", "Sicher, aber falsch \u2013 genau hinsehen lohnt sich",
                        elaborated_feedback(exercise, result), emphasis = TRUE))
  }
  feedback_box("danger", "Noch nicht richtig", result$message)
}

# Console text from a run_code() result
console_text <- function(res) {
  parts <- c(
    if (nzchar(res$output)) res$output,
    if (length(res$messages)) paste0("Meldung: ", trimws(res$messages)),
    if (length(res$warnings)) paste0("Warnung: ", res$warnings),
    if (!is.null(res$error)) translate_error(res$error, res$timed_out)
  )
  if (!length(parts)) "(keine Ausgabe)" else paste(trimws(parts, "right"), collapse = "\n")
}

hint_label <- function(shown, total) {
  if (!total) "Keine Hinweise" else sprintf("Hinweis (%d/%d)", shown, total)
}

# ---- exam -----------------------------------------------------------------

exam_summary <- function(ids, results, exercises) {
  res <- vapply(ids, function(i) {
    if (is.null(results[[i]])) "\u2013 nicht bearbeitet"
    else if (isTRUE(results[[i]])) "\u2713 richtig" else "\u2717 falsch"
  }, "")
  data.frame(
    Aufgabe = vapply(ids, function(i) exercises[[i]]$title, ""),
    Thema = vapply(ids, function(i) exercises[[i]]$topic, ""),
    Ergebnis = unname(res),
    row.names = NULL
  )
}

format_remaining <- function(secs) {
  secs <- max(0, round(secs))
  sprintf("%02d:%02d", secs %/% 60, secs %% 60)
}
