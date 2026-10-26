# STATUS

Stand (2026-10-26): **Neuausrichtung beschlossen.** rtrainer wird vom Shiny-R-Paket zu einem zweisprachigen R-Kurs als Quarto-Website mit quarto-live/webR (Details: docs/SPEC.md, Entscheidungen aus der Grilling-Sitzung vom 2026-10-26). Code ist noch der alte Paketstand; der Umbau beginnt mit Meilenstein 6.

## Gesichert
- Tag `v0-shiny` (lokal, noch nicht gepusht): letzter Stand der Shiny-App, Meilensteine 1-5 abgeschlossen, 65 Aufgaben in `inst/exercises/`, Datensatz `inst/extdata/driving_sim.csv` (+ `data-raw/driving_sim.R`).
- Letzter Stand dort: `devtools::test()` `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 727 ]`, `check_all_solutions()` 65/65, `R CMD check` OK; GitHub Actions (R-CMD-check, Run 40260900315) grün auf ubuntu/macOS/Windows.
- Repo `NikHenProj/rtrainer` öffentlich, `main` gepusht.

## Umgebung
- Quarto 1.10.19, R 4.6.1 lokal; quarto-live noch nicht installiert (`quarto add r-wasm/quarto-live`).
- gh angemeldet (NikHenProj, Scopes repo/workflow).
- Chromium für Browser-Tests: `~/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome` (`CHROMOTE_CHROME` in `~/.Renviron`).
- webR-Index 4.6 geprüft (2026-10-26): alle Kernpakete verfügbar; nicht ladbar: brms, rstanarm, BayesFactor, ggstatsplot, apaTables, DHARMa.

## Als Nächstes: Meilenstein 6
Grundgerüst + Prototyp „Gruppenvergleiche – Beginner“ (DE), siehe SPEC.md Abschnitt „Meilensteine“:
1. R-Paket-Dateien entfernen (R/, man/, tests/, DESCRIPTION, NAMESPACE, vignettes/, inst/ → Aufgaben und Daten vorher nach `legacy/` bzw. `data-raw/` verschieben, damit die Triage in M8 sie findet), README neu.
2. Quarto-Projekt mit quarto-live, Theme (Plex/JetBrains Mono, Indigo, Hell/Dunkel), Kopfzeile, Kursplan-Matrix, Lektionslayout (Breadcrumb, Abschnitt x von 7, Zurück/Weiter).
3. YAML-Übungsformat finalisieren, `tools/generate.R`, `tools/checks.R`, `tools/selftest.R` (+ Tests).
4. Fahrsimulator-Datensatz mit englischen Spaltennamen; Lektion `group-comparisons-beginner` mit 3 Übungen + Wissenscheck; Fortschritt in localStorage.
5. CI: Selbsttest + Render + Deploy auf GitHub Pages (alten R-CMD-check-Workflow ersetzen).
6. Nick nimmt Optik und Aufbau im Browser ab, erst dann M7.

## Offene Punkte
- Skills `rtrainer-write-exercise`/`rtrainer-verify` und Agent `rtrainer-verifier` beschreiben das neue Vorgehen, die Befehle (tools/*.R) entstehen aber erst in M6.
- Alte 65 Aufgaben: Triage in M8 (gute einsortieren, schwache streichen, Liste zur Freigabe).
