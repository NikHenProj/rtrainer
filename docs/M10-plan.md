# M10: Expert-Stufe (Plan, abgenommen 2026-10-27)

Grundlage: SPEC.md „Struktur: Themen × Stufen“, „Lektion (Aufbau)“ und „Meilensteine“, `curriculum.yml`, `docs/legacy-triage.md`.
Ablauf wie M9: P0 (Werkzeug + Daten), dann DE in Paketen zu höchstens 3 Lektionen (je eine Sitzung, danach Verifier + Abnahme), dann EN, dann Mini-Projekt Expert (DE, danach EN).

## Umfang
16 Lektionen `<slug>-expert` + `project-expert`. Laut `curriculum.yml` haben 19 Themen eine Expert-Zelle; `signals`, `text` und `machine-learning` (Themen 18–20) folgen mit M11.
Expert-Lektionen haben den Aufbau aus SPEC.md mit einem Unterschied: Am Anfang steht eine **Herausforderung** („Versuch es erst selbst“). Sie ist überspringbar, danach folgen Erklärung und Übungen.
Pro Lektion: Herausforderung (zählt wie eine Zusatzübung), 3 Pflicht- + 1–2 Zusatzübungen, mindestens eine `interpret`- oder `debug`-Übung, Wissenscheck mit 5 Fragen. Abgeschlossen wie bisher: Pflichtübungen + Wissenscheck ≥ 80 %.

## webR (Index geprüft 2026-10-27, repo.r-wasm.org, R 4.5 und 4.6)
- **Im Index:** data.table, dtplyr, duckplyr, duckdb, mice, ggmice, miceadds, ggdist, ggrepel, ggtext, colorspace, mirt, GPArotation, EFAtools, polycor, semTools, semPlot, tidySEM, TOSTER, boot, coin, robustbase, robustlmm, sandwich, lmtest, clubSandwich, mgcv, ordinal, nnet, MASS, betareg, pscl, optimx, dfoptim, buildmer, mediation, faux, simr, Superpower, bayestestR, posterior, bayesplot, tidybayes, gt, flextable, pointblank, validate, testthat, rlang, cli, bench, specr, multiverse. `splines` gehört zu Base R.
- **Nicht im Index:** arrow, JointAI, blavaan, rstan, rstanarm, cmdstanr.
- **Im Index heißt nicht, dass es läuft.** glmmTMB ist gelistet, lud in M9 aber nicht; officer stürzt ab. brms ist gelistet, kann ohne Stan-Compiler aber nicht schätzen. targets braucht Hintergrundprozesse (callr), die webR nicht hat. Diese Pakete sind von vornherein „Lokal ausführen“: brms, rstanarm, BayesFactor, glmmTMB, officer/Word, papaja/apaquarto-Rendern, targets, renv, Docker, git.
- **Vor jedem Paket:** Ladezeit der Paketliste in webR messen (headless, wie in M9 P7). Wenn sie über 60 s liegt, Liste kürzen oder Teile nach „Lokal ausführen“ verschieben. Besonders prüfen: mirt, duckdb, robustlmm, DHARMa, ggtext (Schriften), specr, simr/faux.

## Pakete (Reihenfolge = empfohlener Pfad)

| Paket | Lektionen | Schwerpunkt | Altaufgaben (Triage-Nr.) | Daten |
|---|---|---|---|---|
| P0 | Werkzeug + Daten | Herausforderung im Generator, Expert-Spalte im Kursplan, neue Datensätze (siehe unten) | – | `tam_markets`, `bayes_draws` (neu) |
| P1 | reshaping, missing, visualisation | Non-equi- und Rolling Joins (`join_by(closest(), between())`), `pivot_longer(names_to = c(".value", …))`, große Daten mit dtplyr/duckplyr; mice vollständig (Methoden je Variable, Diagnose mit ggmice, `pool()`, MNAR-Sensitivität mit δ-Verschiebung), FIML als Alternative; ggdist (Verteilung + Unsicherheit), eigenes Theme als Funktion, Beschriftung mit ggrepel/ggtext, Farbsehschwäche mit colorspace prüfen | – | `driving_sim`, `usability`, `survey` |
| P2 | scales, sem, group-comparisons | Ordinales α/ω mit polychorischen Korrelationen, IRT (graded response) mit mirt, EFA-Entscheidungen mit EFAtools; Messinvarianz (konfigural → metrisch → skalar, partielle Invarianz) mit lavaan/semTools, ordinale CFA (WLSMV), latente Mediation; geplante und Interaktionskontraste mit emmeans, Äquivalenztests (TOST) mit parameters/TOSTER, ANCOVA | – | `tam_markets`, `acceptance`, `usability`, `survey` |
| P3 | robust, regression, glm | Bootstrap mit boot (BCa), Permutationstests mit coin, robuste Regression (`lmrob()`), WRS2 für mehrfaktorielle Designs; nichtlineare Zusammenhänge mit Splines, cluster-robuste Fehler (sandwich/clubSandwich), Kreuzvalidierung mit performance; ordinale Regression (ordinal `clm()`/`clmm()`), multinomial (nnet), Überdispersion und Nullen (MASS `glm.nb()`, pscl) | – | `survey`, `acceptance`, `driving_sim`, `usability` |
| P4 | mixed-models, moderation-mediation, power | Konvergenz und Singularität (`allFit()`), REML vs. ML beim Modellvergleich, Struktur der Zufallseffekte, GLMM mit `glmer()`, glmmTMB und DHARMa als „Lokal ausführen“, falls sie nicht laden; moderierte Mediation (Index der moderierten Mediation in lavaan), Mehrebenen-Moderation; Power durch Simulation für gekreuzte Designs (faux + lme4, eigene Schleife), Planung mit kleinstem interessierenden Effekt, sequentielle Designs als Ausblick | 39, 44 | `driving_sim`, `usability`, `acceptance` |
| P5 | bayes, reporting, reproducibility | Prior, Posterior, Credible Interval, ROPE, Bayes-Faktor über Savage-Dickey mit bayestestR/posterior an vorab gerechneten brms-Ziehungen, das brms-Modell selbst als „Lokal ausführen“; APA-Manuskript mit apaquarto (lokal), Berichten von Mixed Models und Bayes-Modellen, komplexe Tabellen mit gt, Berichtsfunktionen mit glue; Datenvalidierung mit pointblank/validate, Tests für Analysefunktionen mit testthat, targets, CI mit GitHub Actions und Docker als „Lokal ausführen“ | – | `bayes_draws`, `driving_sim`, `usability`, alle |
| P6 | programming | `pmap()` über Spezifikationen (Multiversum/Sensitivität), `.data`/`.env`, Funktionsfabriken, Fehlermeldungen mit cli/rlang, eigene `print()`-Methode (S3), Vektorisieren statt Schleife (bench) | 22, 27 | `driving_sim`, `usability` |
| P7–P8 | EN-Fassung | wie M9 P8/P9: P7 = P1–P3 (9 Lektionen), P8 = P4–P6 (7 Lektionen) | – | – |
| P9 | project-expert (DE, dann EN) | Präregistrierte Studie vom Plan zum Manuskript: Power durch Simulation → Validierung der gelieferten Daten → GLMM/LMM mit begründeter Zufallsstruktur → Sensitivität/Multiversum → Bayes-Ergänzung (vorab gerechnet) → Bericht. Mit Herausforderung „ganzer Plan zuerst selbst“ | – | siehe Offen |

Voraussetzungen: jeweilige Intermediate-Lektion; zusätzlich bayes-expert → regression- und mixed-models-intermediate; sem-expert → scales-intermediate; power-expert → mixed-models-intermediate; reporting-expert → reporting-intermediate und mixed-models-expert; project-expert → mixed-models-, power-, reporting- und programming-expert.

## Werkzeuge (P0, jeweils mit Tests: richtig, falsch, Randfall)
- **Herausforderung:** Übungsfeld `challenge: true` (höchstens eine pro Lektion). Der Generator stellt sie vor „Wozu?“ in einen Kasten „Versuch es erst selbst“ mit Link „Überspringen“ zum Abschnitt `#why`. Sie zählt nicht für „Abgeschlossen“ und kommt wie Zusatzübungen in die Wiederholung. Selbsttest gilt unverändert.
- **Kursplan:** Spalte Expert aktiv, sobald die erste Expert-Lektion existiert. Pfad „Als Nächstes“ über drei Stufen testen (Node-Test), Projektzeile mit drei Stufen.
- **Checks:** Wahrscheinlich ausreichend (Modelle über `model_parameters()`). Neu nur bei Bedarf: Vergleich von mice-`mira`-Objekten über `pool()`, Ziehungen über Zusammenfassungen (`describe_posterior()`) mit Toleranz.
- **Rauchtest:** je Paket eine Expert-Seite mit Herausforderung (Überspringen-Link, Bewertung einer Übung).

## Daten (P0)
- **Neu `tam_markets`:** Akzeptanzfragebogen wie `acceptance` (gleiche Items), zwei Märkte (`market`: de, us) mit je ca. 300 Personen. Bei einem Item ist der Intercept nicht invariant, die Antworten sind ordinal (1–7) mit Deckeneffekt bei einem Item. Gedacht für Messinvarianz, ordinale CFA, IRT und Mehrgruppen-Moderation. `acceptance` selbst bleibt unverändert, weil die abgenommenen Texte seine Zahlen nennen.
- **Neu `bayes_draws`:** Posterior-Ziehungen (z. B. 4 × 1000) aus lokal mit brms geschätzten Modellen: `lmer`-Analogon für `driving_sim` (Bedingung × Durchgang) und logistisches GLMM für `usability` (Erfolg), dazu Prior-Ziehungen für Savage-Dickey. Gespeichert als CSV (lange Form: `model`, `draw`, `parameter`, `value`). Das Skript in `data-raw/` braucht brms + Stan (lokal vorhanden) und läuft nicht in CI; die CSV wird eingecheckt. Tests prüfen Spalten und Zusammenfassungen.
- **Vorhandene Daten prüfen:** `usability$errors` (149 Nullen bei 284) reicht für Überdispersion/Nullen. `survey` reicht für mice; MNAR-Sensitivität rechnet mit einer angenommenen Verschiebung, ohne neue Daten.

## Entscheidungen bei der Abnahme (2026-10-27)
1. **Daten für project-expert:** neuer Datensatz `takeover` (Übernahmezeiten beim automatisierten Fahren, Messwiederholung, zensierte Zeiten, Ausfälle), erzeugt in P9 vor dem Schreiben.
2. **Herausforderung:** als bewertete Übung (`challenge: true`, eigener Check wie andere Übungen, zählt nicht für „Abgeschlossen“).
3. **programming-expert allein in P6:** Pakete und Pfad folgen der Reihenfolge in `curriculum.yml`; keine konfigurierbare Pfadreihenfolge.
