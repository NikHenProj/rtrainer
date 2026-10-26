local_progress_dir <- function(env = parent.frame()) {
  d <- withr::local_tempdir(.local_envir = env)
  withr::local_options(rtrainer.data_dir = d, .local_envir = env)
  d
}
mk_ex <- function(id = "a", topic = "t", tags = c("x", "y"), level = 1L) {
  list(id = id, topic = topic, tags = tags, level = level)
}

fixture_exercises <- function() {
  load_exercises(test_path("fixtures", "exercises"))
}
