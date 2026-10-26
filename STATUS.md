# STATUS

Stand (2026-10-26): **M6 + M7 abgenommen und in `main` (Fast-Forward auf 4cca3f5). Meilenstein 8 Teil 1 ebenfalls in `main`:** Datensätze 2–4 und Triage der alten Aufgaben (freigegeben). Nichts gepusht (`main` ist `origin/main` voraus). Entscheidungen: NEWS.md.

## Was steht
- **Gerüst (M6):** Quarto-Website mit quarto-live/webR, Theme hell/dunkel (IBM Plex Sans, JetBrains Mono, Indigo), Kopfzeile Kursplan · Wiederholen (n fällig) · Pakete · Glossar · DE/EN · Hell/Dunkel · Suche.
- **Kursplan** (`de/index.qmd`, `en/index.qmd`): Matrix 23 Themen × 3 Stufen, Status je Zelle, „Weitermachen mit / Als Nächstes“, „Heute wiederholen (n)“.
- **Lektion** `group-comparisons-beginner` in DE und EN: Breadcrumb, Lektionskasten mit Fortschritt, links „Abschnitt x von 7“ (ab 1200 px), rechts Inhaltsverzeichnis, 3 Pflichtübungen (YAML), Wissenscheck (5 Fragen, ≥ 80 %), Spickzettel, Zurück/Weiter.
- **Wiederholung** (`review.qmd`): Leitner Boxen 1–5 (0/1/3/7/21 Tage), Sicherheits-Rating vor dem Prüfen, Leicht/Okay/Schwer, Serie, Mischen nach Lektionen; R lädt erst beim Start. Export/Import des Fortschritts (`#backup`).
- **Pakete und Glossar** aus YAML (`content/packages/*.yml`, `content/glossary.yml`), Vorlagen für weitere Einträge.
- **Sprachen:** `/de/` und `/en/`; Umschalter führt zur gleichen Seite und zum gleichen Abschnitt; Fortschritt sprachübergreifend.
- **Werkzeuge:** `tools/generate.R` (pre-render), `tools/checks.R`, `tools/selftest.R`, Tests `tools/tests/` (R) und `tests/js/` (Node), Browser-Rauchtest `tests/smoke-test.R`.
- **CI** `.github/workflows/site.yaml`: Selbsttest, R- und Node-Tests, Render, Rauchtest, Pages-Deploy auf `main`.
- **Daten (M8.1):** `driving_sim`, `survey` (Fragebogen: SUS, NASA-TLX, Vertrauen mit umgepolten Items, fehlende Werte, Aufmerksamkeitsfrage), `usability` (24 × 3 Prototypen × 4 Aufgaben, Lateinisches Quadrat, Timeout 180 s, p07 ohne C), `raw_export` (.csv mit `;`/Dezimalkomma) + `raw_export_xlsx` (gleiche Antworten, Titel-/Summenzeilen, gemischte Datumsformate, Codebook). Skripte in `data-raw/`, Einträge in `data/datasets.yml`, Tests `tools/tests/test-datasets.R`.
- **Triage** `docs/legacy-triage.md`: 54 behalten (18 im Beginner-Pfad), 11 streichen. Freigegeben 2026-10-26, noch nichts migriert.
- Alt: `legacy/exercises/` (65 Aufgaben), `legacy/driving_sim_v0.*`.

## Geprüft (2026-10-26, M8 Teil 1)
Über `rtrainer-verifier` (echte Ausgabe, gekürzt):
- `Rscript tools/selftest.R`: 3/3 exercises ok
- `testthat::test_dir("tools/tests")`: PASS 137, FAIL 0, SKIP 0; `node --test tests/js`: 11 pass, 0 fail
- `quarto render`: Exit 0, 0 Warnungen; `_site/data/` enthält alle 5 Datendateien
- `Rscript tests/smoke-test.R`: 10/10 ok, 0 failure(s)
- Manuell im Browser (M7): Wiederholungsrunde (sicherer Fehler, Okay, Lösung angesehen → Box 1, Wiederaufnahme), Sprachumschalter landet am gleichen Abschnitt, Pakete/Glossar DE+EN.

## Offen / bekannte Lücken
- Check-Typ `plot` fehlt noch (nötig für 4 Beginner-Visualisierungsaufgaben).
- `lme4`/`lmerTest`/`here` im webR-Index prüfen, bevor Mixed-Model- und Reproduzierbarkeits-Aufgaben migriert werden.
- **Push + Pages:** Repo-Einstellung Pages-Quelle = „GitHub Actions“ setzen, dann pushen (nur nach Rückfrage). Ladezeit online messen (lokal: webR + Pakete ca. 12 s bei warmem Cache, Erststart ca. 30 s).
- quarto-live-Ladeanzeige („Downloading webR/package …“) bleibt englisch; Code in Lektionsübungen bleibt nach Neuladen nicht erhalten (nur der Gelöst-Status).
- Wiederholungs-Editor ist ein einfaches Textfeld (kein Syntax-Highlighting).
- Linke Abschnittsleiste nur ab 1200 px; darunter übernimmt Quartos Inhaltsverzeichnis.
- Kursplan: „nicht vorgesehen“-Zellen werden vom Screenreader einzeln vorgelesen (19×); ggf. kürzen.

## Als Nächstes
1. Pages einrichten, pushen (nur nach Rückfrage).
2. M8 Teil 2: Check-Typ `plot` (mit Tests), dann Beginner-Lektionen in Paketen à 3 (DE): working-with-r, import, cleaning → reshaping, visualisation, descriptives → scales, regression, reporting; freigegebene alte Aufgaben migrieren, neue für scales/reporting/raw_export schreiben.
3. Nach Abnahme EN-Fassung, Mini-Projekt Beginner.

## Umgebung
- Quarto 1.10.19, R 4.6.1, Node 18, quarto-live 0.1.3-dev (`_extensions/r-wasm/live`, webR 0.6.0).
- gh angemeldet (NikHenProj, Scopes repo/workflow).
- Chromium: `~/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome` (`CHROMOTE_CHROME` in `~/.Renviron`).
- Lokale Vorschau der gebauten Seite: `.claude/launch.json` „site“ (python http.server auf `_site`, Port 4321); alternativ `quarto preview`.
- Hinweis Browser-Tests: quarto-live rendert Editoren nur, wenn die Seite sichtbar ist (im versteckten Tab bleiben sie leer); headless Chrome ist unproblematisch.
