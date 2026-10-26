# STATUS

Stand (2026-10-26, nachts): **Meilenstein 6 auf `main` committet (0002732), Meilenstein 7 auf Branch `m7-wip` umgesetzt.** Beides wartet auf Nicks Abnahme. Nichts gepusht. Entscheidungen im Detail: NEWS.md („Milestone 6“, „Milestone 7“).

## Was steht
- **Gerüst (M6):** Quarto-Website mit quarto-live/webR, Theme hell/dunkel (IBM Plex Sans, JetBrains Mono, Indigo), Kopfzeile Kursplan · Wiederholen (n fällig) · Pakete · Glossar · DE/EN · Hell/Dunkel · Suche.
- **Kursplan** (`de/index.qmd`, `en/index.qmd`): Matrix 23 Themen × 3 Stufen, Status je Zelle, „Weitermachen mit / Als Nächstes“, „Heute wiederholen (n)“.
- **Lektion** `group-comparisons-beginner` in DE und EN: Breadcrumb, Lektionskasten mit Fortschritt, links „Abschnitt x von 7“ (ab 1200 px), rechts Inhaltsverzeichnis, 3 Pflichtübungen (YAML), Wissenscheck (5 Fragen, ≥ 80 %), Spickzettel, Zurück/Weiter.
- **Wiederholung** (`review.qmd`): Leitner Boxen 1–5 (0/1/3/7/21 Tage), Sicherheits-Rating vor dem Prüfen, Leicht/Okay/Schwer, Serie, Mischen nach Lektionen; R lädt erst beim Start. Export/Import des Fortschritts (`#backup`).
- **Pakete und Glossar** aus YAML (`content/packages/*.yml`, `content/glossary.yml`), Vorlagen für weitere Einträge.
- **Sprachen:** `/de/` und `/en/`; Umschalter führt zur gleichen Seite und zum gleichen Abschnitt; Fortschritt sprachübergreifend.
- **Werkzeuge:** `tools/generate.R` (pre-render), `tools/checks.R`, `tools/selftest.R`, Tests `tools/tests/` (R) und `tests/js/` (Node), Browser-Rauchtest `tests/smoke-test.R`.
- **CI** `.github/workflows/site.yaml`: Selbsttest, R- und Node-Tests, Render, Rauchtest, Pages-Deploy auf `main`.
- Alt: `legacy/exercises/` (65 Aufgaben), `legacy/driving_sim_v0.*`.

## Geprüft (2026-10-26)
Über `rtrainer-verifier` (echte Ausgabe, gekürzt):
- `Rscript tools/selftest.R`: 3/3 exercises ok
- `testthat::test_dir("tools/tests")`: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 105 ]; `node --test tests/js`: 11 pass, 0 fail
- `quarto render`: Exit 0, 0 Warnungen
- `Rscript tests/smoke-test.R`: 10/10 ok (webR + Pakete 12 s, Prüfen 0,5 s, Wiederholungskarte 4 s), 0 failure(s)
- Manuell im Browser: Wiederholungsrunde (sicherer Fehler, Okay, Lösung angesehen → Box 1, Wiederaufnahme), Sprachumschalter landet am gleichen Abschnitt, Pakete/Glossar DE+EN.

## Offen / bekannte Lücken
- **Abnahme durch Nick:** Optik, Aufbau, Lektionsformat (M6) und Wiederholungsseite, EN-Fassung (M7). Bei Gefallen `m7-wip` in `main` mergen.
- **Push + Pages:** Repo-Einstellung Pages-Quelle = „GitHub Actions“ setzen, dann pushen (nur nach Rückfrage). Ladezeit online messen (lokal: webR + Pakete ca. 12 s bei warmem Cache, Erststart ca. 30 s).
- quarto-live-Ladeanzeige („Downloading webR/package …“) bleibt englisch; Code in Lektionsübungen bleibt nach Neuladen nicht erhalten (nur der Gelöst-Status).
- Wiederholungs-Editor ist ein einfaches Textfeld (kein Syntax-Highlighting).
- Linke Abschnittsleiste nur ab 1200 px; darunter übernimmt Quartos Inhaltsverzeichnis.
- Kursplan: „nicht vorgesehen“-Zellen werden vom Screenreader einzeln vorgelesen (19×); ggf. kürzen.

## Als Nächstes
1. Abnahme M6/M7, Änderungswünsche einarbeiten, `m7-wip` mergen, Pages einrichten, pushen.
2. Meilenstein 8: Datensätze 2–4 (Fragebogen, Usability-Test, Rohexport), Triage der 65 alten Aufgaben (Liste zur Freigabe), Beginner-Pfad (Themen 1–4, 6–8, 10, 12, 21) DE, nach Abnahme EN, Mini-Projekt Beginner.

## Umgebung
- Quarto 1.10.19, R 4.6.1, Node 18, quarto-live 0.1.3-dev (`_extensions/r-wasm/live`, webR 0.6.0).
- gh angemeldet (NikHenProj, Scopes repo/workflow).
- Chromium: `~/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome` (`CHROMOTE_CHROME` in `~/.Renviron`).
- Lokale Vorschau der gebauten Seite: `.claude/launch.json` „site“ (python http.server auf `_site`, Port 4321); alternativ `quarto preview`.
- Hinweis Browser-Tests: quarto-live rendert Editoren nur, wenn die Seite sichtbar ist (im versteckten Tab bleiben sie leer); headless Chrome ist unproblematisch.
