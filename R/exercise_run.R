#' Run user code safely in a fresh R process
#'
#' Not a security sandbox: it only protects the app from accidents
#' (errors, infinite loops, `q()`). Working dir is a temp dir, but absolute
#' paths remain accessible.
#'
#' @param code User code (string).
#' @param exercise Exercise list (uses setup, packages, seed, timeout).
#' @param timeout Seconds.
#' @param plot_dir Optional directory; plots are then saved there as PNG files
#'   (recorded plots cannot be replayed reliably in another process).
#' @return list(ok, timed_out, value, has_value, output, messages, warnings,
#'   error, env (named list of objects), results (evaluate output), plots
#'   (PNG paths))
#' @export
run_code <- function(code, exercise = list(), timeout = exercise$timeout %||% 10,
                     plot_dir = NULL) {
  tmp <- tempfile("rtrainer-")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  worker <- function(code, setup, packages, seed, tmp, plot_dir, extdata, post) {
    setwd(tmp)
    set.seed(seed)
    for (p in packages) suppressPackageStartupMessages(library(p, character.only = TRUE))
    # The worker is a fresh process, so code runs in the global environment
    # like in a normal session: update(), allFit(), drop1() re-evaluate
    # calls there and must find the data.
    env <- globalenv()
    # rtrainer itself may not be installed in the worker (e.g. load_all())
    env$rtrainer_data <- function(name) {
      f <- file.path(extdata, name)
      if (!file.exists(f)) stop("Datei nicht gefunden: ", name, call. = FALSE)
      f
    }
    if (nzchar(setup)) eval(parse(text = setup), envir = env)
    last <- NULL
    has_value <- FALSE
    handler <- evaluate::new_output_handler(
      value = function(x, visible) {
        last <<- x
        has_value <<- TRUE
        if (visible) print(x)
        invisible()
      }
    )
    res <- evaluate::evaluate(code, envir = env, new_device = TRUE,
                              stop_on_error = 1, output_handler = handler)
    post_value <- NULL
    if (nzchar(post) && !any(vapply(res, inherits, TRUE, "error"))) {
      post_value <- tryCatch(eval(parse(text = post), envir = env), error = function(e) {
        structure(conditionMessage(e), class = "post_error")
      })
    }
    plots <- character()
    if (nzchar(plot_dir)) {
      recorded <- Filter(function(x) inherits(x, "recordedplot"), res)
      for (i in seq_along(recorded)) {
        f <- tempfile("plot-", tmpdir = plot_dir, fileext = ".png")
        grDevices::png(f, width = 800, height = 500, res = 110)
        grDevices::replayPlot(recorded[[i]])
        grDevices::dev.off()
        plots <- c(plots, f)
      }
    }
    objs <- as.list(env, all.names = FALSE)
    objs$rtrainer_data <- NULL
    list(results = res, value = last, has_value = has_value,
         env = objs, plots = plots, post = post_value)
  }

  out <- tryCatch(
    callr::r(worker, timeout = timeout, spinner = FALSE,
             args = list(code = code, setup = exercise$setup %||% "",
                         packages = exercise$packages %||% character(),
                         seed = exercise$seed %||% 1L, tmp = tmp,
                         plot_dir = plot_dir %||% "",
                         post = exercise$check$post %||% "",
                         extdata = system.file("extdata", package = "rtrainer"))),
    error = function(e) e
  )

  # q()/quit() in user code ends the worker without error and returns NULL
  if (!inherits(out, "error") && !is.list(out)) {
    out <- simpleError("Die R-Sitzung wurde beendet (q() oder quit()?).")
  }
  if (inherits(out, "error")) {
    timed_out <- inherits(out, "callr_timeout_error")
    msg <- if (timed_out) {
      sprintf("Zeitlimit von %s s \u00fcberschritten (Endlosschleife?).", timeout)
    } else {
      conditionMessage(out)
    }
    return(list(ok = FALSE, timed_out = timed_out, error = msg, output = "",
                messages = character(), warnings = character(),
                value = NULL, has_value = FALSE, env = list(), results = list(),
                plots = character()))
  }
  summarise_results(out)
}

summarise_results <- function(out) {
  res <- out$results
  is_chr <- vapply(res, is.character, logical(1))
  err <- Filter(function(x) inherits(x, "error"), res)
  list(
    ok = length(err) == 0,
    timed_out = FALSE,
    error = if (length(err)) conditionMessage(err[[1]]) else NULL,
    error_call = if (length(err)) deparse(conditionCall(err[[1]]))[1] else NULL,
    output = paste(unlist(res[is_chr]), collapse = ""),
    messages = vapply(Filter(function(x) inherits(x, "message"), res),
                      conditionMessage, ""),
    warnings = vapply(Filter(function(x) inherits(x, "warning"), res),
                      conditionMessage, ""),
    value = out$value, has_value = out$has_value, env = out$env,
    results = res, plots = out$plots %||% character(), post = out$post
  )
}
