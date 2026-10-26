fx <- function() fixture_exercises()[c("fx-sum", "fx-print", "fx-plot")]

test_that("free mode: correct check logs attempt and offers rating", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "free"), {
    jump_to("fx-sum")
    session$setInputs(set_confidence = TRUE, confidence = "2",
                      editor = "x <- 1:10\nsum(x[x %% 2 == 0])")
    session$setInputs(check = 1)
    expect_true(st$solved)
    expect_match(as.character(st$feedback), "alert-success")
    p <- load_progress()
    expect_length(p$log, 1)
    expect_equal(p$log[[1]]$confidence, 2L)
    # hints are counted before rating; 'easy' with >= 2 hints is capped
    st$hints <- 2L
    session$setInputs(rate_easy = 1)
    expect_equal(st$rated, "ok")
    expect_equal(load_progress()$items[["fx-sum"]]$box, 1L)
    # a second rating is ignored
    session$setInputs(rate_hard = 1)
    expect_equal(st$rated, "ok")
  })
})

test_that("confident error requeues the exercise and shows elaborated feedback", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "free"), {
    jump_to("fx-sum")
    n_before <- length(q()$ids)
    session$setInputs(set_confidence = TRUE, confidence = "3", editor = "sum(1:10)")
    session$setInputs(check = 1)
    expect_false(st$solved)
    expect_match(as.character(st$feedback), "rt-emphasis")
    expect_match(as.character(st$feedback), "Fehlvorstellung")
    expect_equal(length(q()$ids), n_before + 1L)
    expect_equal(utils::tail(q()$ids, 1), "fx-sum")
    expect_equal(load_progress()$items[["fx-sum"]]$box, 1L)
  })
})

test_that("unsure error is not requeued; disabled rating logs no confidence", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "free"), {
    jump_to("fx-sum")
    n_before <- length(q()$ids)
    session$setInputs(set_confidence = FALSE, confidence = "3", editor = "sum(1:10)")
    session$setInputs(check = 1)
    expect_equal(length(q()$ids), n_before)
    expect_no_match(as.character(st$feedback), "rt-emphasis")
    expect_null(load_progress()$log[[1]]$confidence)
  })
})

test_that("empty code and broken solution give warnings, not crashes", {
  local_progress_dir()
  exs <- fx()
  exs[["fx-print"]]$solution <- "stop('kaputt')"
  shiny::testServer(app_server(exs, mode = "free"), {
    jump_to("fx-sum")
    session$setInputs(editor = "   ")
    session$setInputs(check = 1)
    expect_match(as.character(st$feedback), "alert-warning")
    expect_length(load_progress()$log, 0)
    jump_to("fx-print")
    session$setInputs(editor = "cat('x')")
    session$setInputs(check = 2)
    expect_match(as.character(st$feedback), "alert-warning")
    expect_match(as.character(st$feedback), "kaputt")
  })
})

test_that("hints are stepwise and stop when exhausted", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "free"), {
    jump_to("fx-print")  # one hint
    session$setInputs(hint = 1)
    expect_equal(st$hints, 1L)
    session$setInputs(hint = 2)
    expect_equal(st$hints, 1L)
  })
})

test_that("solution after an attempt is shown directly; without attempt it counts as failed", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "free"), {
    jump_to("fx-sum")
    session$setInputs(solution = 1)
    expect_false(st$solution)  # waits for confirmation
    session$setInputs(solution_confirm = 1)
    expect_true(st$solution)
    p <- load_progress()
    expect_length(p$log, 1)
    expect_false(p$log[[1]]$correct)
    jump_to("fx-print")
    session$setInputs(editor = "cat('falsch')")
    session$setInputs(check = 1)
    session$setInputs(solution = 2)
    expect_true(st$solution)
    expect_length(load_progress()$log, 2)  # no extra failed entry
  })
})

test_that("next without rating schedules a solved exercise as 'ok' and resets state", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "free"), {
    jump_to("fx-print")
    session$setInputs(editor = "cat('Hallo Welt\\n')")
    session$setInputs(check = 1)
    expect_true(st$solved)
    session$setInputs(next_ex = 1)
    expect_false(st$solved)
    expect_equal(st$hints, 0L)
    expect_equal(load_progress()$items[["fx-print"]]$due, format(Sys.Date()))
  })
})

test_that("run fills console, plots and value", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "free"), {
    jump_to("fx-plot")
    session$setInputs(editor = "hist(faithful$eruptions)")
    session$setInputs(run = 1)
    expect_length(st$run$plots, 1)
    session$setInputs(editor = "data.frame(a = 1:2)")
    session$setInputs(run = 2)
    expect_s3_class(st$run$value, "data.frame")
    expect_match(output$console, "a")
  })
})

test_that("daily mode interleaves topics and ends with a summary", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "daily", n = 3), {
    ids <- q()$ids
    expect_setequal(ids, names(fx()))
    session$setInputs(next_ex = 1, mode = "daily")
    session$setInputs(next_ex = 2)
    session$setInputs(next_ex = 3)
    expect_true(queue_done(q()))
    expect_null(cur_id())
    expect_match(output$ex_prompt$html, "Neue Runde")
    session$setInputs(new_round = 1)
    expect_false(queue_done(q()))
  })
})

test_that("free mode filters rebuild the queue", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "free"), {
    session$setInputs(mode = "free")  # first flush = init (ignoreInit)
    session$setInputs(f_topic = "plots")
    expect_equal(q()$ids, "fx-plot")
    expect_equal(cur_id(), "fx-plot")
  })
})

test_that("exam mode: no hints, results recorded, finish disables checks", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "exam", n = 2, time_limit = 5), {
    expect_length(q()$ids, 2)
    first <- cur_id()
    session$setInputs(hint = 1, solution = 1)
    expect_equal(st$hints, 0L)
    expect_false(st$solution)
    session$setInputs(editor = "1")
    session$setInputs(check = 1)
    expect_false(exam_results()[[first]])
    expect_false(exam_over())
    session$setInputs(finish_exam = 1)
    expect_true(exam_over())
    expect_match(output$feedback$html, "von 2 richtig")
    session$setInputs(check = 2)
    expect_length(exam_results(), 1)
  })
})

test_that("settings persist scheduler and confidence switch", {
  local_progress_dir()
  shiny::testServer(app_server(fx(), mode = "free"), {
    session$setInputs(set_scheduler = "leitner", set_confidence = TRUE)
    session$setInputs(set_scheduler = "sm2", set_confidence = FALSE)
    p <- load_progress()
    expect_equal(p$scheduler, "sm2")
    expect_false(p$settings$confidence)
  })
})

test_that("app smoke test in a browser", {
  skip_on_cran()
  skip_if_not_installed("shinytest2")
  skip_if(is.null(tryCatch(chromote::find_chrome(), error = function(e) NULL)),
          "Kein Chrome/Chromium gefunden")
  # The app runs in a separate R process: pass data dir and exercises via app.R
  # (shinytest2 turns library(rtrainer) into load_all() during devtools::test()).
  app_dir <- withr::local_tempdir()
  # Chrome puts org.chromium.* into TMPDIR (R CMD check "detritus" note): give
  # it a throwaway TMPDIR and close the browser before that dir is removed.
  withr::local_envvar(TMPDIR = withr::local_tempdir())
  withr::defer(try(chromote::default_chromote_object()$close(), silent = TRUE))
  writeLines(c(
    "library(rtrainer)",
    sprintf("options(rtrainer.data_dir = %s)", deparse(withr::local_tempdir())),
    sprintf("ex <- load_exercises(%s)", deparse(normalizePath(test_path("fixtures", "exercises")))),
    'rtrainer_app("free", exercises = ex[c("fx-sum", "fx-print", "fx-plot")])'
  ), file.path(app_dir, "app.R"))
  app <- shinytest2::AppDriver$new(app_dir, name = "smoke", load_timeout = 30000)
  withr::defer(app$stop())
  app$set_inputs(editor = "x <- 1:10\nsum(x[x %% 2 == 0])", allow_no_input_binding_ = TRUE)
  app$click("check")
  app$wait_for_idle()
  expect_match(app$get_text("#feedback"), "✓|✗|!")
})
