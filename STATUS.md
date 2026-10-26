# STATUS

Stand (2026-10-26): **M6 bis M8 Teil 5 abgenommen und in `main`** (alle 10 Beginner-Lektionen und Mini-Projekt Beginner, DE + EN). **Online seit 2026-10-26:** https://nikhenproj.github.io/rtrainer/ (Pages-Quelle GitHub Actions, CI-Lauf 40326391796 grün). M9-Plan abgenommen (inkl. Datensatz `acceptance`): `docs/M9-plan.md`. Entscheidungen: NEWS.md.

## Was steht
- **Gerüst (M6):** Quarto-Website mit quarto-live/webR, Theme hell/dunkel (IBM Plex Sans, JetBrains Mono, Indigo), Kopfzeile Kursplan · Wiederholen (n fällig) · Pakete · Glossar · DE/EN · Hell/Dunkel · Suche.
- **Kursplan** (`de/index.qmd`, `en/index.qmd`): Matrix 23 Themen × 3 Stufen, Status je Zelle, „Weitermachen mit / Als Nächstes“, „Heute wiederholen (n)“.
- **Lektionen:** `working-with-r-beginner`, `import-beginner`, `cleaning-beginner`, `reshaping-beginner`, `visualisation-beginner`, `descriptives-beginner`, `scales-beginner`, `regression-beginner`, `reporting-beginner` (33 Pflicht- + 13 Zusatzübungen, je 5 Fragen Wissenscheck). Alle in DE und EN (keine `langs`-Einschränkung mehr). Aufbau: Breadcrumb, Lektionskasten mit Fortschritt, links „Abschnitt x von 7“ (ab 1200 px), rechts Inhaltsverzeichnis, 3 Pflichtübungen (YAML), Wissenscheck (5 Fragen, ≥ 80 %), Spickzettel, Zurück/Weiter.
- **Mini-Projekt Beginner (DE + EN):** `project-beginner`, eigene Zeile „Mini-Projekt“ unter den 23 Themen (`kind: project` in curriculum.yml), Pfad nach reporting-beginner. Auftrag mit Analyseplan → 5 Schritte mit je einer Pflichtübung (Import, Ausschluss, Skalen, Welch-t-Test, Tabelle 1, Ergebnisse deuten; 6 Pflicht + 1 Zusatz `pj-b-tlx-subscales`) → Gesamtskript (live) + „Lokal ausführen“ (Quarto → docx) → Wissenscheck (5) → Checkliste. Generator schreibt zusätzlich `exercise-<id>.qmd` je Übung; Check-Option `check_types`; Wiederholungskarten rendern Tabellen/Listen/Zitate.
- **Wiederholung** (`review.qmd`): Leitner Boxen 1–5 (0/1/3/7/21 Tage), Sicherheits-Rating vor dem Prüfen, Leicht/Okay/Schwer, Serie, Mischen nach Lektionen; R lädt erst beim Start. Export/Import des Fortschritts (`#backup`).
- **Pakete und Glossar** aus YAML (`content/packages/*.yml`, `content/glossary.yml`), Vorlagen für weitere Einträge.
- **Sprachen:** `/de/` und `/en/`; Umschalter führt zur gleichen Seite und zum gleichen Abschnitt; Fortschritt sprachübergreifend.
- **Werkzeuge:** `tools/generate.R` (pre-render; `langs` in lesson.yml), `tools/checks.R` (value/object/output/plot; plot: Ebenen, aes, Settings, Position, Ebenendaten, Facets, Skalen; gtsummary-Tabellen nach Inhalt; Neuauswertung bei falschem `last_value`), `tools/selftest.R`, Tests `tools/tests/` (R) und `tests/js/` (Node), Browser-Rauchtest `tests/smoke-test.R`.
- **CI** `.github/workflows/site.yaml`: Selbsttest, R- und Node-Tests, Render, Rauchtest, Pages-Deploy auf `main`.
- **Daten (M8.1):** `driving_sim`, `survey` (Fragebogen: SUS, NASA-TLX, Vertrauen mit umgepolten Items, fehlende Werte, Aufmerksamkeitsfrage), `usability` (24 × 3 Prototypen × 4 Aufgaben, Lateinisches Quadrat, Timeout 180 s, p07 ohne C), `raw_export` (.csv mit `;`/Dezimalkomma) + `raw_export_xlsx` (gleiche Antworten, Titel-/Summenzeilen, gemischte Datumsformate, Codebook). Skripte in `data-raw/`, Einträge in `data/datasets.yml`, Tests `tools/tests/test-datasets.R`.
- **Triage** `docs/legacy-triage.md`: 54 behalten (18 im Beginner-Pfad), 11 streichen, freigegeben. Migriert: 18 (markiert), damit alle Beginner-Aufgaben der Triage.
- Alt: `legacy/exercises/` (65 Aufgaben), `legacy/driving_sim_v0.*`.

## Geprüft (2026-10-26, M8 Teil 5)
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/selftest.R`: 56/56 exercises ok (Warnungen erwartet: `ymd_hms` in cl-b-dates, psych in sc-b-alpha)
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 4 | SKIP 0 | PASS 210; `node --test tests/js`: 12 pass, 0 fail
- `Rscript tools/generate.R`: Generated 229 files, 56 exercises. `quarto render`: Exit 0, 0 Warnungen; `_site/en/project-beginner.html` vorhanden
- `Rscript tests/smoke-test.R`: 0 failure(s); neu „en: project row links the English page“, „en: project page in English with exercises“ ok
- EN-Projektseite nicht manuell im Browser durchgeklickt (nur Rauchtest: Titel, Übung, Gesamtskript vorhanden); EN-Übungen nicht im Browser bewertet (selbe IDs/Checks wie DE).

## Online (2026-10-26)
- CI (build 4,5 min, deploy 1,4 min): `56/56 exercises ok`, `[ FAIL 0 | WARN 4 | SKIP 0 | PASS 210 ]`, Node 12/0, `Generated 229 files`, Rauchtest `0 failure(s)`.
- Ladezeit online (headless Chrome, bis alle „Run“-Knöpfe bereit; Erststart = frischer Browser / warm = neu laden): gruppenvergleiche 13,6 / 10,2 s; regression 15,1 / 11,7 s; Mini-Projekt (6 Pakete) 21,1 / 15,8 s. Nur eine Messung, gute Leitung.
- Hinweis aus CI: `ubuntu-latest` wechselt ab 19.10.2026 auf Ubuntu 26; Lauf war schon grün, bei Fehlern `ubuntu-24.04` festsetzen.

## Offen / bekannte Lücken
- Beginner-Lektionen 1–6 nicht manuell im Browser durchgeklickt (7–9 nur die Übungen, nicht Wissenscheck/Optik), nur Rauchtest (je eine Übung in cleaning und visualisation); Beispiel-Plots und SVG-Abbildungen von reshaping/visualisation/descriptives optisch nicht geprüft.
- Plot-Check vergleicht feste Werte nicht (welche Farbe, `ncol`), nur ob gesetzt; Position und Daten eigener Ebenen (Referenzlinien) schon.
- webR-Index geprüft (alle Kurspakete inkl. lme4, lmerTest, here, broom.helpers, flextable vorhanden); gtsummary-Seite lokal 15 s bei warmem Cache, lme4 noch nicht gemessen. broom.helpers wird angehängt und überdeckt gtsummary-Hilfsfunktionen (gleiche Funktionen, nur Meldung in der Konsole).
- quarto-live-Ladeanzeige („Downloading webR/package …“) bleibt englisch; Code in Lektionsübungen bleibt nach Neuladen nicht erhalten (nur der Gelöst-Status).
- Wiederholungs-Editor ist ein einfaches Textfeld (kein Syntax-Highlighting).
- Linke Abschnittsleiste nur ab 1200 px; darunter übernimmt Quartos Inhaltsverzeichnis.
- Kursplan: „nicht vorgesehen“-Zellen werden vom Screenreader einzeln vorgelesen (19×); ggf. kürzen.

## Als Nächstes
1. M9 Paket P1 (DE): import-, cleaning-, reshaping-intermediate.

## Umgebung
- Quarto 1.10.19, R 4.6.1, Node 18, quarto-live 0.1.3-dev (`_extensions/r-wasm/live`, webR 0.6.0).
- gh angemeldet (NikHenProj, Scopes repo/workflow).
- Chromium: `~/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome` (`CHROMOTE_CHROME` in `~/.Renviron`).
- Lokale Vorschau der gebauten Seite: `.claude/launch.json` „site“ (python http.server auf `_site`, Port 4321); alternativ `quarto preview`.
- Hinweis Browser-Tests: quarto-live rendert Editoren nur, wenn die Seite sichtbar ist (im versteckten Tab bleiben sie leer); headless Chrome ist unproblematisch.
