---
name: rtrainer-verify
description: Use after changing any R code, test, or exercise in rtrainer, or when asked to verify, test, check, or validate the package. Runs document, tests, the exercise self-check and R CMD check in order and reports real output.
---

# Verify rtrainer

Bevorzugt über den Subagenten `rtrainer-verifier` ausführen (spart Hauptkontext). Allgemeine devtools/testthat-Praxis: Skills `r-package-development`, `r-testthat`.

Reihenfolge, beim ersten Fehler stoppen, beheben, bei 1 neu beginnen:
1. `Rscript -e 'devtools::document()'`
2. `Rscript -e 'devtools::test(reporter = "check")'`
3. `Rscript -e 'devtools::load_all(); res <- check_all_solutions(verbose = FALSE); print(res[!res$solution_ok | isFALSE(res$starter_fails), ])'` – muss leer sein.
4. `Rscript -e 'devtools::check(error_on = "warning")'`
5. Optional: `lintr::lint_package()`, `styler::style_pkg()`.

## Regeln
- Gekürzte echte Ausgabe zeigen (Fehlerzeilen, nicht das ganze Log).
- Fehler: Ursache benennen, minimal fixen, Regressionstest ergänzen.
- Aufgaben > 5 s: klären, ob `run_code()` oder die Aufgabe langsam ist.
- Ist R nicht ausführbar, das ausdrücklich melden.
