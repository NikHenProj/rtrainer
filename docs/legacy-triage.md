# Triage der 65 alten Aufgaben (freigegeben)

Stand 2026-10-26. Quelle: `legacy/exercises/` (Tag `v0-shiny`). Migriert: 24 von 54 (markiert).

**Freigegeben von Nick am 2026-10-26: 54 behalten, 11 streichen.** 18 der behaltenen gehören in den Beginner-Pfad (M8), markiert mit **B**.

## Gilt für jede behaltene Aufgabe
- Neues Schema (`exercises/<slug>/<level>/`): `lesson`, `order`, `required`, Texte DE + EN, gestufte Hinweise, `common_mistakes` mit Begründung.
- Daten auf den neuen Stand bringen: `vp_id` → `participant`, Stufen englisch (`visuell/auditiv/haptisch` → `visual/auditory/haptic`, `m/w/d` → `male/female/diverse`). `age_group` gibt es in `driving_sim` nicht mehr; im Setup aus `age` bilden oder `experience` nehmen.
- Werkzeug laut Paket-Standard: easystats/rstatix/afex/emmeans statt Handrechnung aus `summary()`-Tabellen. Statistik-Aufgaben bekommen Effektgröße, KI und einen APA-Satz in der Erklärung.
- Plot-Aufgaben brauchen den Check-Typ `plot`. Den gibt es noch nicht (`tools/checks.R` kennt value/object/output), er ist laut SPEC für später vorgesehen.
- Mixed-Model-Aufgaben: vor der Migration prüfen, ob `lme4`/`lmerTest` im webR-Index laufen; sonst „Lokal ausführen“.

## Behalten

| # | Alte Aufgabe | Art | Neue Lektion | Anpassung |
|---|---|---|---|---|
| 1 | 01-basics/factor-numeric | debug | import-beginner **B** | Kontext: Zahl wurde beim Einlesen zum Faktor; `readr::parse_number()` als Alternative nennen. | **Migriert (M8.2a).**
| 2 | 01-basics/factor-relevel | write | cleaning-beginner **B** | `forcats::fct_relevel()` statt `factor(levels =)`; englische Stufen. | **Migriert (M8.2a).**
| 3 | 01-basics/na-index | predict | working-with-r-beginner **B** | Unverändert; in der Erklärung auf `filter()` verweisen (lässt `NA` weg). | **Migriert (M8.2a).**
| 4 | 01-basics/nested-list | write | programming-intermediate | Kontext: Modell- oder JSON-Objekt statt einer erfundenen `studie`-Liste. |
| 5 | 02-dplyr/across | write | descriptives-intermediate | Mit `survey` (mehrere Skalen auf einmal) statt `driving_sim`. |
| 6 | 02-dplyr/case-when | write | cleaning-beginner **B** | Stufen englisch (`fast/medium/slow`), Ergebnis als geordneter Faktor. | **Migriert (M8.2a).**
| 7 | 02-dplyr/count-units | write | descriptives-beginner **B** | Unverändert (Person statt Zeile zählen); gut für Tabelle 1. | **Migriert (M8.2b).**
| 8 | 02-dplyr/filter-select | write | cleaning-beginner **B** | Englische Stufen. | **Migriert (M8.2a).**
| 9 | 02-dplyr/join | write | reshaping-beginner **B** | `anti_join()` zur Kontrolle der nicht verknüpften Personen ergänzen. | **Migriert (M8.2b).**
| 10 | 02-dplyr/lag-predict | predict | reshaping-intermediate | Unverändert. | **Migriert (M9 P1).**
| 11 | 02-dplyr/slice-max | write | cleaning-beginner **B** | Kontext: auffällige Durchgänge vor dem Bereinigen sichten. | **Migriert (M8.2a).**
| 12 | 02-dplyr/summarise-regroup | debug | descriptives-beginner **B** | Unverändert (Gruppierung nach `summarise()`, `.groups`). | **Migriert (M8.2b).**
| 13 | 02-dplyr/window-cumsum | write | reshaping-intermediate | Unverändert. | **Migriert (M9 P1).**
| 14 | 03-tidyr/complete-trials | complete | missing-intermediate | Implizit fehlende Zeilen; Bezug zu `naniar` herstellen. |
| 15 | 03-tidyr/drop-na-debug | debug | missing-intermediate | Unverändert. |
| 16 | 03-tidyr/pivot-longer-predict | predict | reshaping-beginner **B** | Englische Stufen. | **Migriert (M8.2b).**
| 17 | 03-tidyr/pivot-wider | write | reshaping-beginner **B** | Englische Stufen. | **Migriert (M8.2b).**
| 18 | 03-tidyr/separate-delim | write | cleaning-intermediate | Kontext Logging-Schlüssel bleibt; Stufen englisch. | **Migriert (M9 P1).**
| 19 | 04-purrr/map2-cutoff-debug | debug | programming-intermediate | Unverändert. |
| 20 | 04-purrr/map-extract-predict | predict | programming-intermediate | Unverändert. |
| 21 | 04-purrr/nest-map-models | write | programming-intermediate | Steigung mit `parameters::model_parameters()` holen statt `coef()[[...]]`. Ersetzt auch `03-tidyr/nest-models` (Streichliste Nr. 4). |
| 22 | 04-purrr/pmap-specs | complete | programming-expert | Rahmen: Sensitivitäts- oder Multiversum-Analyse. |
| 23 | 04-purrr/possibly-read | complete | import-intermediate | Erst `readr::read_csv(files, id = "file")` zeigen; `possibly()` nur für die fehlerhafte Datei. | **Migriert (M9 P1).**
| 24 | 04-purrr/reduce-join | write | reshaping-intermediate | Unverändert. | **Migriert (M9 P1).**
| 25 | 05-programming/dots-center | write | programming-intermediate | Unverändert (`...` weiterreichen). |
| 26 | 05-programming/regex-filenames | write | cleaning-intermediate | Unverändert (stringr). | **Migriert (M9 P1).**
| 27 | 05-programming/tidyeval-data-pronoun | complete | programming-expert | Unverändert. |
| 28 | 05-programming/tidyeval-embrace | complete | programming-intermediate | Unverändert. |
| 29 | 05-programming/trycatch-slope | write | programming-intermediate | Unverändert; Bezug zu `possibly()` (Nr. 23). |
| 30 | 06-stats/anova-eta | write | group-comparisons-intermediate | `afex::aov_ez()` + `effectsize::eta_squared()` statt `aov()` und Handrechnung. |
| 31 | 06-stats/assumptions | write | group-comparisons-intermediate | `performance::check_normality()`/`check_homogeneity()` auf Residuen. |
| 32 | 06-stats/correlation | write | regression-beginner **B** | `correlation::correlation()` statt `cor.test()`; Interpretation mit KI. | **Migriert (M8.2c).**
| 33 | 06-stats/describe-person | write | descriptives-beginner **B** | Zwei Stufen mitteln (Person, dann Bedingung); Abgrenzung zu `gc-b-describe` (dort schon aggregiert). | **Migriert (M8.2b).**
| 34 | 06-stats/lm-centered | write | regression-beginner **B** | `parameters::model_parameters()`; zentrieren mit `datawizard::center()` als Variante. | **Migriert (M8.2c).**
| 35 | 06-stats/mannwhitney | write | robust-intermediate | `rstatix::wilcox_test()` + `wilcox_effsize()`; englische Stufen. |
| 36 | 06-stats/padjust-predict | predict | group-comparisons-intermediate | Unverändert (Holm). |
| 37 | 06-stats/paired-debug | debug | group-comparisons-intermediate | Gepaarter Vergleich; ergänzt `gc-b-pseudoreplication` (dort: Durchgänge als unabhängig gezählt). |
| 38 | 06-stats/tukey | complete | group-comparisons-intermediate | `emmeans`/`modelbased::estimate_contrasts()` statt `TukeyHSD()`. |
| 39 | 07-mixed/allfit-singular | write | mixed-models-expert | Unverändert. |
| 40 | 07-mixed/condition-trial | complete | mixed-models-intermediate | Unverändert (lmerTest). |
| 41 | 07-mixed/icc | write | mixed-models-intermediate | `performance::icc()` statt Handrechnung aus `VarCorr()`; Schwerpunkt Deuten. |
| 42 | 07-mixed/random-intercept | write | mixed-models-intermediate | Unverändert. |
| 43 | 07-mixed/random-slope | complete | mixed-models-intermediate | Unverändert. |
| 44 | 07-mixed/reml-debug | debug | mixed-models-expert | Unverändert. |
| 45 | 07-mixed/residuals-debug | debug | mixed-models-intermediate | `performance::check_model()` als Ausblick. |
| 46 | 07-mixed/structure-predict | predict | mixed-models-intermediate | Zahlen an die neuen Daten anpassen (480 Zeilen, 9 fehlende `lane_dev`). |
| 47 | 08-ggplot2/aes-inherit | write | visualisation-beginner **B** | Braucht Check-Typ `plot`. | **Migriert (M8.2b).**
| 48 | 08-ggplot2/ci-ggsave | write | visualisation-intermediate | KI z. B. über `modelbased`; `ggsave()` ins Dateisystem von webR; Check `plot`. |
| 49 | 08-ggplot2/errorbar-person-debug | debug | visualisation-beginner **B** | Check `plot`. | **Migriert (M8.2b).**
| 50 | 08-ggplot2/facet-log-scale | write | visualisation-beginner **B** | Check `plot`. | **Migriert (M8.2b).**
| 51 | 08-ggplot2/mapping-setting-debug | debug | visualisation-beginner **B** | Check `plot`. | **Migriert (M8.2b).**
| 52 | 08-ggplot2/theme-predict | predict | visualisation-intermediate | Unverändert. |
| 53 | 09-reproducibility/here-project | write | reproducibility-intermediate | Prüfen, ob `here` in webR läuft; sonst „Lokal ausführen“. |
| 54 | 09-reproducibility/renv-dependencies-predict | predict | reproducibility-intermediate | Unverändert (nur vorhersagen, läuft ohne renv). |

## Streichen

| # | Alte Aufgabe | Grund |
|---|---|---|
| 1 | 01-basics/first-slow | Schleife baut `which()`/`purrr::detect_index()` nach; Schleife als Selbstzweck. |
| 2 | 01-basics/se-function | Baut den Standardfehler nach (liefern `parameters`/`datawizard`). Funktionen schreiben deckt `dots-center` ab. |
| 3 | 02-dplyr/group-summarise | Spielzeugdaten `mtcars`; Inhalt doppelt zu `count-units`/`describe-person`. |
| 4 | 03-tidyr/nest-models | Doppelt zu `04-purrr/nest-map-models` (gleiches Lernziel, dort mit purrr). |
| 5 | 04-purrr/map-na-count | Praxis ist `naniar::miss_var_summary()`. Typstabiles `map_*` deckt `map-extract-predict` ab. |
| 6 | 05-programming/bench-debug | Laufzeit messen ist kein Lernziel des Kurses; `bench` im Browser fraglich. |
| 7 | 05-programming/closure-predict | Closures und Environments sind für die Analysepraxis zu weit weg. |
| 8 | 05-programming/vectorize-change | Baut `dplyr::lag()` bzw. die prozentuale Änderung nach; `lag-predict` deckt es ab. |
| 9 | 06-stats/welch-age | Doppelt zum Prototyp `gc-b-ttest`/`gc-b-pseudoreplication` (Welch-t-Test auf Personenmitteln). |
| 10 | 09-reproducibility/rmarkdown-params-debug | Rendern läuft nicht im Browser, außerdem R Markdown statt Quarto. Inhalt als Kasten „Lokal ausführen“ mit Quarto-Parametern in reproducibility-intermediate. |
| 11 | 09-reproducibility/targets-pipeline | `targets` braucht Hintergrundprozesse und läuft nicht in webR. Inhalt als Kasten „Lokal ausführen“ in reproducibility-expert. |

## Folgen für den Beginner-Pfad (M8)
- Abgedeckt durch alte Aufgaben: working-with-r (1), import (1), cleaning (4), reshaping (3), visualisation (4), descriptives (3), regression (2). Group comparisons hat schon die 3 Übungen des Prototyps.
- Ohne alte Aufgabe, also neu zu schreiben: **scales-beginner** (mit `survey`: umpolen, SUS-Score, `psych::alpha()`) und **reporting-beginner** (`report`, `gtsummary`). Neu dazu kommen Übungen für import/cleaning mit `raw_export` und für visualisation mit `usability`.
- Check-Typ `plot` ist seit M8.2a vorhanden; seit M8.2b prüft er auch Position und eigene Daten einer Ebene.
