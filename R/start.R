#' Start the trainer app
#'
#' @param mode `"daily"`: mixed session of due repetitions and new exercises
#'   (topics interleaved). `"free"`: choose and filter exercises freely.
#'   `"exam"`: no hints or solutions, timer, overall result.
#' @param n Number of exercises (default 10, exam 15).
#' @param time_limit Exam time limit in minutes.
#' @param topics Optional topic filter. Restricts daily and exam sessions and
#'   preselects the topic filter in free mode (changeable there).
#' @param dirs Extra exercise directories (see [add_exercise_dir()]).
#' @param launch.browser,port Passed to [shiny::runApp()].
#' @return Called for its side effect (runs the app).
#' @examples
#' if (interactive()) {
#'   start()
#'   start("exam", n = 15, time_limit = 30)
#' }
#' @export
start <- function(mode = c("daily", "free", "exam"), n = NULL, time_limit = 30,
                  topics = NULL, dirs = NULL, launch.browser = TRUE,
                  port = getOption("shiny.port")) {
  app <- rtrainer_app(mode, n = n, time_limit = time_limit, topics = topics, dirs = dirs)
  shiny::runApp(app, launch.browser = launch.browser, port = port)
}

#' Build the trainer app object without running it
#'
#' Useful for [shinytest2::AppDriver] or deployment.
#' @inheritParams start
#' @param exercises Named list of exercises (default: [load_exercises()]).
#' @return A `shiny.appobj`.
#' @export
rtrainer_app <- function(mode = c("daily", "free", "exam"), n = NULL, time_limit = 30,
                         topics = NULL, dirs = NULL, exercises = load_exercises(dirs)) {
  mode <- match.arg(mode)
  if (!length(exercises)) cli::cli_abort("Keine Aufgaben gefunden.")
  n <- n %||% if (mode == "exam") 15L else 10L
  p <- load_progress()
  shiny::shinyApp(
    ui = app_ui(exercises, mode, show_confidence = p$settings$confidence %||% TRUE,
                selected_topics = topics),
    server = app_server(exercises, mode, n = n, time_limit = time_limit, topics = topics)
  )
}
