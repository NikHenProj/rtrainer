# STATUS

Stand (2026-10-26): Meilensteine 1-5 erledigt, 65 Paket-Aufgaben. Meilenstein 5, Teil 2 (Vignetten, GitHub Actions, shinytest2) erledigt; Abnahmekriterien siehe unten. Noch kein GitHub-Remote.

## Nach Meilenstein 5: Lücken behoben (Details: NEWS.md)
- `start("free", topics = )` setzt den Themenfilter vor (Checkboxen gesetzt, Filter aufgeklappt); danach gelten die Checkboxen, alle abwählen = alle Themen.
- Prüfungs-Timer behält nach „Prüfung beenden“ die Restzeit (`exam_time_left()`), die angezeigte Bearbeitungszeit bleibt ebenfalls stehen.
- Debug-Aufgaben: Standardtext „mindestens einen Fehler“, neues optionales YAML-Feld `bugs` (validiert) für die Anzahl; `ggplot2-mapping-setting-debug` hat `bugs: 2`. Vignette und Skill `rtrainer-write-exercise` ergänzt.
- Nebenbei gefunden: `kind_labels` war in `export_learnr.R` doppelt definiert und überschrieb das App-Badge („Reparieren“ statt „Fehler finden“), entfernt.
- GitHub: `gh` fehlt noch (Nutzer installiert `gh` und meldet sich an); Repo `rtrainer`, öffentlich, unter dem eigenen Account. Danach `OWNER` im Badge ersetzen, pushen, CI prüfen.

## Abnahmekriterien (SPEC.md, geprüft 2026-10-26)
| Kriterium | Ergebnis | Beleg |
|---|---|---|
| `rtrainer::start()` öffnet die App, Aufgabe lösbar, Feedback < 2 s | erfüllt mit Einschränkung | shinytest2-Smoke-Test läuft (App startet in Chromium, Code setzen, Prüfen, Rückmeldung erscheint); manuelle Browser-Tests in M3/M4. Feedback < 2 s für Basis-/Tidyverse-Aufgaben (dplyr 1,6 s erste Prüfung, 0,9 s danach). Aufgaben mit lme4/ggplot2/targets brauchen bei der ersten Prüfung 2-6,7 s (Paketladen im Subprozess). |
| Fortschritt bleibt nach Neustart erhalten | erfüllt | JSON atomar in `R_user_dir()`; Tests „progress survives save/load“, „corrupt file falls back…“, Settings-Test in `test-app-server.R` |
| >= 60 Aufgaben, alle Selbsttests grün | erfüllt | 65 Aufgaben, `check_all_solutions()` 65/65, alle Starter scheitern |
| `R CMD check` ohne Errors und Warnings | erfüllt | `Status: OK` (0/0/0), lokal mit Vignetten, ohne Pandoc; CI-Workflow angelegt, aber noch nie gelaufen (kein Remote) |
| Neue Aufgabe in < 5 Minuten als YAML | erfüllt (nicht von Hand gestoppt) | Vignette „Eigene Aufgaben“ führt `new_exercise()` -> `load_exercises()` -> `check_all_solutions()` beim Bauen real aus; nur eine Datei, keine Code-Änderung nötig |

## Meilenstein 5, Teil 2 (erledigt, Details: NEWS.md)
- Vignetten `vignettes/erste-schritte.Rmd` (Modi, Ablauf, Fortschritt/Leitner, Dashboard) und `vignettes/eigene-aufgaben.Rmd` (Felder, Arten, Check-Typen, `forbid`/`require`/`post`, Selbsttest, Registrieren, learnr-Export). Entscheidung: litedown-Engine statt `rmarkdown::html_vignette`, damit `R CMD check` ohne Pandoc läuft; litedown in Suggests.
- `.github/workflows/R-CMD-check.yaml`: r-lib/actions v2, ubuntu/macOS/Windows, R release; gradethis über `extra-repositories` (r-universe); Pandoc (`setup-pandoc`) und Chrome (`browser-actions/setup-chrome` -> `CHROMOTE_CHROME`), `NOT_CRAN: true`. Badge im README mit Platzhalter `OWNER`.
- shinytest2-Smoke-Test läuft jetzt: Er startet die App aus einem temporären `app.R` (vorher scheiterte er mit „no package called rtrainer“, und die Fortschritts-Option erreichte den App-Prozess nicht). Chrome bekommt ein eigenes TMPDIR und wird danach geschlossen (sonst NOTE „detritus in the temp directory“).
- Lokaler Browser ohne Systeminstallation: Playwright-Chromium unter `~/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome`. `CHROMOTE_CHROME` zeigt seit 2026-10-26 per `~/.Renviron` auf diesen Pfad (bei einem Playwright-Update ändert sich `chromium-1243`, dann anpassen); `NOT_CRAN=true` setzt `devtools::test()` selbst.

## Meilenstein 5, Teil 1 (erledigt, Details: NEWS.md)
- git-Repo angelegt (Branch `main`, `.gitignore` für R-Pakete; `.claude/launch.json` und `settings.local.json` nicht versioniert). Noch kein GitHub-Remote.
- `export_learnr(topics, path, exercises, overwrite)` in `R/export_learnr.R`: eine learnr-`.Rmd` pro Thema mit globalem Setup (gradethis, `rtrainer_data()`, `rt_equal()`/`rt_output()`), pro Aufgabe `<id>-setup`, `<id>` (Starter, `exercise.timelimit`), `<id>-hint-N`, `<id>-solution`, `<id>-check` (gradethis `grade_this()`, nur bei value/object/output) und Erklärung in `<details>`. Andere Check-Typen sowie `forbid`/`require`/`post` bekommen eine sichtbare Notiz. Rmd-Quelltext in Prompts wird für knitr maskiert.
- gradethis 0.2.14 aus r-universe installiert (nicht auf CRAN; `Additional_repositories` in DESCRIPTION). Mit `gradethis::mock_this_exercise()` geprüft: 51/54 übersetzte Checks lassen die Lösung bestehen, alle Starter fallen durch. Ausnahmen (bekannt, in NEWS.md): mixed-allfit-singular, repro-rmarkdown-params-debug, repro-targets-pipeline.
- Tests `tests/testthat/test-export-learnr.R`: Themenauswahl im `withr::local_tempdir()`, Chunk-Labels/exercise-Optionen/Anzahl Aufgaben, Notiz statt Check, object-Check, unbekanntes Thema, Überschreibschutz, Chunk-Grenze im Code, knitr-Roundtrip der Maskierung, alle 65 Aufgaben exportierbar und parsebar, gradethis-Mock (richtig/falsch); Rendern nur mit Pandoc (lokal übersprungen).
- README.md: Zweck, Installation, `start()`-Modi, eigene Aufgaben, Check-Typen, Lernförderung, Shiny statt learnr (+ Export), Abschnitt „keine Sandbox“.

## Meilenstein 4, Durchgang 9 (erledigt, Details: NEWS.md)
- 4 Reproduzierbarkeits-Aufgaben in `inst/exercises/09-reproducibility/` (topic `reproduzierbarkeit`, Projekte/Dateien nur im `tempdir()` des Workers): here-project (L1, Arbeitsverzeichnis `analysis/`, Wurzel über `.Rproj`/`here::i_am()`, `dir.create()` vor `write.csv()`, `require: [here]`), renv-dependencies-predict (L2, predict: statische Analyse von `renv::dependencies()`: `if (FALSE)` zählt, `character.only`/Kommentar/String nicht, `.Rmd` -> rmarkdown), rmarkdown-params-debug (L2, debug: globales `params` blockiert `render(params =)`; Fix `params = list(...)` + `envir = new.env()`), targets-pipeline (L3, complete: `format = "file"`, Abhängigkeiten über Symbole, Personenmittel; `check$post` ändert die CSV und erwartet alle 4 Ziele in `tar_outdated()`).
- Pandoc ist nicht installiert: Die Rmd-Aufgabe rendert über `render_md()` aus dem Setup (`rmarkdown::render(run_pandoc = FALSE)` mit Markdown-Format, sonst gleiche Argumente). renv ohne Netz/Installation (nur `dependencies()`), targets mit `tar_make(callr_function = NULL)`.
- Engine-Änderung: Nach `require`/`forbid`-Verstoß wird auch der passende `common_mistakes`-Hinweis angehängt (z. B. `setwd()`/`../` statt `here()`). Test in `test-check.R`.
- here, renv, targets in Suggests (Begründung in NEWS.md); eigener Content-Test mit `skip_if_not_installed()` plus Test, dass die predict-Antwort dem installierten renv entspricht. `here` absichtlich nicht in `packages:` (würde vor dem `setwd()` im Setup laden und die Wurzel falsch setzen).
- 26 typische Fehl- und Alternativantworten durchgespielt: alle Fehlantworten schlagen fehl mit passender Meldung (auch nach Laufzeitfehlern und Nachprüfung), Muster vertragen einfache Anführungszeichen und treffen keine Starter-Kommentare. Diese Alternativen bestehen: `library(here)` + `here("a/b")` ohne `i_am()`, `subset()`, `readr::write_csv()`, Rendern in der globalen Umgebung, `params = params` mit `envir = new.env()`, `vapply()` statt Schleife, `tar_load()`, `dplyr::summarise(.by)`.
- Laufzeit (Lösung, eine Prüfung inkl. Musterlösung): here 1,0 s, renv 0,8 s, rmarkdown 1,2 s, targets 2,2 s.

## Meilenstein 4, Durchgang 8 (erledigt, Details: NEWS.md)
- 6 ggplot2-Aufgaben in `inst/exercises/08-ggplot2/` (topic `ggplot2`, alle `driving_sim`, ggplot2/dplyr aus Suggests): aes-inherit (L1, globale vs. Layer-Mappings, `geom_smooth()` je Bedingung), mapping-setting-debug (L1, debug: `aes(fill = "steelblue")` und `colour = condition` außerhalb von `aes()`), theme-predict (L2, predict: `c("bottom", "right", "bottom")`, vollständiges Theme ersetzt `theme()`), facet-log-scale (L2, `scale_x_log10()` vs. `log10()` in `aes()` vs. `coord_trans()`, Breaks, Facets), errorbar-person-debug (L2, debug: SE aus Trials statt Personenmitteln, visuell 14 statt 23 ms; Anknüpfung an stats-describe-person), ci-ggsave (L3, t-KI aus Personenmitteln, Faktorreihenfolge, `ggsave()` 16 × 10 cm/300 dpi = 1889 × 1181 px, geprüft über PNG-Header).
- Engine-Änderung: `check: type: plot` vergleicht jetzt mit dem Plot der Musterlösung: `facet: [var]`, `scales: [x]` (Transformation, Reihenfolge, Breaks), `layers: {geom: [Spalten]}` (gebaute Layer-Daten, Farben normalisiert), `theme: [element]`. Neu `check$post` (Code im Worker nach dem Nutzercode, z. B. Datei prüfen) mit `post_message`. Mapping-Suche für ggplot2 4.0 repariert. YAML-Loader lässt nacktes `y`/`n` als String (vorher wurde `y:` zu `TRUE`). Tests in `test-check.R`, Content-Test für ggplot2 mit `skip_if_not_installed()` in `test-content.R`; Skill `rtrainer-write-exercise` ergänzt.
- 36 typische Fehl- und Alternativantworten durchgespielt: alle Fehlantworten schlagen fehl mit passender Meldung (auch nach Laufzeitfehlern und Nachprüfung), Muster vertragen einfache Anführungszeichen und treffen keine Starter-Kommentare. Diese Alternativen bestehen: `color`/`method = lm`/`se = F`, Hex-Farbe, `position_jitter()`, `facet_grid()`/`vars()`, `trans = "log10"`, `group_by()` + `.groups`, `stat_summary(mean_se)` auf Personenmitteln, `scale_x_discrete(limits =)`, benannte `ggsave()`-Argumente.
- In der App gegengeprüft (eingebauter Browser, Konfiguration `rtrainer-ggplot2` in `.claude/launch.json`): Plot-Tab zeigt den halb reparierten Boxplot mit der Legende „steelblue“, die Rückmeldung zum Füll-Layer und der Hinweis erscheinen; bei ci-ggsave zeigt die Nachprüfung 4800 × 3000 px plus den Zoll-Hinweis, nach dem Fix „Richtig!“.
- Laufzeit: eine Ausführung 1,8-2,6 s (aes-inherit am langsamsten: Rendern + `lm` je Gruppe); Prüfung mit Cache 1,9-3,2 s, erste Prüfung inkl. Musterlösung bis 6,7 s (aes-inherit). Im Selbsttest (Lösung + Starter) 3,8-8,5 s.

## Meilenstein 4, Durchgang 7 (erledigt, Details: NEWS.md)
- 8 Mixed-Model-Aufgaben in `inst/exercises/07-mixed/` (topic `mixed-models`, alle `driving_sim`, lme4/lmerTest aus Suggests): structure-predict (L1, predict: `c(4, 2, 40, 4)` = fixe Effekte, Spalten/Zeilen von `ranef()`, Zeilen von `VarCorr()`), random-intercept (L1, RM-Bedingungsvergleich aus Statistik nachgeholt, `confint(parm = "beta_")`, Profil oder Wald), icc (L2, Nullmodell-ICC 0.35 aus `VarCorr()`, Design-Effekt, `icc` gesperrt), random-slope (L2, complete: `(1 + trial | vp_id)`, `coef()` statt `ranef()`, Gegenstück zu purrr-nest-map-models: Shrinkage SD 0.015 -> 0.003), reml-debug (L2, debug: REML-LRT bei verschiedenen festen Effekten -> ML/`anova()`), residuals-debug (L2, debug: `na.action = na.exclude`, Residual-SD pro Bedingung), allfit-singular (L3, `allFit()` auf singulärem Maximalmodell, REML-LRT `refit = FALSE` gegen Zufallsintercept, χ²(9) = 5.3), condition-trial (L3, complete mit weniger Gerüst = Fading: `trial_c` zentriert, lmerTest Typ III Satterthwaite; unzentriert F = 48 statt 196).
- Datenlage: Random Slopes für `rt_ms` sind in `driving_sim` singulär (Korrelation ±1); daher Random Slope mit `lane_dev` (nicht singulär), Singularität ist Thema von allfit-singular.
- 43 typische Fehl- und Alternativantworten durchgespielt: alle Fehlantworten schlagen fehl mit passender Meldung (auch nach Laufzeitfehlern), Muster vertragen einfache Anführungszeichen und treffen keine Starter-Kommentare; Alternativen (Wald-KI, `anova()` statt manuell, `REML = F`, `!is.na()`-Filter, `diff(range())`, `scale(scale = FALSE)`, `(trial | vp_id)`) bestehen.
- Engine-Änderung: `run_code()` wertet Setup und Code im globalen Environment des Workers aus (vorher Kind-Environment; `allFit()`/`update()` in Funktionen fanden die Daten nicht). Test in `test-check.R`.
- Tests: Aufgaben mit nicht installierten `packages` werden im Content-Test übersprungen; eigener Mixed-Test mit `skip_if_not_installed("lme4")`/`("lmerTest")`.
- Laufzeit: eine Ausführung max. 3,7 s (allfit-singular); erste Prüfung inkl. ungecachter Musterlösung 5,3 s, danach ~3,7 s. Grund: Laden von lme4 im Subprozess (~1,3 s) + `allFit()`.

## Meilenstein 4, Durchgang 6 (erledigt, Details: NEWS.md)
- 10 Statistik-Aufgaben in `inst/exercises/06-stats/` (topic `statistik`, alle `driving_sim`, nur Basis-`stats`): describe-person (L1, zweistufig Person -> Bedingung, n = Personen, SE), welch-age (L1, Welch-t auf Personenmitteln, Altersgruppe im Setup), padjust-predict (L2, predict: Holm mit Monotonie und Eingabereihenfolge), paired-debug (L2, debug: ungepaarter Trial-t-Test -> aggregiert + `paired = TRUE`, d_z), mannwhitney (L2, `wilcox.test(conf.int = TRUE)` + Rang-biseriale r), correlation (L2, `cor.test()` auf Personenebene), anova-eta (L2, `aov()` F + eta²), tukey (L2, complete: `TukeyHSD()`-Tabelle, Spalte `"p adj"`), assumptions (L3, Shapiro auf Residuen, Brown-Forsythe per `aov()` auf |Abweichung vom Gruppenmedian|, `leveneTest` gesperrt), lm-centered (L3, Prädiktor zentriert/skaliert, `-`/`/` in Formeln, `I()`).
- Pseudoreplikation (fehlende Aggregation pro `vp_id`) ist überall, wo relevant, ein `common_mistakes`-Eintrag. Erklärungen nennen Effektgröße und KI; Zahlen gegen die Daten geprüft.
- 45 typische Fehl- und Alternativantworten durchgespielt: alle Fehlantworten schlagen fehl mit passender Meldung (auch nach Laufzeitfehlern, z. B. 3 Geschlechter im U-Test, `"p_adj"`, Formel-Arithmetik), Muster vertragen einfache Anführungszeichen und treffen keine Starter-Kommentare; Alternativen (`aggregate()`, `group_by()`, `lm()` + `r.squared`, `t.test(diff)`, `I()`, `tk[, 4]`) bestehen.
- Keine Engine-Änderung, keine neue Abhängigkeit.

## Meilenstein 4, Durchgang 5 (erledigt, Details: NEWS.md)
- 8 Programmier-Aufgaben in `inst/exercises/05-programming/` (topic `programmierung`): dots-center (L1, `fun(x, ...)`, Function-Check mit NA/leer; Transfer zu purrr-pmap-specs über Tag `dots`), closure-predict (L1, predict: Funktionsfabrik, eigenes Environment pro Aufruf, `<<-`), trycatch-slope (L2, Function-Check: `error = function(e) NA_real_`, Handler muss Funktion sein, Typstabilität; Transfer zu purrr-possibly-read über Tag `fehlerbehandlung`), regex-filenames (L2, `str_match()` mit Ankern, `\\.`, `\\d+`, `ignore_case`), tidyeval-embrace (L2, complete: `{{ }}`), vectorize-change (L2, Function-Check, Schleifen/apply/map per `forbid` gesperrt, Randfälle leer und Länge 1), tidyeval-data-pronoun (L3, complete mit weniger Gerüst = Fading: `.data[[var]]`, `"mean_{var}" :=`), bench-debug (L3, debug: `bench::mark()` lehnt abweichende Ergebnisse ab, `!is.na(x[i]) && ...` macht NA zu FALSE).
- Typische Fehlantworten je Aufgabe geprüft (schlagen fehl, passende `common_mistakes`-Meldung; Muster treffen keine Starter-Kommentare); Alternativen (`match.fun`, `dplyr::lag`, `diff` mit Sonderfall, `.by`, `!!paste0() :=`, `str_split_fixed`, `if (is.na()) NA`) bestehen. Dabei behoben: zufällig gleiche Testwerte (getrimmter Mittelwert = Median), Muster nur für doppelte Anführungszeichen.
- Engine-Änderung: `check$require` wirkt jetzt auch ohne `forbid` (vorher still ignoriert), Test in `test-check.R`.
- `bench` installiert (1.1.4) und in Suggests (Begründung in NEWS.md).

## Meilenstein 4, Durchgang 4 (erledigt, Details: NEWS.md)
- 7 purrr-Aufgaben in `inst/exercises/04-purrr/`: map-na-count (L1, `map_int()` Pflicht, `sapply`/`colSums` gesperrt), map-extract-predict (L1, predict: `map("rt")`, `mean(numeric(0))` = `NaN`), map2-cutoff-debug (L2, debug: Zusatzargumente von `map()` werden ganz weitergereicht -> `map2_dbl()`), pmap-specs (L2, complete: Spalten per Name an Argumente, `...` fängt `label`), reduce-join (L2, `reduce()` + `left_join()`, `inner`/`right_join` verlieren 9 Personen), nest-map-models (L3, Transfer zu tidyr-nest-models mit gleichen Tags: `lm` pro Person, `map_dbl`/`map_int`, `nobs()` statt `nrow()`), possibly-read (L3, complete: `possibly(read.csv, otherwise = NULL)` + `list_rbind(names_to = "file")`, Setup schreibt CSVs nach `tempdir()`).
- Typische Fehlantworten je Aufgabe geprüft (schlagen fehl, passende `common_mistakes`-Meldung, auch bei Laufzeitfehlern); Alternativen (`reduce(parts, left_join)`, `full_join`, `otherwise = data.frame()`, `NA` statt `NaN`) bestehen.
- Keine Engine-Änderung.

## Meilenstein 4, Durchgang 3 (erledigt, Details: NEWS.md)
- 6 tidyr-Aufgaben in `inst/exercises/03-tidyr/`: pivot-longer-predict (L1, predict: zeilenweises Stapeln, `NA` bleibt), pivot-wider (L1, `id_cols`-Falle, Alternative `values_fn`), separate-delim (L2, `too_few = "align_start"`, `trial` als integer; `separate()` per `forbid` gesperrt), drop-na-debug (L2, debug: `drop_na()` ohne Spalten = listenweiser Ausschluss), complete-trials (L2, complete: `complete(nesting(vp_id, age, gender), condition, trial = 1:4)`), nest-models (L3, Listenspalten, `lm` pro Bedingung, `nest()` Pflicht, `group_by/summarise` gesperrt, `lapply()` statt purrr).
- Typische Fehlantworten je Aufgabe geprüft (schlagen fehl, passende `common_mistakes`-Meldung); Alternativen (`values_fn`, `filter(!is.na())`, `unnest_wider()`) bestehen.
- Engine-Änderung: `common_mistakes`-Hinweise erscheinen jetzt auch nach Laufzeitfehlern (`add_mistake_hint()` in `R/check_engine.R`), Test in `test-check.R`.

## Meilenstein 4, Durchgang 2 (erledigt, Details: NEWS.md)
- 9 neue dplyr-Aufgaben in `inst/exercises/02-dplyr/` (alle `driving_sim`): filter-select (L1, `%in%` statt `== c()`), count-units (L1, Personen statt Zeilen), case-when (L2, NA vs. Auffangfall), across (L2, `.names`, `na.rm`), lag-predict (L2, predict), slice-max (L2, Ties), summarise-regroup (L3, debug, Transfer zu group-summarise: Gruppierung nach `summarise()`), join (L3, `join_by(vp_id == vp)`, left vs. inner/full), window-cumsum (L3, gemischte Zeilen, `cumsum` + NA).
- Typische Fehlantworten je Aufgabe geprüft: schlagen fehl und lösen die passende `common_mistakes`-Meldung aus; Alternativlösungen (`.by`, `.groups = "drop"`, `order_by`) bestehen.
- Bugfix `compare_df()`: Absturz bei erwartet `NA`, bekommen Zahl (Rundungs-Heuristik); Regressionstest in `test-check.R`.

## Meilenstein 4, Durchgang 1 (erledigt, Details: NEWS.md)
- Datensatz `inst/extdata/driving_sim.csv` (480 Zeilen: 40 VP × 3 Bedingungen visuell/auditiv/haptisch × 4 trials; vp_id, age, gender, condition, trial, rt_ms, lane_dev; NA: 12 rt_ms, 9 lane_dev, age bei vp17), Skript `data-raw/driving_sim.R` (Seed 20261025), Doku `?driving_sim` in `R/data.R`.
- `rtrainer_data(name)`: Pfad zu Paketdaten; im Worker von `run_code()` ebenfalls definiert (Aufgaben-Setup: `driving_sim <- read.csv(rtrainer_data("driving_sim.csv"))`). Skill `rtrainer-write-exercise` angepasst.
- Entscheidung predict: Antwort ist ein Wert als R-Literal, Check `type: value`; `check_literal()` lehnt Code (Variablen, Zuweisungen, andere Aufrufe) ab.
- 6 Basics-Aufgaben in `inst/exercises/01-basics/`: na-index (L1, predict), nested-list (L1, write), factor-numeric (L2, debug), factor-relevel (L2, write, driving_sim), se-function (L2, write, Randfälle), first-slow (L3, complete).

## Aufgaben pro Thema (Ist/Soll)
| Thema | Ist | Soll |
|---|---|---|
| Basics | 6 | 6 |
| dplyr | 10 | 10 |
| tidyr | 6 | 6 |
| purrr | 7 | 7 |
| Programmierung | 8 | 8 |
| Statistik | 10 | 10 |
| Mixed Models | 8 | 8 |
| ggplot2 | 6 | 6 |
| Reproduzierbarkeit | 4 | 4 |
| **Gesamt** | **65** | **65** |

Arten: write 35 (54 %), predict 9 (14 %), debug 11 (17 %), complete 10 (15 %) – je ≥ 10 % erfüllt.

## Meilenstein 3 (erledigt, Details: NEWS.md)
- `start(mode = "daily"|"free"|"exam", n, time_limit, topics, dirs)`, `rtrainer_app()` für shinytest2/Deployment.
- Dateien: `R/app_logic.R` (reine Funktionen: Queue, Filter, Feedback, Prüfungsauswertung), `R/app_ui.R`, `R/app_server.R` (dünn, `testServer`-getestet), `R/start.R`.
- Lernförderung umgesetzt: Problem zuerst, Hinweise stufenweise, Lösung erst nach Versuch (sonst Bestätigungsdialog, zählt als falsch), Sicherheits-Rating 1-3 (Tasten, abschaltbar), sicherer Fehler -> hervorgehobenes elaboriertes Feedback + Wiedervorlage in der Sitzung, Leicht/Okay/Schwer mit Deckelung, Selbsterklärungs-Notiz, Daily interleavt, Prüfung ohne Hilfen mit Timer.
- Dashboard: Streak, Woche, Quote, gemeistert, Heatmap, Quote pro Thema, Kalibrierung, schwächste Tags, Fehlerjournal.
- Performance: Lösungs-Cache -> Prüfen 1,6 s (erste Prüfung, dplyr) / 0,9 s danach.
- Browser-Test manuell im eingebauten Browser (Daily: falsch+sicher, Hinweis, richtig, Bewertung, Plot, Dashboard; Exam: Abgabe, Beenden, Auswertung) - ok. Dabei gefunden und behoben: `need(nrow(x))` greift bei 0 nicht, `due_ids()` lieferte `NULL`, Plot-Hintergrund im Dark-Mode, Leerraum im `pre`.
- Start für manuelle Tests: `.claude/launch.json` (Konfigurationen `rtrainer-daily`, `rtrainer-exam`; Skript und Datenverzeichnis liegen im Scratchpad dieser Sitzung, für neue Sitzungen ggf. neu anlegen).

## Als Nächstes
GitHub-Remote anlegen (`gh` installieren und anmelden: macht der Nutzer), `OWNER` im README-Badge ersetzen, pushen und den ersten CI-Lauf prüfen (macOS/Windows, shinytest2 mit Chrome, learnr-Rendern mit Pandoc). Danach restliche Lücken unten.

## Bekannte Lücken
- learnr-Export: 3 Checks scheitern in gradethis trotz richtiger Lösung (`allFit()` braucht das globale Environment; Datei-Seiteneffekte im Setup werden für die Lösung nicht wiederholt). Gerendert und im Browser angesehen wurde noch kein exportiertes Tutorial (kein Pandoc).
- shinytest2-Smoke-Test hängt lokal am Playwright-Chromium-Pfad in `~/.Renviron` (siehe oben).
- "Loading required package: shiny" erscheint in den Tests (harmlos, kommt aus einer Abhängigkeit beim `testServer`).
- predict-Prompts zeigen Code als Markdown-Block; in der App noch nicht gegengeprüft, wie das aussieht und dass der Starter-Kommentar nicht verwirrt.
- Pandoc fehlt lokal: Nur das Rendern exportierter learnr-Tutorials ist betroffen (Test übersprungen, läuft in CI). Vignetten brauchen kein Pandoc mehr.
- CI-Workflow ist ungetestet, bis ein Remote existiert.
- Feedback < 2 s gilt nicht für Aufgaben mit lme4/ggplot2/targets bei der ersten Prüfung (bis 6,7 s).

## Externe Skills (installiert 2026-10-25 nach .claude/skills/)
- posit-dev/skills@4400f97: r-package-development, r-testthat, r-tidyverse-style, shiny-bslib, create-release-checklist; anthropics/skills@dbd4588: webapp-testing. skill-creator kommt als Plugin-Skill.
- Konflikte, bei denen die Projektregeln gelten: kein `air format` (styler/lintr); `expect_error()` bleibt, Snapshots nur für neue, längere Meldungen.
- webapp-testing braucht Python Playwright (nicht installiert); stattdessen eingebauter Browser + shinytest2.
- create-release-checklist braucht `gh` plus GitHub-Remote (git-Repo seit 2026-10-26, Remote fehlt noch).

## Offene Entscheidungen
(keine)

## Letzte Testausgabe (gekürzt, 2026-10-26, via rtrainer-verifier, mit `CHROMOTE_CHROME`)
- `devtools::test()`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 727 ]` (Skip: Tutorial-Rendern – Pandoc fehlt). Browser-Smoke-Test lief und bestand.
- `check_all_solutions()`: 65/65 ok, alle Starter schlagen fehl, max. 8,9 s (mixed-allfit-singular)
- `devtools::check(--no-manual)`: `Status: OK` (0 errors | 0 warnings | 0 notes)
