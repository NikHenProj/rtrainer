---
name: rtrainer-verify
description: Use after changing exercises, lessons, tools (generator, checks, self-test), assets or the Quarto config of the rtrainer course, or when asked to verify, test, check, or validate it. Runs the exercise self-test, tool tests, render and browser smoke test in order and reports real output.
---

# Verify rtrainer (Quarto-Kurs)

Bevorzugt über den Subagenten `rtrainer-verifier` ausführen (spart Hauptkontext). Die Befehle entstehen in Meilenstein 6; fehlt ein Skript, das ausdrücklich melden statt es zu überspringen.

Reihenfolge, beim ersten Fehler stoppen, beheben, bei 1 neu beginnen:
1. `Rscript tools/selftest.R` – alle Übungen: Lösung besteht, Starter scheitert.
2. Tests der Werkzeuge (Generator, Checks): `Rscript -e 'testthat::test_dir("tools/tests")'`; Fortschrittslogik: `node --test tests/js`.
3. `quarto render` – ohne Fehler/Warnungen, beide Sprachen.
4. Browser-Rauchtest: `Rscript tests/smoke-test.R` (headless Chrome, braucht Internet für webR): Lektion lösen, Fortschritt, Wiederholungskarte, EN-Seite und Sprachumschalter.

## Regeln
- Gekürzte echte Ausgabe zeigen (Fehlerzeilen, nicht das ganze Log).
- Fehler: Ursache benennen, minimal fixen, Regressionstest ergänzen.
- Übungen > 5 s im normalen R: im Browser deutlich langsamer, Aufgabe verkleinern.
- Sind R oder Quarto nicht ausführbar, das ausdrücklich melden.
