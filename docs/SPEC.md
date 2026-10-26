# rtrainer – Spezifikation

## Rolle und Ziel
Erfahrener R-Paketentwickler und Didaktiker baut **rtrainer**: lokale, offline nutzbare, interaktive Lernumgebung für fortgeschrittenes R. Oberfläche Deutsch, Code/Funktionsnamen Englisch.
`rtrainer::start()` startet eine Shiny-App mit: (1) Aufgaben, Editor, echte R-Ausführung lokal; (2) automatische Auswertung mit deutschem Feedback; (3) stufenweise Hinweise, Musterlösung mit Erklärung; (4) Fortschritt + Spaced Repetition (Leitner, optional SM-2); (5) Erweiterbarkeit über YAML-Aufgaben (auch eigene Datensätze).

## Zielperson
Nick, Human-Factors-/UX-Forscher (Master), Linux, täglich R/Tidyverse/R Markdown, wertet Fahrsimulator- und Nutzerstudien aus. Gezieltes Training für Fortgeschrittene: Datenaufbereitung, funktionale Programmierung, Inferenzstatistik, LMMs (lme4), ggplot2, reproduzierbare Pipelines. Klare Aufgaben, schnelles Feedback, sichtbarer Fortschritt, kompakte Lösungen.

## Technische Vorgaben
- R >= 4.3, Linux-first, plattformunabhängig, keine Systemabhängigkeiten außer R-Paketen.
- usethis/devtools-Konventionen, roxygen2, testthat 3e, lintr/styler-konform, GitHub Actions für `R CMD check`.
- Imports: shiny, bslib, shinyAce, yaml, evaluate, callr, cli, jsonlite, rlang. Suggests: dplyr, tidyr, purrr, stringr, ggplot2, lme4, lmerTest, learnr, gradethis, testthat, knitr, rmarkdown, shinytest2, withr, bench, here, renv, targets.
- Frontend: eigene Shiny-App (bslib, Dark/Light), Editor shinyAce. README begründet Shiny statt learnr. Zusätzlich `export_learnr()` (learnr-`.Rmd` mit gradethis-Checks).
- Nutzercode in isoliertem Prozess (`callr::r()`), Timeout 10 s, Fehler/Warnungen/Ausgaben abfangen (`evaluate`), Arbeitsverzeichnis tempdir. Kein Sicherheits-Sandbox – Grenzen ehrlich dokumentieren.
- Fortschritt: JSON in `tools::R_user_dir("rtrainer","data")`.

## Dateistruktur (Ziel)
```
rtrainer/
├── DESCRIPTION, NAMESPACE, LICENSE, README.md, NEWS.md
├── R/ start.R, app_ui.R, app_server.R, exercise_load.R, exercise_run.R,
│      check_engine.R, feedback.R, progress.R, scheduler.R, content_tools.R,
│      export_learnr.R, data.R, utils.R, rtrainer-package.R
├── inst/exercises/{01-basics,02-dplyr,03-tidyr,04-purrr,05-programming,
│                   06-statistics,07-mixed-models,08-ggplot2,09-reproducibility}/*.yml
├── inst/datasets/driving_sim.csv      (erzeugt durch data-raw/driving_sim.R)
├── inst/app/www/
├── tests/testthat/
└── vignettes/ getting-started.Rmd, write-your-own-exercises.Rmd
```

## Aufgabenformat (YAML)
Felder: id, topic, title, level (1-3), kind (write|predict|debug|complete), tags, packages, seed, prompt, setup, starter, solution, hints[], explanation, misconception, check{type, ...}, common_mistakes[{pattern, message}].
Check-Typen: value | output | object | function | regex | ast | plot. Beispiel: `inst/exercises/02-dplyr/group-summarise.yml`. `validate_exercise()` meldet Fehler mit `cli::cli_abort()`.

## Check-Engine (`check_exercise(exercise, user_code)` -> list(correct, message, details))
1. value: letzter Wert vs. Musterlösung; Zahlen mit tolerance; Data Frames getrennt nach Spaltennamen, Typen, Zeilenanzahl, Werten; Optionen ignore_row_order/ignore_col_order/ignore_attributes; konkrete Meldungen.
2. output: Konsolenausgabe mit normalisierten Leerzeichen (Diff bis zur ersten Abweichung).
3. object: Objekt mit Name/Klasse im Nutzer-Environment.
4. function: Testfälle `tests: [{args, expect}]` inkl. Randfälle (NA, leerer Vektor).
5. regex/ast: Funktionen gefordert/verboten (`getParseData()`).
6. plot: ggplot strukturell (Geoms, Mappings, Facets, Theme), nicht Pixel.
Zusätzlich: deutsche Übersetzung häufiger R-Fehler, `common_mistakes` als gezielte Hinweise, deterministisch via `seed`.

## Oberfläche (Shiny)
- Seitenleiste: Themen mit Fortschrittsbalken, Filter (Level, Tags, "nur fällige Wiederholungen"), "Zufallsaufgabe" (nur nicht gemeisterte).
- Hauptbereich: Titel, Aufgabentext (Markdown), Editor; Buttons Ausführen (Strg+Enter), Prüfen, Hinweis (stufenweise), Lösung (erst nach Versuch oder Bestätigung), Zurücksetzen, Weiter.
- Ausgabe: Konsole, Plots, Tabellen, Feedback-Box grün/rot/gelb mit Symbolen (✓ ✗ !).
- Nach der Lösung: Erklärung + "Wie schwer war das?" (Leicht/Okay/Schwer).
- Dashboard: Streak, Aufgaben/Woche, Erfolgsquote pro Thema, Aktivitäts-Heatmap (ggplot2), schwächste Tags, Kalibrierung, Fehlerjournal.
- Barrierefreiheit: Tastaturbedienung, Kontraste, keine reine Farbcodierung.

## Lernlogik
- Leitner: 5 Boxen, Intervalle 0/1/3/7/21 Tage. Richtig+leicht: +1; richtig+okay: gleich; richtig+schwer: -1; falsch: Box 1. "Leicht" mit >= 2 Hinweisen zählt als "Okay".
- SM-2 optional (`scheduler = "sm2"`), einheitliche Schnittstelle `next_due(state, result)`, beide getestet.
- `start(mode = "daily")`: 10 Aufgaben (fällige + neue, Level und Themen gemischt). `start(mode = "exam", n = 15, time_limit = 30)`: keine Hinweise, Gesamtauswertung.

## Lernförderung (evidenzbasiert)
Grundlage: Dunlosky et al. (2013) bewerten Abrufübung (Practice Testing) und verteiltes Üben als besonders nützlich; Interleaving, Elaboration und Feedback ergänzen. Die Zielperson ist fortgeschritten, daher gilt "Problem zuerst" (Expertise-Reversal-Effekt: ausgearbeitete Beispiele helfen Novizen, Fortgeschrittenen oft weniger).

| Prinzip | Umsetzung |
|---|---|
| Abrufübung | Aufgabe zuerst, Hinweise nur auf Abruf, Lösung erst nach Versuch; `predict`-Aufgaben prüfen mentale Modelle |
| Verteiltes Üben | Leitner/SM-2; Box-1-Wiederholung noch in derselben Sitzung, danach 1/3/7/21 Tage |
| Interleaving | `pick_session()` mischt Themen (`interleave_topics()`), Daily-Modus nie blockweise |
| Sicherheits-Rating (Hypercorrection) | Optional vor "Prüfen" 1-3; sicherer Fehler -> hervorgehobenes, elaboriertes Feedback (Erwartung vs. Ergebnis, `misconception`, Erklärung) + erneute Vorlage in der Sitzung |
| Kalibrierung | Dashboard zeigt Trefferquote je Sicherheitsstufe (`progress_stats()$calibration`) |
| Faded Examples | `kind: complete` mit Lücken nur bei neuen/schweren Themen (Mixed Models, targets, tidy eval); Lücken über 2-3 Aufgaben ausblenden |
| Fehler lernen | `kind: debug` + `misconception` + `common_mistakes` mit Begründung; Fehlerjournal im Dashboard |
| Selbsterklärung | Optionales "In einem Satz: warum?" nach der Lösung (Notiz, ohne Bewertung) |
| Transfer | Pro Konzept mindestens eine Variante im anderen Kontext (`driving_sim.csv`) |
| Ehrliche Schwierigkeit | Hinweise drücken Bewertung ("Leicht" gedeckelt); Prüfungsmodus ohne Hilfen |
Nicht überversprechen: Hypercorrection und Kalibrierung sind für Wissensfragen gut belegt, für Programmieraufgaben weniger; als Option anbieten und per Logdaten prüfen.

## Inhalte (mindestens 60 Aufgaben, jeweils Hinweise + Erklärung, steigende Schwierigkeit)
- Basics (6), dplyr (10), tidyr (6), purrr (7), Programmierung (8), Statistik (10), Mixed Models (8), ggplot2 (6), Reproduzierbarkeit (4) – Themen wie im Aufgaben-Skill `rtrainer-write-exercise`:
  - Basics: Vektoren, Indizierung, Listen, Faktoren, Funktionen, Kontrollstrukturen.
  - dplyr: filter/select, mutate/case_when, group_by/summarise, across, joins, Window-Funktionen, slice_max, count.
  - tidyr: pivot_longer/wider, separate_wider_*, drop_na, complete, nest/unnest.
  - purrr: map-Familie, map2, reduce, Modelle pro Gruppe, safely/possibly.
  - Programmierung: Funktionen, Defaults und `...`, tryCatch, Environments, tidy evaluation, stringr-Regex, Vektorisierung vs. Schleife, bench.
  - Statistik: Deskriptiv, Welch-t, Mann-Whitney, ANOVA, Tukey, Effektstärken, Voraussetzungstests, Korrelation, lm, p.adjust.
  - Mixed Models: Random Intercept, Random Slope, Modellvergleich, ICC, Konvergenz (allFit), Diagnostik, Interpretation, Messwiederholung (Bedingung × Zeit, vp_id).
  - ggplot2: aes/Geoms, Facets, Skalen, Themes, Fehlerbalken, ggsave.
  - Reproduzierbarkeit: R-Projekte, here, renv, R-Markdown-Parameter, einfache targets-Pipeline.
- Mindestens je 10 % `predict`, `debug`, `complete` (nur in neuen Themen).
- Datensatz `driving_sim.csv`: 40 Versuchspersonen, 3 Bedingungen zur Übernahmeaufforderung, Reaktionszeit, Spurabweichung, Alter, Geschlecht, wiederholte Messungen, einige NA; `data-raw/driving_sim.R` (Seed), Doku in `R/data.R`.

## Erweiterbarkeit
`add_exercise_dir()`, `new_exercise()`, `check_all_solutions()`, `export_learnr(topics, path)`.

## Qualitätssicherung
Unit-Tests: YAML-Validierung (inkl. kind), jede Check-Art, Scheduler, Fortschritt (inkl. Confidence/Kalibrierung, Interleaving, Hint-Cap), sichere Ausführung (Timeout, Endlosschleife, `stop()`, `q()`). Jede Aufgabe besteht mit Musterlösung und besteht mit Starter nicht. shinytest2-Smoke-Test. README: Screenshot-Platzhalter, Linux-Installation, Schnellstart, eigene Aufgaben, Troubleshooting.

## Meilensteine
1. Gerüst, Check-Engine, Ausführung, Scheduler (geschrieben, ungetestet)
2. Progress (JSON), Feedback/Diff, check_all_solutions, new_exercise, Lern-Grundlagen im Code (geschrieben, ungetestet)
3. Shiny-App, start(), Modi daily/exam, Dashboard, Lernförderungs-UI
4. 60+ Aufgaben, driving_sim.csv
5. export_learnr, Vignetten, README, GitHub Actions, shinytest2
Nach jedem Meilenstein: lauffähig, Tests grün (echte Ausgabe), kurze Zusammenfassung, STATUS.md aktualisieren.

## Bekannte Risiken (zuerst prüfen)
1. `run_code()`: Signatur des `value`-Handlers von `evaluate::new_output_handler()` ist versionsabhängig; letzter Wert und Konsolenausgabe müssen zuverlässig erfasst werden (Plots beachten).
2. Timeout-Erkennung per Textvergleich der callr-Meldung ist fragil -> Fehlerklasse oder Laufzeit prüfen.
3. `getParseData()` braucht `keep.source = TRUE`; testen mit `stringr::str_detect` und `pkg::fun`.
4. `compare_df()`: Faktoren, integer vs. double, tibble vs. data.frame absichern.
5. `pick_session()`/`interleave_topics()`: Randfälle (weniger Aufgaben als n, leeres Log, ein Level/Thema).
6. `withr` in Suggests (Tests nutzen `local_progress_dir()`).
7. Starter mit Syntaxfehler (endet auf Pipe) muss als "nicht bestanden" gelten.
8. `common_mistakes`-Regex der Beispielaufgabe (Negative Lookahead, `perl = TRUE`) testen.

## Skill-Einsatz
| Phase | Skill/Agent |
|---|---|
| M1/M2 Fix und Tests | r-package-development, r-testthat, rtrainer-verifier |
| M3 App | shiny-bslib, rtrainer-shiny-app, webapp-testing (oder shinytest2) |
| M4 Inhalte | rtrainer-write-exercise, rtrainer-verifier; skill-creator zum Verfeinern |
| M5 Export/Doku/Release | r-package-development, r-tidyverse-style, create-release-checklist |
Projektregeln haben Vorrang vor allgemeinen Skills.

## Abnahmekriterien
- `rtrainer::start()` öffnet die App, Aufgabe lösbar, Feedback < 2 s.
- Fortschritt bleibt nach Neustart erhalten.
- >= 60 Aufgaben, alle Selbsttests grün.
- `R CMD check` ohne Errors und Warnings.
- Neue Aufgabe in < 5 Minuten als YAML hinzufügbar.

## Ausgabeformat pro Meilenstein
(1) Entscheidungen, (2) geänderte Dateien, (3) Befehle zum Testen, (4) ehrlicher Status, (5) nächster Schritt.
