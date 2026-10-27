# STATUS

Stand (2026-10-27): **M9 Paket P9b (EN: reporting-, reproducibility-, programming- und project-intermediate) committet, Abnahme durch Nick offen, nicht gepusht.** Davor: **M9 Paket P9a (EN: Intermediate P4–P5, 6 Lektionen) abgenommen und in `main`.** Davor: **M9 Paket P8 (EN: Intermediate P1–P3, 9 Lektionen) abgenommen und in `main`.** Davor: **M9 Paket P7 (DE: project-intermediate) abgenommen und in `main`.** Davor: **M9 Paket P6 (DE: reporting-, reproducibility-, programming-intermediate) abgenommen und in `main`.** Davor: **M9 Paket P5 (DE: mixed-models-, moderation-mediation-, power-intermediate) abgenommen und in `main`.** **M6 bis M8 Teil 5 und M9 Paket P1 (DE: import-, cleaning-, reshaping-intermediate) abgenommen und in `main` und M9 Paket P2 (DE: missing-, visualisation-, descriptives-intermediate) abgenommen und in `main`; M9 Paket P3 (DE: scales-, sem-, group-comparisons-intermediate) und Datensatz `acceptance` abgenommen und in `main`; M9 Paket P4 (DE: robust-, regression-, glm-intermediate) abgenommen und in `main`** (alle 10 Beginner-Lektionen und Mini-Projekt Beginner, DE + EN). **Online seit 2026-10-26:** https://nikhenproj.github.io/rtrainer/ (Pages-Quelle GitHub Actions, letzter CI-Lauf 40575147997 grün). M9-Plan abgenommen (inkl. Datensatz `acceptance`): `docs/M9-plan.md`. Entscheidungen: NEWS.md.

## Was steht
- **Gerüst (M6):** Quarto-Website mit quarto-live/webR, Theme hell/dunkel (IBM Plex Sans, JetBrains Mono, Indigo), Kopfzeile Kursplan · Wiederholen (n fällig) · Pakete · Glossar · DE/EN · Hell/Dunkel · Suche.
- **Kursplan** (`de/index.qmd`, `en/index.qmd`): Matrix 23 Themen × 3 Stufen, Status je Zelle, „Weitermachen mit / Als Nächstes“, „Heute wiederholen (n)“.
- **Lektionen:** `working-with-r-beginner`, `import-beginner`, `cleaning-beginner`, `reshaping-beginner`, `visualisation-beginner`, `descriptives-beginner`, `scales-beginner`, `regression-beginner`, `reporting-beginner` (33 Pflicht- + 13 Zusatzübungen, je 5 Fragen Wissenscheck). Alle in DE und EN (keine `langs`-Einschränkung mehr). Aufbau: Breadcrumb, Lektionskasten mit Fortschritt, links „Abschnitt x von 7“ (ab 1200 px), rechts Inhaltsverzeichnis, 3 Pflichtübungen (YAML), Wissenscheck (5 Fragen, ≥ 80 %), Spickzettel, Zurück/Weiter.
- **Intermediate P1 (DE + EN):** `import-intermediate` (viele Dateien mit `read_csv(files, id)`, `possibly()`/`safely()`, SPSS-Labels mit haven, Excel-Datum/Text gemischt), `cleaning-intermediate` (`separate_wider_delim/regex`, verankerte Regex mit `str_match()`, `difftime`-Einheiten, forcats + `tabyl()`), `reshaping-intermediate` (Fensterfunktionen, abgesicherte Joins mit `relationship`/`unmatched`, `reduce()`). Je 3 Pflicht + 1 Zusatz, je 5 Fragen. Übungen mit Dateien schreiben sie im `setup` nach `tempdir()`.
- **Intermediate P2 (nur DE, abgenommen):** `missing-intermediate` (naniar pro Variable/Fall, `complete()` für implizit fehlende Zeilen, gezieltes `drop_na()`, mice als Ausblick mit `pool()`), `visualisation-intermediate` (KI aus Personenmitteln mit `position_dodge()`, `estimate_relation()` mit Band, patchwork, Themes, `ggsave()` in Zielgröße), `descriptives-intermediate` (`across()` mit Funktionsliste, Skalenwert mit Mindestzahl Items, Tabelle M (SD) lang → breit, Tabelle mit d deuten). 3 Pflicht + 1–2 Zusatz, je 5 Fragen. Plot-Check vergleicht patchwork-Kombinationen (Teilplots + Layout).
- **Intermediate P3 (nur DE, abgenommen):** `scales-intermediate` (α und ω mit `psych::reliability()`, Itemanalyse, Parallelanalyse + EFA oblimin, Umpolen auf 1–7), `sem-intermediate` (CFA mit lavaan, Fit deuten, standardisierte Ladungen, `lavTestLRT()`, ω mit `semTools::compRelSEM()`, SEM-Ausblick), `group-comparisons-intermediate` (afex `aov_ez()` gemischt, η²G, GG, emmeans/modelbased + Holm, gepaarter Vergleich, Voraussetzungen am Modell). 3 Pflicht + 1–2 Zusatz, je 5 Fragen. Check für Modelle (lavaan, afex, merMod) über `parameters::model_parameters()`.
- **Intermediate P4 (nur DE, abgenommen):** `robust-intermediate` (Rangtests mit rstatix inkl. Friedman auf vollständigen Personen, r / Rang-biserial / Kendalls W, Hodges-Lehmann; getrimmte Mittel mit WRS2 `yuen()`), `regression-intermediate` (`acceptance`: multiple Regression, standardisiert, hierarchisch mit `anova(m1, m2)`, Interaktion Nützlichkeit × Erfahrung zentriert + einfache Steigungen, Diagnostik mit performance), `glm-intermediate` (`usability`: logistisch mit Odds Ratios, marginaleffects `avg_predictions()`/`avg_comparisons()` cluster-robust nach Person, Poisson mit Rate Ratios, Überdispersion/quasipoisson). 3 Pflicht + 1–2 Zusatz, je 5 Fragen. `usability` reichte für glm (`success`, `errors`), keine neue Spalte.
- **Intermediate P5 (nur DE, abgenommen):** `mixed-models-intermediate` (Zufallsintercept vs. `lm()`, lmerTest/Satterthwaite, Durchgang zentriert × Modalität, Random Slope + Shrinkage, gekreuzt Person × Aufgabe mit `icc(by_group = TRUE)`, Residuen mit `na.exclude`; glmmTMB nur „Lokal ausführen“, lädt in webR nicht), `moderation-mediation-intermediate` (Johnson-Neyman mit interactions, Mediation mit lavaan-Labels und `:=`, Bootstrap im Beispiel; `mediation`-Paket nur im Paketvergleich), `power-intermediate` (pwr a priori/Sensitivität, d_z, Superpower mit `r`, simr `powerSim()`/`extend()`, beobachtete Power). Je 3 Pflicht + 2 Zusatz, je 5 Fragen.
- **Intermediate P6 (nur DE, abgenommen):** `reporting-intermediate` (modelsummary mit KI und `gof_map`, geschachtelte Modelle auf derselben Stichprobe, APA-Tabelle aus `model_parameters()` mit `rempsyc::nice_table()`, Inline-Zahlen; Word-Export nur „Lokal ausführen“, officer stürzt in webR ab), `reproducibility-intermediate` (Projektstruktur, here mit `i_am()` im webR-Dateisystem, `renv::dependencies()` vorhersagen, `renv.lock` mit jsonlite lesen, `set.seed()`; renv/git/Quarto-Parameter als „Lokal ausführen“), `programming-intermediate` (`{{ }}`, `map2()`, ein Modell pro Person mit `nest()` + `model_parameters()`, `...`, `tryCatch()`/`possibly()`). 3 Pflicht + 1 bzw. 2 Zusatz, je 5 Fragen.
- **Intermediate EN P9b (Abnahme offen):** `en/{reporting,reproducibility,programming,project}-intermediate.qmd`, `langs` entfernt (keine `langs`-Einschränkung mehr im Kurs); EN-Texte mit „N%“ (20 Zeilen, nur `en:`-Blöcke). Damit alle 18 Intermediate-Lektionen und beide Mini-Projekte zweisprachig. Achsentitel im EN-Gesamtskript englisch; die gemeinsame Lösung von `pj-i-figure` behält das deutsche Label (Plot-Check vergleicht keine Beschriftungen).
- **Intermediate EN P9a (abgenommen):** `en/{robust,regression,glm,mixed-models,moderation-mediation,power}-intermediate.qmd`, `langs` entfernt; EN-Texte dieser Lektionen mit „N%“ statt „N %“ (72 Zeilen, nur `en:`-Blöcke). Damit 15 von 18 Intermediate-Lektionen zweisprachig; reporting, reproducibility, programming und project-intermediate weiter nur DE (P9b).
- **Intermediate EN (P8, abgenommen):** `en/{import,cleaning,reshaping,missing,visualisation,descriptives,scales,sem,group-comparisons}-intermediate.qmd`, übersetzt mit gleichem Code, gleichen Daten und Übungs-IDs; `langs` entfernt. P4–P7 (robust bis project-intermediate) weiter nur DE. Fix: 12 DE-Intermediate-Seiten (P3–P6) hatten kein `footer.qmd`-Include (keine Zurück/Weiter-Leiste); ergänzt.
- **Mini-Projekt Intermediate (nur DE, P7, abgenommen):** `project-intermediate` (Zeile „Mini-Projekt“ jetzt mit Stufen beginner + intermediate; Voraussetzungen reporting- und mixed-models-intermediate). Zwei getrennte Quellen: Remote-Befragung zur aktuellen App aus `raw_export_xlsx` (Ausgangslage) und Labortest `usability` (Entscheidung). Auftrag mit Analyseplan → 7 Schritte mit je einer Pflichtübung (Excel-Export einlesen, Bereinigen nach Plan (debug), Zeitmodell `log(time_s) ~ prototype + position + (1 | participant) + (1 | task)` auf gelösten Aufgaben, emmeans-Kontraste als Zeitverhältnis mit Holm, Abbildung der Vergleiche, Kennwertetabelle, Ergebnisse deuten) + Zusatz `pj-i-success` (glmer) → Gesamtskript (live) → „Lokal ausführen“ (Quarto → docx) → Wissenscheck (5) → Checkliste.
- **Mini-Projekt Beginner (DE + EN):** `project-beginner`, eigene Zeile „Mini-Projekt“ unter den 23 Themen (`kind: project` in curriculum.yml), Pfad nach reporting-beginner. Auftrag mit Analyseplan → 5 Schritte mit je einer Pflichtübung (Import, Ausschluss, Skalen, Welch-t-Test, Tabelle 1, Ergebnisse deuten; 6 Pflicht + 1 Zusatz `pj-b-tlx-subscales`) → Gesamtskript (live) + „Lokal ausführen“ (Quarto → docx) → Wissenscheck (5) → Checkliste. Generator schreibt zusätzlich `exercise-<id>.qmd` je Übung; Check-Option `check_types`; Wiederholungskarten rendern Tabellen/Listen/Zitate.
- **Wiederholung** (`review.qmd`): Leitner Boxen 1–5 (0/1/3/7/21 Tage), Sicherheits-Rating vor dem Prüfen, Leicht/Okay/Schwer, Serie, Mischen nach Lektionen; R lädt erst beim Start. Export/Import des Fortschritts (`#backup`).
- **Pakete und Glossar** aus YAML (`content/packages/*.yml`, `content/glossary.yml`), Vorlagen für weitere Einträge.
- **Sprachen:** `/de/` und `/en/`; Umschalter führt zur gleichen Seite und zum gleichen Abschnitt; Fortschritt sprachübergreifend.
- **Werkzeuge:** `tools/generate.R` (pre-render; `langs` in lesson.yml), `tools/checks.R` (value/object/output/plot; plot: Ebenen, aes, Settings, Position, Ebenendaten, Facets, Skalen; gtsummary-Tabellen nach Inhalt; Neuauswertung bei falschem `last_value`), `tools/selftest.R`, Tests `tools/tests/` (R) und `tests/js/` (Node), Browser-Rauchtest `tests/smoke-test.R`.
- **CI** `.github/workflows/site.yaml`: Selbsttest, R- und Node-Tests, Render, Rauchtest, Pages-Deploy auf `main`.
- **Daten (M8.1):** `driving_sim`, `survey` (Fragebogen: SUS, NASA-TLX, Vertrauen mit umgepolten Items, fehlende Werte, Aufmerksamkeitsfrage), `usability` (24 × 3 Prototypen × 4 Aufgaben, Lateinisches Quadrat, Timeout 180 s, p07 ohne C), `raw_export` (.csv mit `;`/Dezimalkomma) + `raw_export_xlsx` (gleiche Antworten, Titel-/Summenzeilen, gemischte Datumsformate, Codebook). Skripte in `data-raw/`, Einträge in `data/datasets.yml`, Tests `tools/tests/test-datasets.R`. Neu (vor P3): `acceptance` (TAM-Fragebogen, n = 300, 4 Skalen 1–7, `peou_3`/`trust_4` umgepolt, schwaches Item `pu_5`, Erfahrung, Alter).
- **Triage** `docs/legacy-triage.md`: 54 behalten (18 im Beginner-Pfad), 11 streichen, freigegeben. Migriert: 41 (markiert): alle Beginner-Aufgaben der Triage, P1 (10, 13, 18, 23, 24, 26), P2 (5, 14, 15, 48, 52), P3 (30, 31, 36, 37, 38), P4 (35), P5 (40–43, 45, 46; 44 bleibt für mixed-models-expert) und P6 (53, 54, 19, 21, 25, 28, 29; 4 als `rr-i-lockfile`, 20 als Wissenscheck-Frage). Stand: 50 von 54 (offen: 22, 27, 39, 44 für Expert).
- Alt: `legacy/exercises/` (65 Aufgaben), `legacy/driving_sim_v0.*`.

## Geprüft (2026-10-27, M9 P9b)
EN-Texte der 4 Lektionen (Übungen + Wissenscheck) per Skript geprüft (fehlendes `en`, Umlaute, deutsche Anführungszeichen, Dezimalkomma, deutsche Wörter, „N %“): nichts fehlt, 20 Zeilen „N %“ → „N%“.
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 595 files, 144 exercises. `Rscript tools/selftest.R`: 144/144 exercises ok
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 16 | SKIP 0 | PASS 243; `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, [69/69], keine Warnungen; 4 neue `_site/en/*-intermediate.html`, alle mit `rt-pager`
- `Rscript tests/smoke-test.R`: 0 failure(s); „en: all 18 intermediate lessons linked in course plan“, „en: project row links the English intermediate project“ ok; project-intermediate bereit nach 23,8 s
- Nicht geprüft: EN-Seiten nicht manuell durchgeklickt; EN-Übungen nicht im Browser bewertet (gleiche IDs/Checks wie DE); EN-Texte nur per Skript geprüft; nicht gepusht, CI nicht gelaufen.

## Online (2026-10-27, M9 P9a)
- Gepusht (682de00, 9c6baf2). CI-Lauf 40575147997 grün (build 13,1 min, deploy ok): 144/144, `[ FAIL 0 | WARN 16 | SKIP 0 | PASS 243 ]`, Node 12/0, Rauchtest 0 failure(s); „en: intermediate P1-P5 lessons linked in course plan“ (15 Slugs) und „en: German-only reporting-intermediate not linked“ ok.
- Ladezeit im CI-Rauchtest: project-intermediate 22,7 s.

## Geprüft (2026-10-27, M9 P9a)
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 554 files, 144 exercises. `Rscript tools/selftest.R`: 144/144 exercises ok
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 16 | SKIP 0 | PASS 243; `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, [65/65], keine Warnungen; 6 neue `_site/en/*-intermediate.html`, keine `en/reporting-intermediate.html`
- `Rscript tests/smoke-test.R`: 0 failure(s); „en: intermediate P1-P5 lessons linked in course plan“ (15 Slugs), „en: German-only reporting-intermediate not linked“ ok
- Umgebung: Selbsttest und R-Tests waren zunächst rot, weil eine knitr-Installation (27.10., 20:10, nicht aus dieser Sitzung) abgebrochen war (leerer Ordner + `00LOCK-knitr`) und `~/.Renviron` fehlte. Nach Rückfrage: Sperrordner entfernt, knitr 1.52 neu installiert, `~/.Renviron` mit `CHROMOTE_CHROME` neu angelegt; danach grün. Ein alter, unabhängiger Rest `00LOCK-arrow` (25.07.) liegt noch in der Bibliothek; arrow wird im Kurs nicht genutzt, nicht angefasst.
- Nicht geprüft: EN-Seiten nicht manuell durchgeklickt; EN-Übungen nicht im Browser bewertet (gleiche IDs/Checks wie DE); EN-Texte nur per Skript geprüft. CI siehe oben.

## Online (2026-10-27, M9 P8)
- Gepusht (ce3a2ad, 7f7efd9). CI-Lauf 40568702740 grün (build 11,9 min, deploy ok): 144/144, `[ FAIL 0 | WARN 16 | SKIP 0 | PASS 243 ]`, Node 12/0, Rauchtest 0 failure(s); alle 9 „en:“-Schritte ok, inkl. Intermediate-Links im EN-Kursplan und EN-Seite group-comparisons-intermediate mit Übung und Zurück/Weiter.
- Ladezeit im CI-Rauchtest: project-intermediate 21,2 s.

## Geprüft (2026-10-27, M9 P8)
EN-Texte der 9 Lektionen (Übungen + Wissenscheck) per Skript geprüft (fehlendes `en`, Umlaute, deutsche Anführungszeichen, Dezimalkomma, deutsche Wörter, „N %“): nichts fehlt, 4 Prozentangaben auf „14%“ vereinheitlicht. In glm/mixed-models/power-Texten steht noch „80 %“ (bei deren Übersetzung korrigieren).
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 496 files, 144 exercises. `Rscript tools/selftest.R`: 144/144 exercises ok
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 16 | SKIP 0 | PASS 243; `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, [59/59], keine Warnungen; alle 9 `_site/en/*-intermediate.html` vorhanden, keine `en/robust-intermediate.html`; `_site/de/sem-intermediate.html` enthält `rt-pager`
- `Rscript tests/smoke-test.R`: erster Lauf 1 failure (eigener Testfehler: EN-Projektzeile auf der falschen Seite geprüft, Schritte umsortiert), zweiter Lauf 0 failure(s); neu: „en: intermediate P1-P3 lessons linked in course plan“, „en: German-only robust-intermediate not linked“, „en: intermediate page in English with exercise and pager“ ok; project-intermediate bereit nach 25,3 s
- Nicht geprüft: EN-Seiten nicht manuell durchgeklickt (SVG-Beschriftungen auf Überlänge, Wissenscheck, Beispielblöcke nicht in webR ausgeführt; Code ist identisch zu DE); EN-Übungen nicht im Browser bewertet (gleiche IDs/Checks wie DE); EN-Texte nur per Skript, nicht vollständig gelesen. CI siehe oben.

## Online (2026-10-27, M9 P7)
- Gepusht (852d386, 8753f65). CI-Lauf 40533051262 grün (build 11,4 min, deploy ok): 144/144, `[ FAIL 0 | WARN 16 | SKIP 0 | PASS 243 ]`, Node 12/0, Rauchtest 0 failure(s).
- Ladezeit im CI-Rauchtest (headless, Runner): project-intermediate 21,7 s; Excel-Export, Kontraste (Hinweis + Lösung) und Abbildung je ≤ 1 s bis zur Bewertung.

## Geprüft (2026-10-27, M9 P7)
Vorab Ladezeit in webR (headless, eine Messung): webR 1,3 s, readxl/janitor/dplyr 3,8 s, lme4/lmerTest/emmeans/parameters/ggplot2 3,7 s, Excel lesen 3,2 s, `lmer()` + Kontraste 5,9 s, `glmer()` 1,7 s (gesamt ~20 s). glmer-Werte weichen in webR in der 2. Nachkommastelle ab → `pj-i-success` mit `tolerance: 0.02`.
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 412 files, 144 exercises. `Rscript tools/selftest.R`: 144/144 exercises ok
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 16 | SKIP 0 | PASS 243 (unverändert); `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, [50/50], keine Warnungen; `_site/de/project-intermediate.html` vorhanden, keine EN-Seite
- `Rscript tests/smoke-test.R`: 0 failure(s); neu Abschnitt 14: Projektzeile verlinkt project-intermediate, Seite bereit nach 25,8 s (lokal, eine Messung); Excel-Export, Kontraste (Hinweis ohne Holm, Lösung) und Abbildung in webR bewertet
- Nicht geprüft: Seite nicht manuell durchgeklickt (SVG-Abbildung, Wissenscheck, Gesamtskript nur lokal in R, nicht in webR ausgeführt; `pj-i-clean`, `pj-i-model`, `pj-i-table`, `pj-i-success` nur im Selbsttest, nicht in webR bewertet); CI siehe oben.

## Online (2026-10-27, M9 P6)
- Gepusht (4e56892, 56e1ad1). CI-Lauf 40526007218 grün (build 9,5 min, deploy ok): 136/136, `[ FAIL 0 | WARN 16 | SKIP 0 | PASS 243 ]`, Node 12/0, Rauchtest 0 failure(s).
- Ladezeit im CI-Rauchtest (headless, Runner): reporting-intermediate 14,1 s, reproducibility-intermediate 9,1 s, programming-intermediate 9,1 s; `pg-i-nest-models` bis zur Bewertung 12,6 s.

## Geprüft (2026-10-27, M9 P6)
Vorab Ladezeit in webR (headless, eine Messung): dplyr/tidyr/parameters 6,2 s, modelsummary 3,1 s, flextable 5,1 s, rempsyc 1,4 s; here/readr/jsonlite/purrr 5,2 s. `flextable::save_as_docx()` (officer) stürzt in webR ab (`memory access out of bounds`) → Word nur „Lokal ausführen“.
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 399 files, 136 exercises. `Rscript tools/selftest.R`: 136/136 exercises ok
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 16 | SKIP 0 | PASS 243 (vorher WARN 10; die 6 neuen sind „longer object length“-Warnungen aus dem Starter von `pg-i-map2-debug`, gewollt: der Starter recycelt die Grenzwerte); `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, [49/49], keine Warnungen; `_site/de/{reporting,reproducibility,programming}-intermediate.html` vorhanden, keine EN-Seiten
- `Rscript tests/smoke-test.R`: 0 failure(s); neu Abschnitt 13: reporting-intermediate bereit nach 17,7 s, reproducibility-intermediate 12,1 s, programming-intermediate 11,7 s (lokal, eine Messung); modelsummary (Hinweis bei unbenannten Modellen, Lösung), rempsyc-Objekt `tab`, here-Pfade, Lockfile, `map()` mit Zusatzvektor (Hinweis) in webR bewertet; `pg-i-nest-models` bis zur Bewertung 15,7 s
- Nicht geprüft: Lektionen nicht manuell durchgeklickt (SVG-Abbildungen, Wissenscheck, Beispielblöcke nur lokal in R, nicht in webR, v. a. `nice_table()`-Ausgabe als flextable im Browser, `setwd()` im Beispiel der reproducibility-Seite); nicht gepusht, CI nicht gelaufen.

## Online (2026-10-27, M9 P5)
- Gepusht (7d74098, ca8080d). CI-Lauf 40429331075 grün (build 10,5 min, deploy ok): 123/123, `[ FAIL 0 | WARN 10 | SKIP 0 | PASS 243 ]`, Node 12/0, Rauchtest 0 failure(s).
- Ladezeit im CI-Rauchtest (headless, Runner): mixed-models-intermediate 15,6 s, moderation-mediation-intermediate 18,1 s, power-intermediate 19,6 s; `powerSim()`-Übung bis zur Bewertung 27,2 s.
- Build dauert jetzt 10,5 statt 6 min (neue Pakete; der Rauchtest wird länger).

## Geprüft (2026-10-27, M9 P5)
Vorab Ladezeit in webR (headless, eine Messung): lme4/lmerTest/performance/parameters 12–18 s, simr danach 5,5 s, pwr + Superpower 2–16 s; `powerSim()` mit 50 Läufen 14,7 s, lavaan-Bootstrap mit 200 Ziehungen 21,8 s. glmmTMB lädt nicht (TMB 1.9.11 im webR-Repo, glmmTMB braucht ≥ 1.9.23).
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 371 files, 123 exercises. `Rscript tools/selftest.R`: 123/123 exercises ok (Warnungen wie bisher)
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 10 | SKIP 0 | PASS 243 (vorher WARN 8; die Warnungen kommen aus test-selftest.R:27, das den Selbsttest laufen lässt; wohl die ggplot2-Hinweise aus Superpower, nicht einzeln geprüft); `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, 0 Warnungen; `_site/de/{mixed-models,moderation-mediation,power}-intermediate.html` vorhanden, keine EN-Seiten
- `Rscript tests/smoke-test.R`: 0 failure(s); neu Abschnitt 12: mixed-models-intermediate bereit nach 18,7 s, moderation-mediation-intermediate 17,2 s, power-intermediate 21,2 s (lokal, eine Messung); Hinweis bei geschachteltem `participant/task`, gekreuzte Lösung, Johnson-Neyman, lavaan-Mediation, Superpower (Hinweis ohne `r`, Lösung) in webR bewertet; `powerSim()`-Übung bis zur Bewertung 32,9 s
- Nicht geprüft: Lektionen nicht manuell durchgeklickt (SVG-Abbildungen, Wissenscheck, Beispielblöcke nur lokal in R, nicht in webR, v. a. Bootstrap-Block, `johnson_neyman()`-Plot, `mediation`-Code nur statisch); nicht gepusht, CI nicht gelaufen.

## Online (2026-10-27, M9 P4)
- Gepusht (ba2a5ad, 103c4d5). Erster CI-Lauf 40369342263 rot: 107/108, `rb-i-mann-whitney` brauchte coin für `rstatix::wilcox_effsize()` (lokal installiert, in CI und Browser nicht). Fix 736afb2: coin in Lektion, Übung, Seite und Workflow, vor rstatix geladen (coin hat eigenes `wilcox_test()`); Rauchtest bewertet die Übung jetzt in webR.
- CI-Lauf 40424325670 grün (build 6,1 min, deploy ok): 108/108, `[ FAIL 0 | WARN 8 | SKIP 0 | PASS 243 ]`, Node 12/0, Rauchtest 0 failure(s).
- Ladezeit im CI-Rauchtest (headless, Runner): robust-intermediate (mit coin) 12,6 s, regression-intermediate 6,5 s, glm-intermediate 7,5 s.

## Geprüft (2026-10-26, M9 P4)
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 341 files, 108 exercises. `Rscript tools/selftest.R`: 108/108 exercises ok (Warnungen erwartet wie bisher, keine aus P4)
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 8 | SKIP 0 | PASS 243; `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, 0 Warnungen; `_site/de/{robust,regression,glm}-intermediate.html` vorhanden, keine EN-Seiten
- `Rscript tests/smoke-test.R`: 0 failure(s); neu Abschnitt 11: robust-intermediate (rstatix, effectsize, WRS2) bereit nach 20,8 s, regression-intermediate (modelbased) 13,1 s, glm-intermediate (marginaleffects, sandwich) 15,2 s (lokal, eine Messung); Yuen-Lösung, zentrierte Interaktion, `avg_comparisons()` (Hinweis ohne `vcov`, Lösung) in webR bewertet
- Nicht geprüft: Lektionen nicht manuell durchgeklickt (SVG-Abbildungen, Wissenscheck; Beispielblöcke nur lokal in R, nicht in webR, v. a. `rank_biserial()`, `estimate_slopes()`, `avg_comparisons(vcov = ~participant)` im Beispiel); Zahlen in Texten aus lokalen Paketversionen (webR: parameters 0.28, marginaleffects 0.32), Abweichungen in der letzten Stelle möglich; nicht gepusht, CI nicht gelaufen.

## Online (2026-10-26, M9 P3)
- Gepusht (692fa09, CI-Fix 25686f4: alle Übungspakete ausdrücklich im Workflow, erster Lauf scheiterte an fehlendem `afex`). CI-Lauf 40361912320 grün (build 6,5 min, deploy ok): 95/95, `[ FAIL 0 | WARN 8 | SKIP 0 | PASS 243 ]`, Node 12/0, Rauchtest 0 failure(s).
- Ladezeit im CI-Rauchtest (headless, Runner): scales-intermediate 10,1 s, sem-intermediate 9,6 s, group-comparisons-intermediate 18,1 s, missing 16,6 s.

## Geprüft (2026-10-26, M9 P3)
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 313 files, 95 exercises. `Rscript tools/selftest.R`: 95/95 exercises ok (längste 0,92 s; Warnungen erwartet wie bisher)
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 8 | SKIP 0 | PASS 243; `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, 0 Warnungen; `_site/de/{scales,sem,group-comparisons}-intermediate.html` vorhanden, keine EN-Seiten
- `Rscript tests/smoke-test.R`: 0 failure(s); neu Abschnitt 10: scales-intermediate bereit nach 12,7 s, sem-intermediate (lavaan, semTools) 12,2 s, group-comparisons-intermediate (afex, emmeans, modelbased) 23,8 s (lokal, eine Messung); EFA-Lösung, lavaan-Modell (Hinweis bei fehlendem Faktor, Lösung), afex-ANOVA (Hinweis ohne `na.rm`, Lösung) in webR bewertet
- Erster Lauf hatte 2 Fehler, behoben: `reliability()` von semTools maskiert (jetzt `psych::reliability()`), EFA-Faktornummern wechseln in webR (Übung vergleicht jetzt Item + Ladung)
- Nicht geprüft: Lektionen nicht manuell durchgeklickt (SVG-Abbildungen, Wissenscheck, Beispielblöcke nur lokal in R, nicht in webR; v. a. `psych::reliability()`, `fa.parallel()`, `sem()` im Browser); Online-Ladezeit afex noch nicht gemessen.

## Geprüft (2026-10-26, M9 P2)
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 284 files, 81 exercises. `Rscript tools/selftest.R`: 81/81 exercises ok (Warnungen erwartet wie bisher)
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 8 | SKIP 0 | PASS 220; `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, 0 Warnungen; `_site/de/{missing,visualisation,descriptives}-intermediate.html` vorhanden
- `Rscript tests/smoke-test.R`: 0 failure(s); neu Abschnitt 9: missing (webR + mice, naniar) bereit nach 23,3 s, visualisation-intermediate (modelbased, patchwork) nach 12,7 s (lokal, eine Messung); naniar-Lösung, `ggsave()`-PNG-Größe, modelbased-Plot, patchwork (Hinweis bei `/`, Lösung) in webR ok
- Nicht geprüft: descriptives-intermediate nicht im Rauchtest (nur Render + Selbsttest); Lektionen nicht manuell durchgeklickt (SVG-Abbildungen, Wissenscheck, Beispielblöcke nur lokal in R ausgeführt, nicht in webR; mice-Beispiel mit m = 10 im Browser nicht gemessen).

## Geprüft (2026-10-26, M9 P1)
Über Verifier-Subagent (echte Ausgabe, gekürzt):
- `Rscript tools/generate.R`: Generated 256 files, 68 exercises. `Rscript tools/selftest.R`: 68/68 exercises ok (Warnungen erwartet: Datumsformate in Startern, psych, many-to-many im Starter von rs-i-join-duplicates)
- `testthat::test_dir("tools/tests")`: FAIL 0 | WARN 8 | SKIP 0 | PASS 213; `node --test tests/js`: 12 pass, 0 fail
- `quarto render`: Exit 0, 0 Warnungen; `_site/de/*-intermediate.html` (3) vorhanden, keine EN-Seiten
- `Rscript tests/smoke-test.R`: 0 failure(s); neu Abschnitt 8: import-intermediate im Kursplan verlinkt, webR + 8 Pakete 17,2 s, `possibly()` über CSV-Dateien ok, geratene SPSS-Labels bekommen den Hinweis, haven-Lösung ok
- Nicht geprüft: Lektionen nicht manuell im Browser durchgeklickt (Optik der drei SVG-Abbildungen, Wissenscheck, Beispielblöcke nur lokal in R ausgeführt, nicht in webR).

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
1. Abnahme M9 P9b durch Nick; danach nach Rückfrage pushen, CI-Ergebnis eintragen.
2. M9 damit inhaltlich komplett; danach M10 (Expert-Stufe, SPEC.md Abschnitt Meilensteine) planen, analog `docs/M9-plan.md`.

## Umgebung
- Quarto 1.10.19, R 4.6.1, Node 18, quarto-live 0.1.3-dev (`_extensions/r-wasm/live`, webR 0.6.0).
- gh angemeldet (NikHenProj, Scopes repo/workflow).
- Chromium: `~/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome` (`CHROMOTE_CHROME` in `~/.Renviron`).
- Lokale Vorschau der gebauten Seite: `.claude/launch.json` „site“ (python http.server auf `_site`, Port 4321); alternativ `quarto preview`.
- Hinweis Browser-Tests: quarto-live rendert Editoren nur, wenn die Seite sichtbar ist (im versteckten Tab bleiben sie leer); headless Chrome ist unproblematisch.
