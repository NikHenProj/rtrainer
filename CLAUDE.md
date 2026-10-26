# rtrainer

Lokales R-Lernpaket (Shiny-App, YAML-Aufgaben, Leitner/SM-2). Nutzertexte Deutsch; Code, Kommentare, Funktionsnamen Englisch.
Spezifikation: docs/SPEC.md – NICHT komplett lesen, nur den jeweils relevanten Abschnitt (grep/Zeilenbereich).
Aktueller Stand und nächster Schritt: STATUS.md (zuerst lesen).

## Zielperson
Nick, Human-Factors-/UX-Forscher, Linux, fortgeschrittenes R (Tidyverse, lme4, ggplot2). Kein Anfängerniveau. Kompakte, direkt umsetzbare Lösungen.

## Feste Entscheidungen (nicht neu diskutieren)
- Eigene Shiny-App (bslib, shinyAce); learnr nur als Export (`export_learnr()`).
- Fortschritt als JSON (`tools::R_user_dir("rtrainer","data")`), atomar geschrieben; Pfad per `options(rtrainer.data_dir=)` überschreibbar.
- Ausführung per `callr::r()` + `evaluate::evaluate()`, Timeout 10 s. Kein Sicherheits-Sandbox; im README ehrlich benennen.
- Leitner: Boxen 1-5, Intervalle 0/1/3/7/21 Tage; richtig+leicht = +1, okay = gleich, schwer = -1, falsch = Box 1. "Leicht" zählt nur bei < 2 Hinweisen. SM-2 über dieselbe Schnittstelle `next_due()`.
- Lernförderung (Details: SPEC.md, Abschnitt "Lernförderung"): Problem zuerst (Expertise-Reversal), Abrufübung, verteiltes Üben, Themen-Mischung (Interleaving), Sicherheits-Rating vor dem Prüfen, elaboriertes Feedback bei sicheren Fehlern, Aufgabenarten write/predict/debug/complete.
- Imports minimal: shiny, bslib, shinyAce, yaml, evaluate, callr, cli, jsonlite, rlang.

## Skills und Agenten
Extern: `r-package-development`, `r-testthat`, `shiny-bslib`, `r-tidyverse-style`, `create-release-checklist`, `webapp-testing`, `skill-creator` (Installation: SETUP.md).
Projekt: `rtrainer-verify`, `rtrainer-write-exercise`, `rtrainer-shiny-app`; Subagent `rtrainer-verifier` (günstig, liefert nur Kurzbericht).
Bei Konflikt gilt: projektspezifische Regeln vor allgemeinen Skills.

## Token-Disziplin
- Verifikation (Tests, check, Selbsttest) immer über Subagent `rtrainer-verifier`; Logs nie komplett ausgeben.
- Gezielt lesen: Dateien/Zeilenbereiche nennen statt ganzer Verzeichnisse.
- Eine Sitzung pro Meilenstein bzw. Aufgaben-Thema. Am Ende STATUS.md aktualisieren, dann `/clear` empfehlen.
- Aufgaben-YAML in Themenpaketen (max. ~10 pro Durchgang) schreiben, danach verifizieren.

## Befehle
- `Rscript -e 'devtools::document()'`
- `Rscript -e 'devtools::test()'`
- `Rscript -e 'devtools::load_all(); print(check_all_solutions(verbose = FALSE))'`
- `Rscript -e 'devtools::check()'`

## Stil
- `|>`, roxygen2 mit Markdown, testthat 3e, lintr/styler-konform.
- Neue Abhängigkeiten nur mit Begründung in NEWS.md.
- Jede Verhaltensänderung bekommt Tests (richtig, falsch, Randfall).

## Arbeitsweise
- Meilensteine laut SPEC.md; nach jedem: Tests grün, kurze Zusammenfassung, nächster Schritt.
- Nie behaupten, Tests seien grün, ohne sie ausgeführt zu haben; echte (gekürzte) Ausgabe zeigen.
- Entscheidungen in NEWS.md notieren; nur bei echter Blockade nachfragen.
