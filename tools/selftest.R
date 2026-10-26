# Self-test of all exercises in normal R: the solution must pass the check,
# the starter must fail it. Uses the same check code as the browser.
#
#   Rscript tools/selftest.R            # all exercises
#   Rscript tools/selftest.R gc-b-ttest # only these ids

if (!exists("rt_check")) source("tools/checks.R")
if (!exists("generate")) source("tools/generate.R")

# Evaluate code like quarto-live: in a child of `parent`, keep the last value.
run_code <- function(code, parent) {
  env <- new.env(parent = parent)
  value <- tryCatch(
    withVisible(eval(parse(text = code), envir = env))$value,
    error = function(e) structure(list(message = conditionMessage(e)), class = "rt_error")
  )
  list(env = env, value = value)
}

# Run one exercise; returns a one-row data frame with the outcome.
selftest_exercise <- function(ex, datasets, root = ".", lang = "de") {
  workdir <- tempfile("rt-selftest-")
  dir.create(file.path(workdir, "data"), recursive = TRUE)
  on.exit(unlink(workdir, recursive = TRUE), add = TRUE)
  for (d in unlist(ex$data)) {
    file.copy(file.path(root, "data", datasets[[d]]$file), file.path(workdir, "data"))
  }
  old_wd <- setwd(workdir)
  on.exit(setwd(old_wd), add = TRUE, after = FALSE)

  prep <- new.env(parent = globalenv())
  setup <- paste(c(data_loader(ex$data, datasets), ex$setup), collapse = "\n")
  suppressMessages(eval(parse(text = setup), envir = prep))

  started <- Sys.time()
  solution <- suppressMessages(run_code(ex$solution, prep))
  seconds <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  starter <- suppressMessages(run_code(ex$starter, prep))

  grade <- function(attempt, code) {
    if (inherits(attempt$value, "rt_error") && identical(code, ex$solution)) {
      return(rt_feedback(FALSE, paste("solution error:", attempt$value$message)))
    }
    value <- if (inherits(attempt$value, "rt_error")) NULL else attempt$value
    rt_checker(
      label = exercise_label(ex$id),
      user_code = code,
      check_code = check_code(ex, lang),
      envir_result = attempt$env,
      last_value = value,
      solution = solution$value,
      envir_solution = solution$env
    )
  }
  solution_grade <- grade(solution, ex$solution)
  starter_grade <- grade(starter, ex$starter)

  data.frame(
    id = ex$id,
    solution_passes = isTRUE(solution_grade$correct),
    starter_fails = !isTRUE(starter_grade$correct),
    seconds = round(seconds, 2),
    message = if (!isTRUE(solution_grade$correct)) {
      solution_grade$message
    } else if (isTRUE(starter_grade$correct)) {
      "starter passes the check"
    } else {
      ""
    }
  )
}

selftest <- function(root = ".", ids = NULL) {
  course <- read_course(root)
  problems <- validate_course(course, langs = character())
  if (length(problems) > 0) {
    stop("Invalid course content:\n", paste0("- ", problems, collapse = "\n"), call. = FALSE)
  }
  exercises <- unlist(lapply(course$lessons, function(l) l$exercises), recursive = FALSE)
  if (!is.null(ids)) {
    exercises <- Filter(function(ex) ex$id %in% ids, exercises)
  }
  for (ex in exercises) {
    for (pkg in unlist(ex$packages)) {
      suppressPackageStartupMessages(library(pkg, character.only = TRUE))
    }
  }
  results <- lapply(exercises, selftest_exercise, datasets = course$datasets, root = root)
  do.call(rbind, results)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  results <- selftest(".", ids = if (length(args) > 0) args else NULL)
  ok <- results$solution_passes & results$starter_fails
  for (i in seq_len(nrow(results))) {
    r <- results[i, ]
    cat(sprintf(
      "%s %-28s %5.2fs %s\n",
      if (ok[i]) "ok  " else "FAIL", r$id, r$seconds, r$message
    ))
    if (r$seconds > 5) cat("     warning: solution takes > 5 s; much slower in the browser\n")
  }
  cat(sprintf("\n%d/%d exercises ok\n", sum(ok), length(ok)))
  if (!all(ok)) quit(status = 1)
}
