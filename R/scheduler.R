leitner_intervals <- c(0, 1, 3, 7, 21)

#' Initial scheduling state
#' @export
new_state <- function() {
  list(box = 1L, ease = 2.5, interval = 0, reps = 0L, due = Sys.Date())
}

#' Compute next scheduling state
#'
#' @param state List from [new_state()].
#' @param result `list(correct = TRUE/FALSE, rating = "easy"|"ok"|"hard")`.
#' @param scheduler `"leitner"` or `"sm2"`.
#' @param today Date (injectable for tests).
#' @return Updated state with new `due` date.
#' @export
next_due <- function(state, result, scheduler = c("leitner", "sm2"), today = Sys.Date()) {
  scheduler <- match.arg(scheduler)
  switch(scheduler,
    leitner = leitner_next(state, result, today),
    sm2 = sm2_next(state, result, today)
  )
}

leitner_next <- function(state, result, today) {
  box <- state$box %||% 1L
  # Correct + easy: up; correct + ok: stay; correct + hard: down one; wrong: box 1
  box <- if (!isTRUE(result$correct)) 1L else
    switch(result$rating %||% "ok",
           easy = min(box + 1L, 5L), ok = box, hard = max(box - 1L, 1L))
  state$box <- as.integer(box)
  state$interval <- leitner_intervals[box]
  state$due <- today + state$interval
  state
}

sm2_next <- function(state, result, today) {
  q <- if (!isTRUE(result$correct)) 1 else
    switch(result$rating %||% "ok", easy = 5, ok = 4, hard = 3)
  if (q < 3) {
    state$reps <- 0L; state$interval <- 1
  } else {
    state$reps <- state$reps + 1L
    state$interval <- switch(min(state$reps, 3L), 1, 6, round(state$interval * state$ease))
  }
  state$ease <- max(1.3, state$ease + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
  state$due <- today + state$interval
  state
}
