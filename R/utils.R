`%||%` <- function(x, y) if (is.null(x)) y else x

# Registry of user exercise directories (persisted in config dir)
registered_dirs <- function() {
  f <- file.path(tools::R_user_dir("rtrainer", "config"), "dirs.json")
  if (file.exists(f)) jsonlite::read_json(f, simplifyVector = TRUE) else character()
}

#' Register a directory with custom exercises
#' @param path Directory containing YAML files.
#' @export
add_exercise_dir <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  d <- tools::R_user_dir("rtrainer", "config")
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  dirs <- unique(c(registered_dirs(), path))
  jsonlite::write_json(dirs, file.path(d, "dirs.json"))
  invisible(dirs)
}
