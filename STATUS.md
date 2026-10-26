# STATUS

Stand (2026-10-26): **Meilenstein 6 umgesetzt, wartet auf Abnahme durch Nick** (Optik, Aufbau). Quarto-Website mit quarto-live/webR, erste Lektion „Gruppenvergleiche – Beginner“ (DE). Entscheidungen im Detail: NEWS.md, Abschnitt „Milestone 6“.

## Was steht
- Grundgerüst: `_quarto.yml` (Website, Theme hell/dunkel, IBM Plex Sans/JetBrains Mono, Indigo), Kopfzeile Kursplan · Wiederholen (n fällig) · Pakete · Glossar · EN · Hell/Dunkel · Suche.
- Kursplan `de/index.qmd`: Matrix 23 Themen × 3 Stufen, eine aktive Zelle mit Status, Kasten „Heute wiederholen“ (erscheint ab fälligen Übungen).
- Lektion `de/group-comparisons-beginner.qmd`: Breadcrumb, Lektionskasten (Dauer, Voraussetzungen, Pakete, Daten, Lernziele, Fortschritt), links „Abschnitt x von 7“ mit Häkchen (ab 1200 px), rechts Inhaltsverzeichnis, unten Zurück/Weiter; 3 Pflichtübungen, Wissenscheck (5 Fragen, ≥ 80 %), Spickzettel.
- Übungen als YAML in `exercises/group-comparisons/beginner/` (+ `lesson.yml`, `quiz.yml`); `tools/generate.R` (läuft als Quarto-pre-render), `tools/checks.R` (Browser + Selbsttest), `tools/selftest.R`, Tests in `tools/tests/`.
- Daten: `data/driving_sim.csv` (englische Namen, Skript `data-raw/driving_sim.R`), Laden über `data/datasets.yml`.
- Fortschritt: localStorage `rtrainer.progress` (Version 1), Abschluss → Wiederholung Box 1, fällig am Folgetag.
- CI: `.github/workflows/site.yaml` (Selbsttest, Werkzeug-Tests, Render, Pages-Deploy auf main). Noch nicht gepusht.
- Alt: `legacy/exercises/` (65 Aufgaben), `legacy/driving_sim_v0.*`.

## Geprüft (2026-10-26)
- `Rscript tools/selftest.R`: 3/3 ok. `testthat::test_dir("tools/tests")`: FAIL 0, PASS 77. `quarto render`: Exit 0, keine Warnungen.
- Im Browser (lokal, Chromium-Pane): webR lädt (Erststart ca. 30 s inkl. Pakete), alle 3 Übungen: Starter scheitert mit passender Meldung, Lösung „Richtig!“; Fortschritt, Wissenscheck (4/5 = bestanden), Abschluss und Wiederholungseintrag in localStorage; Kursplan zeigt „abgeschlossen“. Kontrast hell/dunkel ≥ 6:1, mobil ohne horizontales Scrollen.

## Offene Punkte / bekannte Lücken
- GitHub Pages: Quelle muss einmalig auf „GitHub Actions“ stehen (Repo-Einstellungen), dann Push (nur nach Rückfrage).
- Browser-Rauchtest in CI fehlt (M7, `tests/`).
- quarto-live lädt alle Lektionspakete beim Seitenstart; Pakete werden bei jedem Seitenaufruf neu aus dem webR-Repo geholt (Browser-Cache hilft). Ladezeit auf GitHub Pages messen.
- Englische quarto-live-Texte werden per JS übersetzt; die Ladeanzeige („Downloading webR/package …“) bleibt englisch.
- Linke Abschnittsleiste nur ab 1200 px; darunter übernimmt Quartos Inhaltsverzeichnis.
- Wiederholen, Pakete, Glossar und EN sind Platzhalterseiten.

## Als Nächstes
1. Abnahme durch Nick (Optik, Aufbau, Lektionsformat); Änderungswünsche einarbeiten.
2. Pages-Quelle setzen, pushen, Ladezeit online prüfen.
3. Meilenstein 7: Wiederholungsseite (Leitner, Sicherheits-Rating, Streak), Export/Import, Vorlagen Paket-Steckbrief und Glossar, EN-Fassung des Prototyps + Sprachumschalter, Browser-Rauchtest in CI.

## Umgebung
- Quarto 1.10.19, R 4.6.1, quarto-live 0.1.3-dev (`_extensions/r-wasm/live`, webR 0.6.0).
- gh angemeldet (NikHenProj, Scopes repo/workflow).
- Chromium für Browser-Tests: `~/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome`.
- Lokale Vorschau der gebauten Seite: `.claude/launch.json` „site“ (python http.server auf `_site`, Port 4321); alternativ `quarto preview`.
- Hinweis Browser-Tests: quarto-live rendert Editoren erst, wenn die Seite sichtbar ist (OJS); im versteckten Tab bleiben sie leer.
