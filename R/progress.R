# Progress is stored as one JSON file. Writes are atomic (tmp file + rename).
# Override the location with options(rtrainer.data_dir = "...") (used in tests).

progress_path <- function() {
  dir <- getOption("rtrainer.data_dir", tools::R_user_dir("rtrainer", "data"))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, "progress.json")
}

new_progress <- function(scheduler = "leitner") {
  list(version = 1L, scheduler = scheduler, items = list(), log = list())
}

#' Load saved progress (empty if none exists or file is corrupt)
#' @export
load_progress <- function() {
  f <- progress_path()
  if (!file.exists(f)) return(new_progress())
  p <- tryCatch(jsonlite::read_json(f, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(p) || is.null(p$items)) {
    file.copy(f, paste0(f, ".bak"), overwrite = TRUE)
    cli::cli_warn("Fortschrittsdatei besch\u00e4digt, Sicherung unter {.file {paste0(f, '.bak')}}.")
    return(new_progress())
  }
  p$items <- p$items %||% list()
  p$log <- p$log %||% list()
  p
}

#' Save progress atomically
#' @param p Progress list.
#' @export
save_progress <- function(p) {
  f <- progress_path()
  tmp <- paste0(f, ".tmp")
  jsonlite::write_json(p, tmp, auto_unbox = TRUE, pretty = TRUE, null = "null")
  file.rename(tmp, f)
  invisible(p)
}

#' Delete all saved progress
#' @export
reset_progress <- function() {
  unlink(progress_path())
  invisible(TRUE)
}

item_state <- function(p, id) {
  it <- p$items[[id]]
  if (is.null(it)) {
    s <- new_state()
    s$due <- format(s$due)
    it <- c(s, list(attempts = 0L, correct = 0L, solved = FALSE, seen = FALSE))
  }
  it
}

#' Record one attempt (check result) in the log
#'
#' Wrong answers reset the schedule immediately. Correct answers are
#' scheduled once [record_rating()] is called.
#' @param p Progress list.
#' @param ex Exercise.
#' @param correct Logical.
#' @param hints Number of hints used.
#' @param scheduler `"leitner"` or `"sm2"`.
#' @param now POSIXct (injectable for tests).
#' @param confidence Self-rated confidence before checking: 1 (unsure) to 3 (sure), or `NA`.
#' @param mistake Optional message of the matched `common_mistakes` entry
#'   (feeds the error journal).
#' @export
record_attempt <- function(p, ex, correct, hints = 0L, scheduler = p$scheduler,
                           now = Sys.time(), confidence = NA_integer_, mistake = NULL) {
  it <- item_state(p, ex$id)
  it$attempts <- it$attempts + 1L
  it$seen <- TRUE
  if (isTRUE(correct)) {
    it$correct <- it$correct + 1L
    it$solved <- TRUE
  } else {
    it <- schedule_item(it, list(correct = FALSE), scheduler, as.Date(now))
  }
  p$items[[ex$id]] <- it
  entry <- list(
    time = format(now, "%Y-%m-%dT%H:%M:%S"), id = ex$id, topic = ex$topic,
    tags = as.list(ex$tags), correct = isTRUE(correct), hints = as.integer(hints)
  )
  if (!is.na(confidence)) entry$confidence <- as.integer(confidence)
  if (!isTRUE(correct) && length(mistake) && nzchar(mistake)) entry$mistake <- mistake
  p$log[[length(p$log) + 1L]] <- entry
  p
}

#' Record the difficulty rating after a solved exercise
#' @param p Progress list.
#' @param id Exercise id.
#' @param rating `"easy"`, `"ok"` or `"hard"`.
#' @param scheduler `"leitner"` or `"sm2"`.
#' @param today Date.
#' @param hints Number of hints used for this exercise.
#' @export
record_rating <- function(p, id, rating = c("ok", "easy", "hard"), scheduler = p$scheduler,
                          today = Sys.Date(), hints = 0L) {
  rating <- match.arg(rating)
  # Solving with >= 2 hints is not 'easy' (avoids over-promoting weak items)
  if (rating == "easy" && hints >= 2L) rating <- "ok"
  p$items[[id]] <- schedule_item(item_state(p, id), list(correct = TRUE, rating = rating),
                                 scheduler, today)
  p
}

schedule_item <- function(it, result, scheduler, today) {
  st <- next_due(it[c("box", "ease", "interval", "reps", "due")], result, scheduler, today)
  it[names(st)] <- st
  it$due <- format(as.Date(it$due))
  it
}

#' IDs of exercises due for review (seen before and due date reached)
#' @param p Progress list.
#' @param today Date.
#' @export
due_ids <- function(p, today = Sys.Date()) {
  ids <- names(p$items) %||% character()
  keep <- vapply(ids, function(i) {
    it <- p$items[[i]]
    isTRUE(it$seen) && as.Date(it$due) <= today
  }, logical(1))
  ids[keep]
}

#' Mastered = solved and in Leitner box >= 4 (or SM-2 interval >= 7 days)
#' @param p Progress list.
#' @param id Exercise id.
#' @export
is_mastered <- function(p, id) {
  it <- p$items[[id]]
  !is.null(it) && isTRUE(it$solved) && (it$box >= 4L || it$interval >= 7)
}

#' Was this a confident error? (triggers elaborated feedback)
#' @param correct Logical.
#' @param confidence 1-3 or `NA`.
#' @export
is_confident_error <- function(correct, confidence) {
  !isTRUE(correct) && !is.na(confidence) && confidence >= 3
}

#' Reorder ids so that neighbouring exercises come from different topics
#'
#' Interleaved practice supports long-term retention and transfer.
#' @param ids Character vector of exercise ids.
#' @param topics Named character vector (names = ids) with topics.
#' @export
interleave_topics <- function(ids, topics) {
  out <- character()
  pool <- ids
  while (length(pool)) {
    last <- if (length(out)) topics[[out[length(out)]]] else NA_character_
    tp <- unname(topics[pool])
    # Greedy: take the most frequent remaining topic that differs from the last
    # one; plain "first different" fails e.g. for A, B, C, C.
    counts <- table(factor(tp, levels = unique(tp)))
    cand <- if (is.na(last)) counts else counts[names(counts) != last]
    pick <- if (length(cand)) names(cand)[which.max(cand)] else tp[1]
    i <- match(pick, tp)
    out <- c(out, pool[i])
    pool <- pool[-i]
  }
  out
}

#' Pick exercises for a session
#'
#' Due repetitions first, then new exercises mixed across levels; the result
#' is interleaved by topic.
#' @param exercises Named list from [load_exercises()].
#' @param p Progress list.
#' @param n Number of exercises.
#' @param topics Optional topic filter.
#' @param today Date.
#' @param seed Optional seed.
#' @export
pick_session <- function(exercises, p, n = 10, topics = NULL, today = Sys.Date(), seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  if (!is.null(topics)) {
    exercises <- Filter(function(e) e$topic %in% topics, exercises)
  }
  ids <- names(exercises)
  due <- intersect(due_ids(p, today), ids)
  due <- due[order(vapply(due, function(i) as.numeric(as.Date(p$items[[i]]$due)), 0))]
  due <- utils::head(due, ceiling(n / 2))
  fresh <- setdiff(ids, names(p$items))
  lv <- vapply(exercises[fresh], function(e) as.integer(e$level), 0L)
  by_lv <- lapply(split(fresh, lv), function(x) if (length(x) > 1) sample(x) else x)
  # Interleave levels 1,2,3,1,2,3,...
  mixed <- character()
  while (any(lengths(by_lv) > 0)) {
    for (k in seq_along(by_lv)) {
      if (length(by_lv[[k]])) {
        mixed <- c(mixed, by_lv[[k]][1]); by_lv[[k]] <- by_lv[[k]][-1]
      }
    }
  }
  sel <- utils::head(c(due, mixed), n)
  if (length(sel) < n) {  # fill with non-mastered seen exercises
    rest <- setdiff(ids[!vapply(ids, is_mastered, TRUE, p = p)], sel)
    sel <- utils::head(c(sel, rest), n)
  }
  interleave_topics(sel, vapply(exercises, function(e) e$topic, ""))
}

#' Progress statistics for the dashboard
#' @param p Progress list.
#' @param today Date.
#' @return list(log, streak, per_week, by_topic, weak_tags, calibration)
#' @export
progress_stats <- function(p, today = Sys.Date()) {
  empty <- list(log = data.frame(), streak = 0L,
                per_week = data.frame(week = character(), n = integer()),
                by_topic = data.frame(topic = character(), rate = numeric(), n = integer()),
                weak_tags = data.frame(tag = character(), rate = numeric(), n = integer()),
                calibration = data.frame(confidence = integer(), rate = numeric(), n = integer()))
  if (!length(p$log)) return(empty)
  log <- do.call(rbind, lapply(p$log, function(e) data.frame(
    time = as.POSIXct(e$time, format = "%Y-%m-%dT%H:%M:%S"), id = e$id, topic = e$topic,
    correct = isTRUE(e$correct), hints = e$hints %||% 0L,
    confidence = as.integer(e$confidence %||% NA_integer_),
    tags = paste(unlist(e$tags), collapse = ","), stringsAsFactors = FALSE)))
  log$date <- as.Date(log$time)

  days <- sort(unique(log$date), decreasing = TRUE)
  streak <- 0L
  expected <- if (days[1] == today || days[1] == today - 1) days[1] else NULL
  if (!is.null(expected)) {
    for (d in as.list(days)) {
      if (d == expected) { streak <- streak + 1L; expected <- expected - 1 } else break
    }
  }
  wk <- format(log$date, "%G-W%V")
  per_week <- as.data.frame(table(week = wk), responseName = "n", stringsAsFactors = FALSE)

  r <- stats::aggregate(correct ~ topic, data = log, FUN = mean)
  bt <- data.frame(topic = r$topic, rate = r$correct,
                   n = as.integer(table(log$topic)[r$topic]))

  tg <- do.call(rbind, lapply(seq_len(nrow(log)), function(i) {
    t <- strsplit(log$tags[i], ",")[[1]]
    if (length(t)) data.frame(tag = t, correct = log$correct[i]) else NULL
  }))
  wt <- if (is.null(tg)) empty$weak_tags else {
    r <- stats::aggregate(correct ~ tag, tg, mean)
    out <- data.frame(tag = r$tag, rate = r$correct, n = as.integer(table(tg$tag)[r$tag]))
    out <- out[out$n >= 2, , drop = FALSE]
    utils::head(out[order(out$rate), , drop = FALSE], 5)
  }

  # Calibration: success rate per self-rated confidence level
  cal <- empty$calibration
  has_conf <- !is.na(log$confidence)
  if (any(has_conf)) {
    cl <- log[has_conf, , drop = FALSE]
    r <- stats::aggregate(correct ~ confidence, data = cl, FUN = mean)
    cal <- data.frame(confidence = r$confidence, rate = r$correct,
                      n = as.integer(table(cl$confidence)[as.character(r$confidence)]))
  }
  list(log = log, streak = streak, per_week = per_week, by_topic = bt, weak_tags = wt,
       calibration = cal)
}

#' Store a short self-explanation note for an exercise
#'
#' Notes are not graded; they only support elaboration.
#' @param p Progress list.
#' @param id Exercise id.
#' @param note Character string.
#' @export
record_note <- function(p, id, note) {
  it <- item_state(p, id)
  it$note <- trimws(note)
  p$items[[id]] <- it
  p
}

#' Error journal: most frequent mistakes from wrong attempts
#'
#' Uses the matched `common_mistakes` message of an attempt if logged,
#' otherwise the exercise's `misconception`.
#' @param p Progress list.
#' @param exercises Named list from [load_exercises()].
#' @param n Maximum number of rows.
#' @return data.frame(mistake, topic, n)
#' @export
error_journal <- function(p, exercises, n = 10) {
  empty <- data.frame(mistake = character(), topic = character(), n = integer())
  wrong <- Filter(function(e) !isTRUE(e$correct), p$log)
  txt <- vapply(wrong, function(e) {
    e$mistake %||% exercises[[e$id]]$misconception %||% ""
  }, "")
  topic <- vapply(wrong, function(e) e$topic %||% "", "")
  keep <- nzchar(txt)
  if (!any(keep)) return(empty)
  d <- data.frame(mistake = txt[keep], topic = topic[keep])
  r <- stats::aggregate(list(n = rep(1L, nrow(d))), d, length)
  r <- r[order(-r$n, r$mistake), , drop = FALSE]
  rownames(r) <- NULL
  utils::head(r, n)
}

#' Daily activity counts for a heatmap
#' @param log `progress_stats()$log`.
#' @param today Date.
#' @param weeks Number of weeks to show.
#' @return data.frame(date, week, weekday, n) with one row per day.
#' @export
activity_grid <- function(log, today = Sys.Date(), weeks = 12) {
  start <- today - weeks * 7 + 1
  days <- seq(start, today, by = "day")
  n <- if (nrow(log)) as.integer(table(factor(as.character(log$date), as.character(days)))) else 0L
  # Monday-based weekday 1-7 and week index counted from the first day
  wd <- as.integer(format(days, "%u"))
  data.frame(date = days, week = as.integer(days - start + wd[1] - 1) %/% 7 + 1L,
             weekday = wd, n = n)
}
