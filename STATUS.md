# STATUS

Stand (2026-10-26): **M6–M8.1 in `main`. Meilenstein 8 Teil 2a auf Branch `m8-part2`:** Check-Typ `plot`, `langs` pro Lektion, Beginner-Lektionen working-with-r, import, cleaning (nur DE). Wartet auf Abnahme. Nichts gepusht (`main` ist `origin/main` voraus). Entscheidungen: NEWS.md.

## Was steht
- **Gerüst (M6):** Quarto-Website mit quarto-live/webR, Theme hell/dunkel (IBM Plex Sans, JetBrains Mono, Indigo), Kopfzeile Kursplan · Wiederholen (n fällig) · Pakete · Glossar · DE/EN · Hell/Dunkel · Suche.
- **Kursplan** (`de/index.qmd`, `en/index.qmd`): Matrix 23 Themen × 3 Stufen, Status je Zelle, „Weitermachen mit / Als Nächstes“, „Heute wiederholen (n)“.
- **Lektionen:** `working-with-r-beginner`, `import-beginner`, `cleaning-beginner` (nur DE, `langs: [de]`; 10 Pflicht- + 5 Zusatzübungen, je 5 Fragen Wissenscheck) und `group-comparisons-beginner` in DE und EN: Breadcrumb, Lektionskasten mit Fortschritt, links „Abschnitt x von 7“ (ab 1200 px), rechts Inhaltsverzeichnis, 3 Pflichtübungen (YAML), Wissenscheck (5 Fragen, ≥ 80 %), Spickzettel, Zurück/Weiter.
- **Wiederholung** (`review.qmd`): Leitner Boxen 1–5 (0/1/3/7/21 Tage), Sicherheits-Rating vor dem Prüfen, Leicht/Okay/Schwer, Serie, Mischen nach Lektionen; R lädt erst beim Start. Export/Import des Fortschritts (`#backup`).
- **Pakete und Glossar** aus YAML (`content/packages/*.yml`, `content/glossary.yml`), Vorlagen für weitere Einträge.
- **Sprachen:** `/de/` und `/en/`; Umschalter führt zur gleichen Seite und zum gleichen Abschnitt; Fortschritt sprachübergreifend.
- **Werkzeuge:** `tools/generate.R` (pre-render; `langs` in lesson.yml), `tools/checks.R` (value/object/output/plot), `tools/selftest.R`, Tests `tools/tests/` (R) und `tests/js/` (Node), Browser-Rauchtest `tests/smoke-test.R`.
- **CI** `.github/workflows/site.yaml`: Selbsttest, R- und Node-Tests, Render, Rauchtest, Pages-Deploy auf `main`.
- **Daten (M8.1):** `driving_sim`, `survey` (Fragebogen: SUS, NASA-TLX, Vertrauen mit umgepolten Items, fehlende Werte, Aufmerksamkeitsfrage), `usability` (24 × 3 Prototypen × 4 Aufgaben, Lateinisches Quadrat, Timeout 180 s, p07 ohne C), `raw_export` (.csv mit `;`/Dezimalkomma) + `raw_export_xlsx` (gleiche Antworten, Titel-/Summenzeilen, gemischte Datumsformate, Codebook). Skripte in `data-raw/`, Einträge in `data/datasets.yml`, Tests `tools/tests/test-datasets.R`.
- **Triage** `docs/legacy-triage.md`: 54 behalten (18 im Beginner-Pfad), 11 streichen, freigegeben. Migriert: 6 (markiert).
- Alt: `legacy/exercises/` (65 Aufgaben), `legacy/driving_sim_v0.*`.

## Geprüft (2026-10-26, m8-part2)
Über `rtrainer-verifier` (echte Ausgabe, gekürzt):
- `Rscript tools/selftest.R`: 18/18 exercises ok
- `testthat::test_dir("tools/tests")`: 170 Erwartungen, 0 failed, 0 skipped, 0 error; `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, 14 Seiten, 0 Warnungen
- `Rscript tests/smoke-test.R`: 13/13 ok, 0 failure(s) (Prototyp: webR + Pakete 12,2 s; Bereinigen: 6 Pakete 15,7 s, Prüfen 0,5 s)
- Manuell im Browser (M7): Wiederholungsrunde (sicherer Fehler, Okay, Lösung angesehen → Box 1, Wiederaufnahme), Sprachumschalter landet am gleichen Abschnitt, Pakete/Glossar DE+EN.

## Offen / bekannte Lücken
- **Abnahme M8.2a** durch Nick (drei Lektionen DE, Inhalt und Umfang). Neue Lektionen nicht manuell im Browser durchgeklickt, nur Rauchtest (eine Übung in cleaning).
- Check-Typ `plot` ist nur mit Unit-Tests geprüft, noch in keiner Lektion im Browser.
- webR-Index geprüft (alle Kurspakete inkl. lme4, lmerTest, here vorhanden); Ladezeiten großer Pakete (lme4, gtsummary) noch nicht gemessen.
- **Push + Pages:** Repo-Einstellung Pages-Quelle = „GitHub Actions“ setzen, dann pushen (nur nach Rückfrage). Ladezeit online messen (lokal: webR + Pakete ca. 12 s bei warmem Cache, Erststart ca. 30 s).
- quarto-live-Ladeanzeige („Downloading webR/package …“) bleibt englisch; Code in Lektionsübungen bleibt nach Neuladen nicht erhalten (nur der Gelöst-Status).
- Wiederholungs-Editor ist ein einfaches Textfeld (kein Syntax-Highlighting).
- Linke Abschnittsleiste nur ab 1200 px; darunter übernimmt Quartos Inhaltsverzeichnis.
- Kursplan: „nicht vorgesehen“-Zellen werden vom Screenreader einzeln vorgelesen (19×); ggf. kürzen.

## Als Nächstes
1. Abnahme der drei Lektionen; Änderungen einarbeiten; `m8-part2` nach `main` mergen.
2. M8 Teil 2b: Beginner-Lektionen reshaping, visualisation, descriptives (DE) mit den freigegebenen alten Aufgaben (Check `plot` für 4 Visualisierungsaufgaben); danach 2c: scales, regression, reporting (neu: survey, usability).
3. Nach Abnahme EN-Fassung aller Beginner-Lektionen (`langs` entfernen), Mini-Projekt Beginner.
4. Pages einrichten, pushen (nur nach Rückfrage).

## Umgebung
- Quarto 1.10.19, R 4.6.1, Node 18, quarto-live 0.1.3-dev (`_extensions/r-wasm/live`, webR 0.6.0).
- gh angemeldet (NikHenProj, Scopes repo/workflow).
- Chromium: `~/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome` (`CHROMOTE_CHROME` in `~/.Renviron`).
- Lokale Vorschau der gebauten Seite: `.claude/launch.json` „site“ (python http.server auf `_site`, Port 4321); alternativ `quarto preview`.
- Hinweis Browser-Tests: quarto-live rendert Editoren nur, wenn die Seite sichtbar ist (im versteckten Tab bleiben sie leer); headless Chrome ist unproblematisch.
