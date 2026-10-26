app_css <- "
.rt-feedback { display: flex; flex-wrap: wrap; gap: .5rem; align-items: baseline; }
.rt-feedback .rt-icon { font-size: 1.3rem; font-weight: 700; line-height: 1; }
.rt-feedback .rt-msg { flex-basis: 100%; margin: .25rem 0 0; white-space: pre-wrap;
  background: transparent; color: inherit; font-size: .9rem; border: 0; padding: 0; }
.rt-emphasis { border-width: 3px; border-left-width: 8px; }
.rt-console { max-height: 22rem; overflow: auto; white-space: pre-wrap; }
.rt-topic { margin-bottom: .5rem; }
.rt-topic progress { width: 100%; height: .6rem; }
.rt-timer { font-variant-numeric: tabular-nums; font-size: 1.4rem; font-weight: 600; }
.rt-buttons .btn { margin: 0 .25rem .25rem 0; }
:focus-visible { outline: 3px solid var(--bs-primary) !important; outline-offset: 2px; }
"

# Keys 1-3 set the confidence rating, except while typing in the editor or a field
app_js <- "
document.addEventListener('keydown', function(e) {
  if (e.ctrlKey || e.metaKey || e.altKey || !['1', '2', '3'].includes(e.key)) return;
  var t = e.target;
  if (t.closest && (t.closest('.ace_editor') ||
      (t.closest('input, textarea, select') && t.type !== 'radio'))) return;
  var r = document.querySelector('input[name=\"confidence\"][value=\"' + e.key + '\"]');
  if (r) { r.click(); r.focus(); e.preventDefault(); }
});
"

app_ui <- function(exercises, mode, show_confidence = TRUE) {
  exam <- mode == "exam"
  topics <- sort(unique(vapply(exercises, `[[`, "", "topic")))
  tags <- sort(unique(unlist(lapply(exercises, `[[`, "tags"))))

  sidebar <- if (exam) {
    bslib::sidebar(
      shiny::h2(class = "h5", "Pr\u00fcfung"),
      shiny::div(class = "rt-timer", role = "timer", `aria-live` = "off",
                 shiny::textOutput("timer", inline = TRUE)),
      shiny::textOutput("exam_progress"),
      shiny::actionButton("finish_exam", "Pr\u00fcfung beenden", class = "btn-outline-danger")
    )
  } else {
    bslib::sidebar(
      width = 300,
      shiny::radioButtons("mode", "Modus", inline = TRUE, selected = mode,
                          choices = c("T\u00e4glich" = "daily", "Frei" = "free")),
      shiny::uiOutput("session_info"),
      shiny::selectInput("exercise", "Aufgabe", choices = NULL, selectize = FALSE, size = 8),
      shiny::actionButton("random", "Zufallsaufgabe (nicht gemeistert)",
                          class = "btn-outline-primary btn-sm"),
      bslib::accordion(
        open = FALSE,
        bslib::accordion_panel(
          "Filter (freier Modus)",
          shiny::checkboxGroupInput("f_topic", "Themen", choices = topics),
          shiny::checkboxGroupInput("f_level", "Level", choices = 1:3, inline = TRUE),
          shiny::selectizeInput("f_tags", "Tags", choices = tags, multiple = TRUE),
          shiny::checkboxInput("f_due", "Nur f\u00e4llige Wiederholungen")
        ),
        bslib::accordion_panel("Fortschritt nach Thema", shiny::uiOutput("topics"))
      )
    )
  }

  practice <- bslib::layout_columns(
    col_widths = bslib::breakpoints(sm = 12, lg = c(7, 5)),
    bslib::card(
      bslib::card_header(shiny::uiOutput("ex_header")),
      shiny::uiOutput("ex_prompt"),
      shinyAce::aceEditor(
        "editor", mode = "r", height = "260px", fontSize = 14, tabSize = 2,
        autoComplete = "live", autoCompleters = c("rlang", "text"),
        placeholder = "Dein R-Code \u2026",
        hotkeys = list(
          run_key = list(win = "Ctrl-Enter", mac = "CMD-ENTER"),
          check_key = list(win = "Ctrl-Shift-Enter", mac = "CMD-SHIFT-ENTER")
        )
      ),
      shiny::helpText("Strg+Enter: Ausf\u00fchren \u00b7 Strg+Umschalt+Enter: Pr\u00fcfen"),
      shiny::uiOutput("confidence_ui"),
      shiny::div(
        class = "rt-buttons",
        shiny::actionButton("run", "Ausf\u00fchren"),
        shiny::actionButton("check", if (exam) "Abgeben" else "Pr\u00fcfen", class = "btn-primary"),
        if (!exam) shiny::actionButton("hint", "Hinweis"),
        if (!exam) shiny::actionButton("solution", "L\u00f6sung"),
        shiny::actionButton("reset", "Zur\u00fccksetzen"),
        shiny::actionButton("next_ex", "Weiter", class = "btn-outline-primary")
      )
    ),
    shiny::div(
      shiny::div(`aria-live` = "polite", shiny::uiOutput("feedback")),
      shiny::uiOutput("hints"),
      shiny::uiOutput("after_solve"),
      bslib::navset_card_underline(
        bslib::nav_panel("Konsole", shiny::verbatimTextOutput("console") |>
                           shiny::tagAppendAttributes(class = "rt-console")),
        bslib::nav_panel("Plot", shiny::uiOutput("plot_ui")),
        bslib::nav_panel("Tabelle", shiny::tableOutput("table"))
      )
    )
  )

  dashboard <- shiny::tagList(
    bslib::layout_column_wrap(
      width = "180px", fill = FALSE,
      bslib::value_box("Streak (Tage)", shiny::textOutput("vb_streak")),
      bslib::value_box("Aufgaben diese Woche", shiny::textOutput("vb_week")),
      bslib::value_box("Erfolgsquote", shiny::textOutput("vb_rate")),
      bslib::value_box("Gemeistert", shiny::textOutput("vb_mastered"))
    ),
    bslib::layout_columns(
      col_widths = bslib::breakpoints(sm = 12, lg = c(6, 6)),
      bslib::card(bslib::card_header("Aktivit\u00e4t (12 Wochen)"), shiny::plotOutput("heatmap", height = "220px")),
      bslib::card(bslib::card_header("Erfolgsquote pro Thema"), shiny::plotOutput("topic_plot", height = "220px")),
      bslib::card(bslib::card_header("Kalibrierung: Trefferquote je Sicherheit"),
                  shiny::tableOutput("calibration"),
                  shiny::helpText("Gut kalibriert: \"sicher\" liegt deutlich h\u00f6her als \"unsicher\".")),
      bslib::card(bslib::card_header("Schw\u00e4chste Tags"), shiny::tableOutput("weak_tags")),
      bslib::card(bslib::card_header("Fehlerjournal"), shiny::tableOutput("journal"))
    )
  )

  settings <- bslib::card(
    shiny::checkboxInput("set_confidence", "Sicherheits-Rating vor dem Pr\u00fcfen abfragen",
                         value = show_confidence),
    shiny::radioButtons("set_scheduler", "Wiederholungsplan",
                        choices = c("Leitner (Boxen 1-5)" = "leitner", "SM-2" = "sm2")),
    shiny::helpText("Einstellungen werden mit dem Fortschritt gespeichert.")
  )

  bslib::page_sidebar(
    title = shiny::tagList("rtrainer", if (exam) " \u2013 Pr\u00fcfung"),
    theme = bslib::bs_theme(version = 5),
    lang = "de",
    sidebar = sidebar,
    shiny::tags$head(shiny::tags$style(app_css), shiny::tags$script(shiny::HTML(app_js))),
    bslib::navset_underline(
      id = "main",
      bslib::nav_panel("\u00dcben", practice),
      if (!exam) bslib::nav_panel("Dashboard", dashboard),
      if (!exam) bslib::nav_panel("Einstellungen", settings),
      bslib::nav_spacer(),
      bslib::nav_item(bslib::input_dark_mode(id = "dark"))
    )
  )
}
