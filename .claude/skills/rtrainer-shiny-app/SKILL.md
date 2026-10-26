---
name: rtrainer-shiny-app
description: Use when working on the rtrainer Shiny UI or server (start(), app_ui, app_server, dashboard, exam/daily mode, editor, feedback box, confidence rating, accessibility, testServer or shinytest2 tests).
---

# Shiny-Konventionen (projektspezifisch)

Layout, bslib und Theming: Skill `shiny-bslib`. Browser-Tests: `webapp-testing` oder `shinytest2`.

- Logik in reine Funktionen auslagern; `app_server` dünn und per `shiny::testServer()` testbar.
- UI: `bslib::page_sidebar`, Dark/Light-Umschalter, Editor `shinyAce` (R-Modus, Autovervollständigung, Strg+Enter = Ausführen).
- Buttons: Ausführen, Prüfen, Hinweis (stufenweise), Lösung (erst nach Versuch oder Bestätigung), Zurücksetzen, Weiter.
- Feedback-Box: Farbe UND Symbol (✓ ✗ !). Prüfen darf die App nie abstürzen lassen.
- Feedback < 2 s: Pakete nur laden, wenn `packages` es verlangt.

## Lernförderung in der UI
- Kein Beispiel vor dem Versuch. Erst Aufgabe, dann Hinweise auf Abruf.
- Vor "Prüfen": optionales Sicherheits-Rating (1 unsicher, 2 ziemlich, 3 sicher; per Taste 1-3; abschaltbar in den Einstellungen) -> `record_attempt(confidence=)`.
- Sicherer Fehler (`is_confident_error()`): hervorgehobenes, ausführliches Feedback (Erwartung vs. Ergebnis, `misconception`, Erklärung) und Aufgabe noch in dieser Sitzung erneut vorlegen.
- Nach Lösung: Erklärung + Leicht/Okay/Schwer; "Leicht" wird bei >= 2 Hinweisen auf "Okay" gedeckelt (`record_rating(hints=)`).
- Nach Lösung optional: "In einem Satz: warum funktioniert das?" (Selbsterklärung, nur Anzeige/Notiz, keine Bewertung).
- Daily-Modus: gemischte Themen (`pick_session()` interleavt), nicht blockweise. Freier Modus: Themenwahl erlaubt.
- Dashboard: zusätzlich Kalibrierung (Trefferquote je Sicherheitsstufe) und Fehlerjournal (häufigste `misconception`/`common_mistakes`).
- Modus `exam`: keine Hinweise/Lösung, Timer, Gesamtauswertung.
- Tests: `testServer` für Logik, ein Smoke-Test mit `skip_on_cran()`.
