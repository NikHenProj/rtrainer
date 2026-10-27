# rtrainer – Spezifikation (Kurs-Neuausrichtung, ab 2026-10-26)

Vorgänger: lokale Shiny-App als R-Paket, Stand im Tag `v0-shiny` (nicht weitergepflegt).
Entscheidungen hier stammen aus einer Grilling-Sitzung mit Nick (2026-10-26) und gelten als fest.

## Ziel
Ein zweisprachiger (DE/EN) R-Kurs als **Quarto-Website mit quarto-live/webR**: R läuft im Browser, keine Installation. Erst erklären, dann üben, dann verteilt wiederholen. Schwerpunkt: Datenanalyse für Human Factors, UX und Psychologie mit aktuellen Werkzeugen (tidyverse + easystats), von Beginner bis Expert. Öffentlich auf GitHub Pages (`NikHenProj/rtrainer`), lokal per `quarto preview` nutzbar.

## Zielperson
Nick, Human-Factors-/UX-Forscher, Linux, R-Praxis (Tidyverse, lme4, ggplot2). Der Kurs soll aber auch für Kolleg:innen und Studierende ab Beginner taugen. Kompakte, praxisnahe Inhalte; keine Nachbauten von Basisfunktionen (z. B. eigene `sd()`), sondern echte Werkzeuge an realistischen Daten.

## Struktur: Themen × Stufen
Matrix aus 23 Themen (Zeilen) × 3 Stufen (Spalten: Beginner, Intermediate, Expert). Nicht jede Zelle existiert. Empfohlener Pfad **stufenweise** (alle Beginner-Lektionen, dann Intermediate, dann Expert); alles frei zugänglich, Voraussetzungen werden pro Lektion angezeigt und verlinkt. Mini-Projekt (vollständige Analyse) am Ende jeder Stufe.

| # | Slug | Thema (DE / EN) | Kernpakete | Stufen |
|---|---|---|---|---|
| 1 | working-with-r | Arbeiten mit R / Working with R | Projekte, Hilfe, Fehlermeldungen, Quarto | B |
| 2 | import | Daten einlesen / Importing data | readr, readxl, haven (Qualtrics/LimeSurvey) | B, I |
| 3 | cleaning | Daten bereinigen / Cleaning data | janitor, forcats, lubridate, stringr | B, I |
| 4 | reshaping | Umformen und zusammenführen / Reshaping and joining | tidyr, dplyr | B, I, E |
| 5 | missing | Fehlende Werte / Missing data | naniar, mice | I, E |
| 6 | visualisation | Visualisieren / Visualisation | ggplot2, patchwork, see | B, I, E |
| 7 | descriptives | Deskriptive Statistik, Tabelle 1 / Descriptives, Table 1 | dplyr, datawizard, gtsummary | B, I |
| 8 | scales | Fragebögen und Skalen / Questionnaires and scales | datawizard, psych | B, I, E |
| 9 | sem | CFA und SEM / CFA and SEM | lavaan, semTools | I, E |
| 10 | group-comparisons | Gruppenvergleiche / Group comparisons | rstatix, effectsize, afex, modelbased, emmeans | B, I, E |
| 11 | robust | Nichtparametrisch und robust / Nonparametric and robust | rstatix, WRS2 | I, E |
| 12 | regression | Korrelation und Regression / Correlation and regression | correlation, parameters, performance | B, I, E |
| 13 | glm | Kategoriale Daten und GLM / Categorical data and GLMs | glm, marginaleffects, effectsize | I, E |
| 14 | mixed-models | Messwiederholung und Mixed Models / Repeated measures and mixed models | lme4, lmerTest, glmmTMB, modelbased | I, E |
| 15 | moderation-mediation | Moderation und Mediation | interactions, lavaan | I, E |
| 16 | power | Power und Stichprobenplanung / Power analysis | pwr, Superpower, simr | I, E |
| 17 | bayes | Bayes / Bayesian statistics | bayestestR (brms lokal) | E |
| 18 | signals | Zeitverläufe und Signale / Time courses and signals | signal, mgcv, itsadug, eyetrackingR | E |
| 19 | text | Textdaten / Text data | tidytext | I, E |
| 20 | machine-learning | Maschinelles Lernen / Machine learning basics | tidymodels | E |
| 21 | reporting | Ergebnisse berichten / Reporting results | report, gtsummary, modelsummary, flextable, rempsyc, apaquarto | B, I, E |
| 22 | reproducibility | Reproduzierbar arbeiten / Reproducible workflows | Quarto, renv, git | I, E |
| 23 | programming | R-Programmierung für Analysen / Programming for analysis | Funktionen, purrr | I, E |

Lektions-ID: `<slug>-<level>` mit level ∈ {beginner, intermediate, expert}.

## Paket-Standard (Hauptweg)
- **tidyverse + easystats** als Rückgrat (parameters, effectsize, performance, modelbased, see, report, datawizard, correlation).
- rstatix für Tests auf Data Frames; afex für (RM-)ANOVA; modelbased zuerst, emmeans für komplexe Kontraste; psych für Skalen/EFA; lavaan für CFA/SEM.
- Base R nur, wo es dem Verständnis dient oder in fremdem Code ständig vorkommt (`t.test()`, `aov()`, Formeln).
- **Berichtskette** (zieht sich durch alle Lektionen): Modell → `parameters`/`effectsize` → `report()` (APA-Text) → `gtsummary`/`modelsummary` (Tabelle) → Word (`flextable`/`rempsyc::nice_table()`) oder Quarto.
- Paketvergleich in Lektionen nur, wo sinnvoll; mit klarer Empfehlung.
- **Nicht im Browser** (Stand webR 4.6): brms, rstanarm, BayesFactor, ggstatsplot, apaTables, DHARMa; Pandoc/LaTeX (Word-Render, papaja). Umgang: Kasten „Lokal ausführen / Run locally“ mit Code und erwartetem Ergebnis; im Browser Ersatz (bayestestR auf vorab gerechneten Modellen, `performance::check_model()`, ggplot2 + rstatix), Word-Dateien per Download-Knopf.
- Browser-Grenzen: single-threaded, Simulationen klein halten (50–100), Datensätze KB bis wenige MB, Paketversionen pinnen.

## Lektion (Aufbau)
1. Wozu? – Forschungsfrage (HF/UX oder passender Kontext)
2. Konzept – knapp, mit Abbildung
3. Durchgerechnetes Beispiel – live editier- und ausführbar
4. Paketvergleich – wo sinnvoll, mit Empfehlung
5. Übungen – steigende Schwierigkeit, Hinweise gestuft, Lösung
6. Wissenscheck – Ausgabe deuten, Mehrfachauswahl, Erklärung je Option
7. Spickzettel – Zusammenfassung
Expert-Lektionen beginnen mit einer kurzen Herausforderung („Versuch es erst selbst“), Erklärung danach, überspringbar. Lange Inhalte: „Mehr dazu“-Kästen (Progressive Disclosure).
**Abgeschlossen** = alle Pflichtübungen gelöst (automatisch geprüft) + Wissenscheck ≥ 80 %; optionale Vertiefungsübungen zählen nicht. Danach Übungen der Lektion in die Wiederholung (Leitner Box 1, erster Termin am Folgetag).

## Übungen (Single Source)
Jede Übung eine YAML-Datei in `exercises/<slug>/<level>/<id>.yml`; ein R-Skript erzeugt daraus quarto-live-Blöcke für die Lektion **und** Karten für die Wiederholungsseite. Entwurf (wird im Prototyp finalisiert):
`id, lesson, title{de,en}, kind (write|interpret|debug|complete|predict), required (bool), packages, data, setup, starter, solution, hints[{de,en}], explanation{de,en}, misconception{de,en}, check{type, …}, common_mistakes[{pattern, message{de,en}}]`; Expert-Lektionen zusätzlich `challenge (bool)` (M10, siehe docs/M10-plan.md).
- Gute Übung: echtes Werkzeug, realistische Daten, Ergebnis interpretieren. Arten: Code schreiben, Ausgabe deuten (`interpret`), zwischen Paketen übersetzen, Fehler finden (`debug`), Lücken (`complete`) bei neuen Themen.
- Checks laufen im Browser als R-Code (quarto-live `check`), gemeinsame Hilfsfunktionen in `tools/checks.R` (value/object/output; später function/plot).
- Alte 65 Aufgaben (Tag `v0-shiny`, `inst/exercises/`): gute einsortieren und anpassen, schwache streichen – Liste zur Freigabe durch Nick.

## Daten
Simuliert, dokumentiert, mit bekannten eingebauten Effekten, **englische Spaltennamen und Faktorstufen** (Code in beiden Sprachen identisch). Skripte in `data-raw/`, Dateien in `data/`.
1. Fahrsimulator (Messwiederholung; `driving_sim` umbenannt: `participant`, `condition = visual/auditory/haptic`, `rt_ms`, …)
2. Fragebogenstudie (Likert, SUS, NASA-TLX, umgepolte Items, fehlende Werte)
3. Usability-Test (Erfolg, Zeit, Fehler je Person × Prototyp)
4. Unordentlicher Rohexport (Excel/CSV mit Kopfzeilenmüll, Datumsformaten, Freitext)
Weitere bei Bedarf, auch außerhalb von HF/UX (z. B. für komplexere Analysen).

## Lernförderung
| Prinzip | Umsetzung |
|---|---|
| Erst erklären (Novizen, Expertise-Reversal beachten) | Lektionen: Erklärung → Beispiel → Übung; Expert: Herausforderung zuerst |
| Abrufübung | Wiederholung: Aufgabe zuerst, Hinweise auf Abruf, Link zurück zur Lektion |
| Verteiltes Üben | Leitner Boxen 1–5, Intervalle 0/1/3/7/21 Tage; falsch → Box 1; Leicht +1, Okay =, Schwer −1; „Leicht“ nur bei < 2 Hinweisen |
| Sicherheits-Rating | nur auf der Wiederholungsseite (1–3 vor dem Prüfen); sicherer Fehler → ausführliches Feedback |
| Interleaving | Wiederholungsseite mischt Themen |
| Fehler lernen | `debug`, `misconception`, `common_mistakes` mit Begründung |
| Transfer | Paketvergleich, Mini-Projekte je Stufe |
Keine Punkte, Abzeichen, Ranglisten; dezenter Fortschritt, Serie (Streak) nur auf der Wiederholungsseite.

## Wiederholung und Fortschritt
- Fortschritt in **localStorage** (versioniertes JSON), Export/Import als Datei.
- quarto-live meldet Prüfergebnisse nicht per API: Ergebnis aus dem Feedback-DOM mitlesen (MutationObserver), danach Knöpfe Leicht/Okay/Schwer.
- Wiederholungsseite: eine Karte pro Übung, Pakete der Karte erst bei Bedarf laden. Prüfungsmodus entfällt.

## Oberfläche und Navigation
Wayfinding (Skill `cognitive-accessibility:wayfinding-navigation`): jederzeit klar „Wo bin ich, wohin kann ich, wie zurück?“.
- Kopfzeile auf jeder Seite gleich: Kursplan · Wiederholen (n fällig) · Pakete · Glossar · Suche · DE/EN · Hell/Dunkel.
- Startseite **Kursplan**: Themen×Stufen-Matrix, Status je Zelle (nicht begonnen / begonnen / abgeschlossen) + „x fällig“; Kasten „Heute wiederholen (n)“.
- Lektion: Breadcrumb „Kursplan › Stufe › Thema“, links Abschnitte mit Häkchen, „Abschnitt x von 7“, rechts Inhaltsverzeichnis, unten Zurück/Weiter (Weiter = nächstes Thema derselben Stufe).
- **Paket-Steckbriefe**: wofür, 5–10 Kernfunktionen mit Minibeispiel, Stolperfallen, Lektionen, Doku-Link; entstehen mit den Lektionen.
- **Glossar** DE↔EN.
- Optik (Skill `ui-ux-pro-max`): Swiss/minimal, inhaltsorientiert, Lesebreite ~70 Zeichen; IBM Plex Sans + JetBrains Mono; eine Akzentfarbe (Indigo), Grün/Rot/Gelb nur für Status, immer mit Symbol; Hell + Dunkel (Systemstandard); WCAG AA (Kontrast 4,5:1, Tastatur, sichtbarer Fokus, reduced motion).
- Ladezeit: Ladeanzeige mit Text beim ersten Start (10–30 s), Pakete nur pro Lektion.

## Zweisprachigkeit
Zwei Seitenbäume `/de/` und `/en/` aus einem Quarto-Projekt; Umschalter führt zur gleichen Stelle. Gleiche Übungs-IDs, Fortschritt sprachübergreifend. Deutsch zuerst, nach Abnahme durch Nick Englisch übersetzen und prüfen. Code, Daten und Ausgaben identisch; Fachbegriffe im Glossar.

## Repository
Tag `v0-shiny` sichert den alten Stand. Umbau im selben Repo: R-Paket (R/, man/, tests/, DESCRIPTION, NAMESPACE, inst/, vignettes/) entfällt. Ziel:
`_quarto.yml`, `de/`, `en/`, `exercises/`, `data/`, `data-raw/`, `tools/` (Generator, Selbsttest, Checks), `assets/` (CSS, JS: Fortschritt, Wiederholung, Quiz, Sprache), `tests/` (Browser-Rauchtest), `_extensions/` (quarto-live).

## Qualitätssicherung (GitHub Actions bei jedem Push)
1. Selbsttest aller Übungen in normalem R: Lösung besteht, Starter scheitert.
2. `quarto render` (beide Sprachen).
3. Browser-Rauchtest einer Lektion mit webR (Playwright/Chrome): Übung lösen, prüfen, Fortschritt gespeichert.
4. Bei Erfolg auf `main`: Deploy auf GitHub Pages.
Lokal: Verifikation über den Subagenten `rtrainer-verifier`.

## Meilensteine
6. Grundgerüst + **Prototyp „Gruppenvergleiche – Beginner“ (DE)**: Quarto-Projekt, quarto-live, Theme, Kopfzeile/Navigation, Kursplan-Matrix (eine aktive Zelle), Lektion mit 3 Übungen aus YAML, Wissenscheck, Fortschritt (localStorage), Selbsttest, CI (Selbsttest + Render + Pages). Datensatz Fahrsimulator (umbenannt). → Abnahme durch Nick (Optik, Aufbau), erst dann weiter.
7. Wiederholungsseite (Leitner, Rating, Streak), Export/Import, Paket-Steckbrief- und Glossar-Vorlage, EN-Fassung des Prototyps + Sprachumschalter, Browser-Rauchtest in CI.
8. Datensätze 2–4; Triage der alten 65 Aufgaben (Liste zur Freigabe); Beginner-Pfad (Themen 1–4, 6–8, 10, 12, 21) DE, nach Abnahme EN; Mini-Projekt Beginner.
9. Intermediate-Stufe. 10. Expert-Stufe. 11. Spezialthemen (18–20), Feinschliff.
Nach jedem Meilenstein: Selbsttest + Render grün (echte Ausgabe), kurze Zusammenfassung, STATUS.md aktualisieren.

## Abnahmekriterien
- Seite läuft auf GitHub Pages und lokal (`quarto preview`); erste Lektion nutzbar nach ≤ 30 s Erstladen, ≤ 5 s bei erneutem Besuch; Prüfen ≤ 3 s (außer schwere Modelle, dann Hinweis).
- Fortschritt bleibt nach Neuladen und Browser-Neustart; Export/Import funktioniert.
- Alle Übungen: Selbsttest grün in CI.
- Jede veröffentlichte Lektion in DE und EN; Umschalter landet an gleicher Stelle.
- Wayfinding-Checkliste erfüllt; WCAG AA (Kontrast, Tastatur, Fokus).
- Neue Übung als YAML in < 10 Minuten hinzufügbar.

## Skill-Einsatz
| Bereich | Skill/Agent |
|---|---|
| Navigation, Informationsarchitektur | cognitive-accessibility:wayfinding-navigation |
| Optik, Komponenten, Barrierefreiheit | ui-ux-pro-max:ui-ux-pro-max, frontend-design |
| Übungen schreiben | rtrainer-write-exercise |
| Verifikation | rtrainer-verify / Subagent rtrainer-verifier |
| R-Code-Stil | r-tidyverse-style |
Projektregeln haben Vorrang vor allgemeinen Skills.

## Ausgabeformat pro Meilenstein
(1) Entscheidungen, (2) geänderte Dateien, (3) Befehle zum Testen, (4) ehrlicher Status, (5) nächster Schritt.
