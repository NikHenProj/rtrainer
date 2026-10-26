#' Validate an exercise definition
#' @param ex Named list (parsed YAML).
#' @param file Optional file name for error messages.
#' @return `ex` with defaults filled in.
#' @export
validate_exercise <- function(ex, file = NULL) {
  where <- if (is.null(file)) "" else paste0(" (", basename(file), ")")
  req <- c("id", "topic", "title", "level", "prompt", "solution", "check")
  miss <- setdiff(req, names(ex))
  if (length(miss)) {
    cli::cli_abort("Pflichtfelder fehlen{where}: {.field {miss}}")
  }
  if (!is.character(ex$id) || length(ex$id) != 1 || !grepl("^[a-z0-9_-]+$", ex$id)) {
    cli::cli_abort("`id` muss ein String aus [a-z0-9_-] sein{where}.")
  }
  if (!ex$level %in% 1:3) {
    cli::cli_abort("`level` muss 1, 2 oder 3 sein{where}.")
  }
  types <- c("value", "output", "object", "function", "regex", "ast", "plot")
  if (!ex$check$type %in% types) {
    cli::cli_abort("Unbekannter check-Typ {.val {ex$check$type}}{where}. Erlaubt: {types}")
  }
  if (ex$check$type == "object" && is.null(ex$check$name)) {
    cli::cli_abort("check.type 'object' braucht `check.name`{where}.")
  }
  if (ex$check$type == "function" && (is.null(ex$check$name) || is.null(ex$check$tests))) {
    cli::cli_abort("check.type 'function' braucht `name` und `tests`{where}.")
  }
  kinds <- c("write", "predict", "debug", "complete")
  ex$kind <- ex$kind %||% "write"
  if (!ex$kind %in% kinds) {
    cli::cli_abort("`kind` muss eines von {kinds} sein{where}.")
  }
  if (!is.null(ex$bugs) && !(is.numeric(ex$bugs) && length(ex$bugs) == 1 &&
                              ex$bugs >= 1 && ex$bugs == round(ex$bugs))) {
    cli::cli_abort("`bugs` muss eine ganze Zahl >= 1 sein{where}.")
  }
  ex$misconception <- ex$misconception %||% ""
  ex$setup <- ex$setup %||% ""
  ex$starter <- ex$starter %||% ""
  ex$hints <- as.list(ex$hints %||% list())
  ex$tags <- unlist(ex$tags %||% character())
  ex$packages <- unlist(ex$packages %||% character())
  ex$seed <- ex$seed %||% 1L
  ex$explanation <- ex$explanation %||% ""
  ex$common_mistakes <- ex$common_mistakes %||% list()
  ex$timeout <- ex$timeout %||% 10
  ex
}

# YAML 1.1 reads bare `y`/`n` as booleans; in exercises they are almost
# always aesthetics (`mapping: {x: a, y: b}`), so they stay strings.
yaml_handlers <- list(
  "bool#yes" = function(x) if (tolower(x) == "y") x else TRUE,
  "bool#no" = function(x) if (tolower(x) == "n") x else FALSE
)

#' Read one exercise YAML file
#' @param path Path to a `.yml` file.
#' @export
read_exercise <- function(path) {
  ex <- tryCatch(
    yaml::read_yaml(path, handlers = yaml_handlers),
    error = function(e) cli::cli_abort("YAML nicht lesbar: {basename(path)}: {conditionMessage(e)}")
  )
  ex <- validate_exercise(ex, path)
  ex$file <- path
  ex
}

#' Load all exercises from the package and registered directories
#' @param dirs Extra directories (recursive).
#' @export
load_exercises <- function(dirs = NULL) {
  base <- system.file("exercises", package = "rtrainer")
  dirs <- c(base[nzchar(base)], dirs, registered_dirs())
  files <- unlist(lapply(dirs, list.files, pattern = "\\.ya?ml$",
                         recursive = TRUE, full.names = TRUE))
  exs <- lapply(files, read_exercise)
  ids <- vapply(exs, `[[`, "", "id")
  if (anyDuplicated(ids)) {
    cli::cli_abort("Doppelte Aufgaben-IDs: {unique(ids[duplicated(ids)])}")
  }
  stats::setNames(exs, ids)
}
