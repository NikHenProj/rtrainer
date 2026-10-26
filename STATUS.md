# STATUS

Stand (2026-10-26): **M6 bis M8 Teil 3c abgenommen und in `main`** (alle 10 Beginner-Lektionen DE + EN). **M8 Teil 4 fertig, wartet auf Abnahme:** Mini-Projekt Beginner (DE), `de/project-beginner.qmd`. Nichts gepusht (`main` ist `origin/main` voraus). Entscheidungen: NEWS.md.

## Was steht
- **Gerüst (M6):** Quarto-Website mit quarto-live/webR, Theme hell/dunkel (IBM Plex Sans, JetBrains Mono, Indigo), Kopfzeile Kursplan · Wiederholen (n fällig) · Pakete · Glossar · DE/EN · Hell/Dunkel · Suche.
- **Kursplan** (`de/index.qmd`, `en/index.qmd`): Matrix 23 Themen × 3 Stufen, Status je Zelle, „Weitermachen mit / Als Nächstes“, „Heute wiederholen (n)“.
- **Lektionen:** `working-with-r-beginner`, `import-beginner`, `cleaning-beginner`, `reshaping-beginner`, `visualisation-beginner`, `descriptives-beginner`, `scales-beginner`, `regression-beginner`, `reporting-beginner` (33 Pflicht- + 13 Zusatzübungen, je 5 Fragen Wissenscheck). Alle in DE und EN (keine `langs`-Einschränkung mehr). Aufbau: Breadcrumb, Lektionskasten mit Fortschritt, links „Abschnitt x von 7“ (ab 1200 px), rechts Inhaltsverzeichnis, 3 Pflichtübungen (YAML), Wissenscheck (5 Fragen, ≥ 80 %), Spickzettel, Zurück/Weiter.
- **Mini-Projekt Beginner (DE, `langs: [de]`):** `project-beginner`, eigene Zeile „Mini-Projekt“ unter den 23 Themen (`kind: project` in curriculum.yml), Pfad nach reporting-beginner. Auftrag mit Analyseplan → 5 Schritte mit je einer Pflichtübung (Import, Ausschluss, Skalen, Welch-t-Test, Tabelle 1, Ergebnisse deuten; 6 Pflicht + 1 Zusatz `pj-b-tlx-subscales`) → Gesamtskript (live) + „Lokal ausführen“ (Quarto → docx) → Wissenscheck (5) → Checkliste. Generator schreibt zusätzlich `exercise-<id>.qmd` je Übung; Check-Option `check_types`; Wiederholungskarten rendern Tabellen/Listen/Zitate.
- **Wiederholung** (`review.qmd`): Leitner Boxen 1–5 (0/1/3/7/21 Tage), Sicherheits-Rating vor dem Prüfen, Leicht/Okay/Schwer, Serie, Mischen nach Lektionen; R lädt erst beim Start. Export/Import des Fortschritts (`#backup`).
- **Pakete und Glossar** aus YAML (`content/packages/*.yml`, `content/glossary.yml`), Vorlagen für weitere Einträge.
- **Sprachen:** `/de/` und `/en/`; Umschalter führt zur gleichen Seite und zum gleichen Abschnitt; Fortschritt sprachübergreifend.
- **Werkzeuge:** `tools/generate.R` (pre-render; `langs` in lesson.yml), `tools/checks.R` (value/object/output/plot; plot: Ebenen, aes, Settings, Position, Ebenendaten, Facets, Skalen; gtsummary-Tabellen nach Inhalt; Neuauswertung bei falschem `last_value`), `tools/selftest.R`, Tests `tools/tests/` (R) und `tests/js/` (Node), Browser-Rauchtest `tests/smoke-test.R`.
- **CI** `.github/workflows/site.yaml`: Selbsttest, R- und Node-Tests, Render, Rauchtest, Pages-Deploy auf `main`.
- **Daten (M8.1):** `driving_sim`, `survey` (Fragebogen: SUS, NASA-TLX, Vertrauen mit umgepolten Items, fehlende Werte, Aufmerksamkeitsfrage), `usability` (24 × 3 Prototypen × 4 Aufgaben, Lateinisches Quadrat, Timeout 180 s, p07 ohne C), `raw_export` (.csv mit `;`/Dezimalkomma) + `raw_export_xlsx` (gleiche Antworten, Titel-/Summenzeilen, gemischte Datumsformate, Codebook). Skripte in `data-raw/`, Einträge in `data/datasets.yml`, Tests `tools/tests/test-datasets.R`.
- **Triage** `docs/legacy-triage.md`: 54 behalten (18 im Beginner-Pfad), 11 streichen, freigegeben. Migriert: 18 (markiert), damit alle Beginner-Aufgaben der Triage.
- Alt: `legacy/exercises/` (65 Aufgaben), `legacy/driving_sim_v0.*`.

## Geprüft (2026-10-26, M8 Teil 4)
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/selftest.R`: 56/56 exercises ok (Warnungen erwartet: `ymd_hms` in cl-b-dates, psych in sc-b-alpha)
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 4 | SKIP 0 | PASS 210; `node --test tests/js`: 12 pass, 0 fail
- `Rscript tools/generate.R`: Generated 217 files, 56 exercises. `quarto render`: Exit 0, 0 Warnungen
- `Rscript tests/smoke-test.R`: 0 failure(s); neu „project: own row in the German course plan“, „character interface gets the type hint“, „import from the CSV graded correct“ ok (Projektseite bereit nach 16,7 s)
- Browser (Vorschau): Kursplan-Zeile „Mini-Projekt“ abgesetzt, ohne Nummer. Projektseite selbst nicht manuell durchgeklickt (nur Rauchtest: Import-Übung falsch/richtig); Gesamtskript lokal in R ausgeführt (160 → 157, report-Text wie erwartet), im Browser nicht.

## Offen / bekannte Lücken
- Beginner-Lektionen 1–6 nicht manuell im Browser durchgeklickt (7–9 nur die Übungen, nicht Wissenscheck/Optik), nur Rauchtest (je eine Übung in cleaning und visualisation); Beispiel-Plots und SVG-Abbildungen von reshaping/visualisation/descriptives optisch nicht geprüft.
- Plot-Check vergleicht feste Werte nicht (welche Farbe, `ncol`), nur ob gesetzt; Position und Daten eigener Ebenen (Referenzlinien) schon.
- webR-Index geprüft (alle Kurspakete inkl. lme4, lmerTest, here, broom.helpers, flextable vorhanden); gtsummary-Seite lokal 15 s bei warmem Cache, lme4 noch nicht gemessen. broom.helpers wird angehängt und überdeckt gtsummary-Hilfsfunktionen (gleiche Funktionen, nur Meldung in der Konsole).
- **Push + Pages:** Repo-Einstellung Pages-Quelle = „GitHub Actions“ setzen, dann pushen (nur nach Rückfrage). Ladezeit online messen (lokal: webR + Pakete ca. 12 s bei warmem Cache, Erststart ca. 30 s).
- quarto-live-Ladeanzeige („Downloading webR/package …“) bleibt englisch; Code in Lektionsübungen bleibt nach Neuladen nicht erhalten (nur der Gelöst-Status).
- Wiederholungs-Editor ist ein einfaches Textfeld (kein Syntax-Highlighting).
- Linke Abschnittsleiste nur ab 1200 px; darunter übernimmt Quartos Inhaltsverzeichnis.
- Kursplan: „nicht vorgesehen“-Zellen werden vom Screenreader einzeln vorgelesen (19×); ggf. kürzen.

## Als Nächstes
1. Abnahme M8 Teil 4 durch Nick (`/de/project-beginner.html` durchklicken: Seitenaufbau, Übungen 1–7, Gesamtskript, Ladezeit; Kursplan-Zeile).
2. Danach EN-Fassung des Mini-Projekts (`en/project-beginner.qmd`, `langs` entfernen, Rauchtest EN-Kursplan um `project` erweitern).
3. Pages einrichten, pushen (nur nach Rückfrage); danach CI-Lauf prüfen. Dann M9 (Intermediate).

## Umgebung
- Quarto 1.10.19, R 4.6.1, Node 18, quarto-live 0.1.3-dev (`_extensions/r-wasm/live`, webR 0.6.0).
- gh angemeldet (NikHenProj, Scopes repo/workflow).
- Chromium: `~/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome` (`CHROMOTE_CHROME` in `~/.Renviron`).
- Lokale Vorschau der gebauten Seite: `.claude/launch.json` „site“ (python http.server auf `_site`, Port 4321); alternativ `quarto preview`.
- Hinweis Browser-Tests: quarto-live rendert Editoren nur, wenn die Seite sichtbar ist (im versteckten Tab bleiben sie leer); headless Chrome ist unproblematisch.
