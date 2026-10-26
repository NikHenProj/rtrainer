kind_labels <- c(write = "Schreiben", predict = "Vorhersagen", debug = "Fehler finden",
                 complete = "Erg\u00e4nzen")

kind_help <- c(
  write = NULL,
  predict = "Erst \u00fcberlegen, dann pr\u00fcfen: Sag das Ergebnis voraus, ohne den Code vorher auszuf\u00fchren.",
  debug = "Der Code enth\u00e4lt einen Fehler. Finde und behebe ihn.",
  complete = "Erg\u00e4nze die L\u00fccken im Code."
)

confidence_labels <- c("1" = "unsicher", "2" = "ziemlich sicher", "3" = "sicher")

app_server <- function(exercises, mode = "daily", n = 10, time_limit = 30, topics = NULL,
                       today = Sys.Date()) {
  force(exercises)
  function(input, output, session) {
    exam <- mode == "exam"
    plot_dir <- tempfile("rtrainer-plots-")
    dir.create(plot_dir)
    session$onSessionEnded(function() unlink(plot_dir, recursive = TRUE))

    prog <- shiny::reactiveVal(load_progress())
    update_prog <- function(p) {
      save_progress(p)
      prog(p)
    }
    cur_mode <- shiny::reactiveVal(mode)
    cur_id <- shiny::reactiveVal(NULL)
    st <- shiny::reactiveValues(hints = 0L, attempted = FALSE, solved = FALSE, solution = FALSE,
                                feedback = NULL, run = NULL, rated = NULL, conf = NA)
    sess <- shiny::reactiveValues(solved = character(), attempted = character())
    exam_results <- shiny::reactiveVal(list())
    exam_over <- shiny::reactiveVal(FALSE)
    exam_start <- Sys.time()

    filtered_ids <- function() {
      filter_exercises(exercises, prog(), input$f_topic, input$f_level, input$f_tags,
                       isTRUE(input$f_due), today)
    }
    build_queue <- function(m) {
      p <- shiny::isolate(prog())
      ids <- if (m == "free") shiny::isolate(filtered_ids()) else
        pick_session(exercises, p, n = n, topics = topics, today = today)
      new_queue(ids)
    }
    q <- shiny::reactiveVal(build_queue(mode))

    ex <- shiny::reactive({
      shiny::req(cur_id())
      exercises[[cur_id()]]
    })

    load_ex <- function(id) {
      cur_id(id)
      st$hints <- 0L
      st$attempted <- FALSE
      st$solved <- FALSE
      st$solution <- FALSE
      st$feedback <- NULL
      st$run <- NULL
      st$rated <- NULL
      st$conf <- NA
      if (is.null(id)) return(invisible())
      e <- exercises[[id]]
      shinyAce::updateAceEditor(session, "editor", value = e$starter)
      shiny::updateRadioButtons(session, "confidence", selected = character(0))
      shiny::updateActionButton(session, "hint", label = hint_label(0L, length(e$hints)),
                                disabled = !length(e$hints))
    }
    load_ex(queue_current(shiny::isolate(q())))

    shinyAce::aceAutocomplete("editor")
    shiny::observeEvent(input$dark, {
      shinyAce::updateAceEditor(session, "editor",
                                theme = if (identical(input$dark, "dark")) "tomorrow_night" else "textmate")
    })

    # ---- settings ----------------------------------------------------------
    p0 <- shiny::isolate(prog())
    shiny::updateRadioButtons(session, "set_scheduler", selected = p0$scheduler %||% "leitner")
    conf_enabled <- shiny::reactive({
      input$set_confidence %||% (shiny::isolate(prog())$settings$confidence %||% TRUE)
    })
    shiny::observeEvent(input$set_confidence, ignoreInit = TRUE, {
      p <- prog()
      p$settings$confidence <- isTRUE(input$set_confidence)
      update_prog(p)
    })
    shiny::observeEvent(input$set_scheduler, ignoreInit = TRUE, {
      p <- prog()
      if (!identical(p$scheduler, input$set_scheduler)) {
        p$scheduler <- input$set_scheduler
        update_prog(p)
      }
    })

    # ---- navigation --------------------------------------------------------
    go_next <- function() {
      if (st$solved && is.null(st$rated)) rate("ok")  # unrated success keeps the box
      nq <- queue_advance(q())
      q(nq)
      load_ex(queue_current(nq))
      if (exam && queue_done(nq)) finish_exam()
    }
    jump_to <- function(id) {
      q(queue_jump(q(), id))
      load_ex(id)
    }

    shiny::observeEvent(input$next_ex, go_next())
    shiny::observeEvent(input$reset, {
      shinyAce::updateAceEditor(session, "editor", value = ex()$starter)
    })
    shiny::observeEvent(input$exercise, ignoreInit = TRUE, {
      id <- input$exercise
      if (!identical(id, cur_id()) && id %in% names(exercises)) jump_to(id)
    })
    shiny::observeEvent(input$mode, ignoreInit = TRUE, {
      cur_mode(input$mode)
      nq <- build_queue(input$mode)
      q(nq)
      load_ex(queue_current(nq))
    })
    shiny::observeEvent(list(input$f_topic, input$f_level, input$f_tags, input$f_due),
                        ignoreInit = TRUE, {
      if (cur_mode() != "free") return()
      ids <- filtered_ids()
      keep <- cur_id()
      nq <- new_queue(ids)
      if (!is.null(keep) && keep %in% ids) {
        q(queue_jump(nq, keep))
      } else {
        q(nq)
        load_ex(queue_current(nq))
      }
    })
    shiny::observeEvent(input$random, {
      pool <- if (cur_mode() == "free") filtered_ids() else names(exercises)
      id <- random_exercise(pool, prog())
      if (is.null(id)) {
        st$feedback <- feedback_box("warning", "Alles gemeistert",
                                    "Im aktuellen Filter gibt es keine ungemeisterte Aufgabe.")
      } else {
        jump_to(id)
      }
    })
    shiny::observeEvent(input$new_round, {
      sess$solved <- character()
      sess$attempted <- character()
      nq <- build_queue(cur_mode())
      q(nq)
      load_ex(queue_current(nq))
    })

    shiny::observe({
      ids <- q()$ids
      p <- prog()
      mark <- vapply(ids, function(i) {
        if (is_mastered(p, i)) "\u2605 " else if (isTRUE(p$items[[i]]$solved)) "\u2713 " else ""
      }, "")
      labels <- paste0(mark, vapply(ids, function(i) exercises[[i]]$title, ""))
      shiny::updateSelectInput(session, "exercise", choices = stats::setNames(ids, labels),
                               selected = shiny::isolate(cur_id()) %||% character(0))
    })

    # ---- run / check -------------------------------------------------------
    do_run <- function() {
      st$run <- run_code(input$editor %||% "", ex(), plot_dir = plot_dir)
    }
    shiny::observeEvent(input$run, do_run())
    shiny::observeEvent(input$editor_run_key, do_run())

    do_check <- function() {
      e <- ex()
      code <- input$editor %||% ""
      if (exam && exam_over()) return()
      if (st$solved) {
        st$feedback <- feedback_box("warning", "Schon gel\u00f6st", "Bewerte die Aufgabe oder gehe mit \"Weiter\" zur n\u00e4chsten.")
        return()
      }
      if (!nzchar(trimws(code))) {
        st$feedback <- feedback_box("warning", "Noch kein Code", "Schreib zuerst Code in den Editor.")
        return()
      }
      conf <- if (isTRUE(conf_enabled())) suppressWarnings(as.integer(input$confidence %||% NA)) else NA_integer_
      res <- tryCatch(check_exercise(e, code), error = function(err) err)
      if (inherits(res, "error")) {
        st$feedback <- feedback_box("warning", "Pr\u00fcfung nicht m\u00f6glich", conditionMessage(res))
        return()
      }
      p <- record_attempt(prog(), e, res$correct, hints = st$hints, confidence = conf,
                          mistake = res$details$mistake)
      st$attempted <- TRUE
      st$conf <- conf
      shiny::updateRadioButtons(session, "confidence", selected = character(0))
      sess$attempted <- union(sess$attempted, e$id)

      if (exam) {
        if (isTRUE(res$correct)) p <- record_rating(p, e$id, "ok")
        update_prog(p)
        r <- exam_results()
        r[[e$id]] <- isTRUE(res$correct)
        exam_results(r)
        nq <- queue_advance(q())
        q(nq)
        load_ex(queue_current(nq))
        if (queue_done(nq)) finish_exam()
        else st$feedback <- feedback_box("warning", "Abgegeben", sprintf("%d von %d bearbeitet.", length(r), length(nq$ids)))
        return()
      }

      update_prog(p)
      if (isTRUE(res$correct)) {
        st$solved <- TRUE
        sess$solved <- union(sess$solved, e$id)
      } else if (is_confident_error(res$correct, conf)) {
        q(queue_requeue(q(), e$id))
      }
      st$feedback <- check_feedback(e, res, conf)
    }
    shiny::observeEvent(input$check, do_check())
    shiny::observeEvent(input$editor_check_key, do_check())

    # ---- hints / solution / rating -----------------------------------------
    shiny::observeEvent(input$hint, {
      if (exam || is.null(next_hint(ex(), st$hints))) return()
      st$hints <- st$hints + 1L
      total <- length(ex()$hints)
      shiny::updateActionButton(session, "hint", label = hint_label(st$hints, total),
                                disabled = st$hints >= total)
    })

    show_solution <- function() {
      if (!st$attempted && !st$solved) {
        update_prog(record_attempt(prog(), ex(), FALSE, hints = st$hints))
        st$attempted <- TRUE
      }
      st$solution <- TRUE
    }
    shiny::observeEvent(input$solution, {
      if (exam) return()
      if (st$attempted || st$solved) return(show_solution())
      shiny::showModal(shiny::modalDialog(
        title = "L\u00f6sung ohne Versuch ansehen?",
        "Abruf\u00fcbung wirkt am besten, wenn du es zuerst selbst versuchst. ",
        "Siehst du die L\u00f6sung jetzt an, gilt die Aufgabe als nicht gel\u00f6st und kommt bald wieder.",
        footer = shiny::tagList(
          shiny::modalButton("Selbst versuchen"),
          shiny::actionButton("solution_confirm", "L\u00f6sung zeigen", class = "btn-warning")
        )
      ))
    })
    shiny::observeEvent(input$solution_confirm, {
      shiny::removeModal()
      show_solution()
    })

    rate <- function(r) {
      if (!st$solved || !is.null(st$rated)) return()
      update_prog(record_rating(prog(), ex()$id, r, hints = st$hints))
      st$rated <- if (r == "easy" && st$hints >= 2L) "ok" else r
    }
    shiny::observeEvent(input$rate_easy, rate("easy"))
    shiny::observeEvent(input$rate_ok, rate("ok"))
    shiny::observeEvent(input$rate_hard, rate("hard"))
    shiny::observeEvent(input$save_note, {
      shiny::req(nzchar(trimws(input$note %||% "")))
      update_prog(record_note(prog(), ex()$id, input$note))
      shiny::showNotification("Notiz gespeichert.", type = "message", duration = 2)
    })

    # ---- exam --------------------------------------------------------------
    finish_exam <- function() {
      if (exam_over()) return()
      exam_over(TRUE)
      for (b in c("run", "check", "next_ex", "reset")) {
        shiny::updateActionButton(session, b, disabled = TRUE)
      }
    }
    if (exam) {
      deadline <- exam_start + time_limit * 60
      shiny::observe({
        shiny::invalidateLater(1000)
        if (!exam_over() && Sys.time() >= deadline) finish_exam()
      })
      output$timer <- shiny::renderText({
        if (exam_over()) return("00:00")
        shiny::invalidateLater(1000)
        format_remaining(as.numeric(difftime(deadline, Sys.time(), units = "secs")))
      })
      output$exam_progress <- shiny::renderText({
        sprintf("%d von %d abgegeben", length(exam_results()), length(q()$ids))
      })
      shiny::observeEvent(input$finish_exam, finish_exam())
      output$exam_table <- shiny::renderTable(exam_summary(q()$ids, exam_results(), exercises))
    }

    # ---- outputs: practice -------------------------------------------------
    output$ex_header <- shiny::renderUI({
      id <- cur_id()
      if (is.null(id)) return(shiny::h2(class = "h5 m-0", "Sitzung beendet"))
      e <- exercises[[id]]
      badge <- function(x, cls = "text-bg-secondary") shiny::span(class = paste("badge", cls), x)
      shiny::div(
        shiny::h2(class = "h5 d-inline me-2", e$title),
        badge(e$topic), " ", badge(paste("Level", e$level), "text-bg-light border"), " ",
        badge(kind_labels[[e$kind]], "text-bg-info"),
        if (isTRUE(prog()$items[[id]]$seen)) shiny::span(" ", badge("Wiederholung", "text-bg-warning"))
      )
    })
    output$ex_prompt <- shiny::renderUI({
      id <- cur_id()
      if (is.null(id)) {
        if (exam) return(shiny::p("Alle Aufgaben bearbeitet."))
        return(shiny::div(
          shiny::p(sprintf("Gel\u00f6st: %d von %d bearbeiteten Aufgaben.",
                           length(sess$solved), length(sess$attempted))),
          shiny::actionButton("new_round", "Neue Runde", class = "btn-primary")
        ))
      }
      e <- exercises[[id]]
      shiny::tagList(
        shiny::markdown(e$prompt),
        if (!is.null(kind_help[e$kind]) && !is.na(kind_help[e$kind])) shiny::helpText(kind_help[[e$kind]])
      )
    })
    output$session_info <- shiny::renderUI({
      qq <- q()
      if (cur_mode() == "free") {
        return(shiny::helpText(sprintf("%d Aufgaben im Filter", length(qq$ids))))
      }
      shiny::helpText(sprintf("Aufgabe %d von %d \u00b7 %d gel\u00f6st",
                              min(qq$pos, length(qq$ids)), length(qq$ids), length(sess$solved)))
    })
    output$confidence_ui <- shiny::renderUI({
      if (!isTRUE(conf_enabled())) return(NULL)
      shiny::radioButtons("confidence", "Wie sicher bist du? (optional, Tasten 1-3)",
                          choices = stats::setNames(names(confidence_labels),
                                                    paste(names(confidence_labels), confidence_labels)),
                          selected = character(0), inline = TRUE)
    })
    output$feedback <- shiny::renderUI({
      if (exam && exam_over()) {
        r <- exam_results()
        ok <- sum(unlist(r))
        total <- length(q()$ids)
        used <- format_remaining(as.numeric(difftime(Sys.time(), exam_start, units = "secs")))
        return(shiny::tagList(
          feedback_box(if (ok >= total / 2) "success" else "danger", "Pr\u00fcfung beendet",
                       sprintf("%d von %d richtig (%.0f %%), Zeit: %s", ok, total,
                               100 * ok / max(total, 1), used)),
          shiny::tableOutput("exam_table")
        ))
      }
      st$feedback
    })
    output$hints <- shiny::renderUI({
      shiny::req(st$hints > 0, cur_id())
      bslib::card(
        bslib::card_header("Hinweise"),
        shiny::tags$ol(lapply(ex()$hints[seq_len(st$hints)], function(h) shiny::tags$li(shiny::markdown(h))))
      )
    })
    output$after_solve <- shiny::renderUI({
      shiny::req(cur_id(), st$solved || st$solution)
      e <- ex()
      sol <- shiny::tagList(shiny::h3(class = "h6", "Musterl\u00f6sung"), shiny::tags$pre(shiny::tags$code(e$solution, .noWS = "outside"), .noWS = "inside"))
      expl <- if (nzchar(e$explanation)) shiny::tagList(shiny::h3(class = "h6", "Erkl\u00e4rung"), shiny::markdown(e$explanation))
      if (!st$solved) {
        return(bslib::card(bslib::card_header("L\u00f6sung"), sol, expl,
                           shiny::helpText("Die Aufgabe kommt bald wieder.")))
      }
      rating <- if (is.null(st$rated)) {
        capped <- st$hints >= 2L
        shiny::div(
          shiny::p(shiny::strong("Wie schwer war das?")),
          shiny::div(
            class = "rt-buttons",
            shiny::actionButton("rate_easy", if (capped) "Leicht (z\u00e4hlt als Okay)" else "Leicht",
                                title = if (capped) "Mit 2 oder mehr Hinweisen z\u00e4hlt Leicht als Okay."),
            shiny::actionButton("rate_ok", "Okay"),
            shiny::actionButton("rate_hard", "Schwer")
          )
        )
      } else {
        it <- prog()$items[[e$id]]
        shiny::p(sprintf("Gespeichert (%s). N\u00e4chste Wiederholung: %s.",
                         c(easy = "leicht", ok = "okay", hard = "schwer")[[st$rated]],
                         format(as.Date(it$due), "%d.%m.%Y")))
      }
      bslib::card(
        bslib::card_header("Geschafft"),
        expl, rating,
        shiny::textAreaInput("note", "In einem Satz: Warum funktioniert das? (optional)",
                             value = prog()$items[[e$id]]$note %||% "", rows = 2, width = "100%"),
        shiny::actionButton("save_note", "Notiz speichern", class = "btn-sm"),
        sol
      )
    })
    output$console <- shiny::renderText({
      if (is.null(st$run)) "Noch nichts ausgef\u00fchrt." else console_text(st$run)
    })
    output$plot_ui <- shiny::renderUI({
      plots <- st$run$plots
      if (!length(plots)) return(shiny::helpText("Kein Plot erzeugt."))
      shiny::tagList(
        shiny::imageOutput("plot", height = "auto"),
        if (length(plots) > 1) shiny::helpText(sprintf("%d Plots, gezeigt wird der letzte.", length(plots)))
      )
    })
    output$plot <- shiny::renderImage({
      f <- utils::tail(st$run$plots, 1)
      shiny::req(length(f))
      list(src = f, contentType = "image/png", width = "100%", alt = "Plot aus deinem Code")
    }, deleteFile = FALSE)
    output$table <- shiny::renderTable({
      v <- st$run$value
      shiny::validate(shiny::need(is.data.frame(v), "Der letzte Wert ist kein Data Frame."))
      utils::head(as.data.frame(v), 20)
    })

    # ---- outputs: sidebar / dashboard --------------------------------------
    output$topics <- shiny::renderUI({
      tp <- topic_progress(exercises, prog())
      lapply(seq_len(nrow(tp)), function(i) {
        shiny::div(
          class = "rt-topic",
          shiny::div(sprintf("%s: %d/%d gel\u00f6st, %d gemeistert", tp$topic[i], tp$solved[i],
                             tp$total[i], tp$mastered[i])),
          shiny::tags$progress(value = tp$solved[i], max = tp$total[i],
                               `aria-label` = paste("Fortschritt", tp$topic[i]))
        )
      })
    })

    stats <- shiny::reactive(progress_stats(prog(), today))
    pct <- function(x) sprintf("%.0f %%", 100 * x)
    output$vb_streak <- shiny::renderText(stats()$streak)
    output$vb_week <- shiny::renderText({
      log <- stats()$log
      if (!nrow(log)) 0L else sum(format(log$date, "%G-W%V") == format(today, "%G-W%V"))
    })
    output$vb_rate <- shiny::renderText({
      log <- stats()$log
      if (!nrow(log)) "\u2013" else pct(mean(log$correct))
    })
    output$vb_mastered <- shiny::renderText({
      p <- prog()
      sprintf("%d / %d", sum(vapply(names(exercises), is_mastered, logical(1), p = p)), length(exercises))
    })
    output$heatmap <- shiny::renderPlot(plot_activity(activity_grid(stats()$log, today)), bg = "transparent")
    output$topic_plot <- shiny::renderPlot(plot_topics(stats()$by_topic), bg = "transparent")
    output$calibration <- shiny::renderTable({
      cal <- stats()$calibration
      shiny::validate(shiny::need(nrow(cal) > 0, "Noch keine Sicherheits-Ratings."))
      data.frame(Sicherheit = confidence_labels[as.character(cal$confidence)],
                 Trefferquote = pct(cal$rate), Versuche = cal$n)
    })
    output$weak_tags <- shiny::renderTable({
      wt <- stats()$weak_tags
      shiny::validate(shiny::need(nrow(wt) > 0, "Noch zu wenige Daten (mind. 2 Versuche je Tag)."))
      data.frame(Tag = wt$tag, Quote = pct(wt$rate), Versuche = wt$n)
    })
    output$journal <- shiny::renderTable({
      j <- error_journal(prog(), exercises)
      shiny::validate(shiny::need(nrow(j) > 0, "Noch keine Fehler protokolliert."))
      data.frame(Fehler = j$mistake, Thema = j$topic, Anzahl = j$n)
    })
  }
}

# ---- dashboard plots (ggplot2 is optional) ----------------------------------

plot_note <- function(msg) {
  graphics::plot.new()
  graphics::text(0.5, 0.5, msg, col = "grey50")
}

plot_activity <- function(grid) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) return(plot_note("ggplot2 nicht installiert."))
  ggplot2::ggplot(grid, ggplot2::aes(.data$week, .data$weekday, fill = .data$n)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.8) +
    ggplot2::scale_y_reverse(breaks = 1:7, labels = c("Mo", "Di", "Mi", "Do", "Fr", "Sa", "So")) +
    ggplot2::scale_fill_gradient(low = "grey92", high = "#1b6ca8", name = "Versuche") +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(axis.text.x = ggplot2::element_blank(), panel.grid = ggplot2::element_blank(),
                   text = ggplot2::element_text(colour = "grey50"))
}

plot_topics <- function(bt) {
  if (!nrow(bt)) return(plot_note("Noch keine Versuche."))
  if (!requireNamespace("ggplot2", quietly = TRUE)) return(plot_note("ggplot2 nicht installiert."))
  ggplot2::ggplot(bt, ggplot2::aes(.data$rate, stats::reorder(.data$topic, .data$rate))) +
    ggplot2::geom_col(fill = "#1b6ca8") +
    ggplot2::geom_text(ggplot2::aes(label = paste0("n = ", .data$n)), hjust = -0.1, size = 3.5) +
    ggplot2::scale_x_continuous(labels = function(x) paste0(100 * x, " %"), limits = c(0, 1.15),
                                breaks = c(0, 0.5, 1)) +
    ggplot2::labs(x = "Erfolgsquote", y = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(text = ggplot2::element_text(colour = "grey50"),
                   axis.text = ggplot2::element_text(colour = "grey50"))
}
