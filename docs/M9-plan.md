# M9: Intermediate-Stufe (Plan, abgenommen 2026-10-26)

Grundlage: SPEC.md „Struktur: Themen × Stufen“ und „Meilensteine“, `curriculum.yml`, `docs/legacy-triage.md`.
Ablauf wie M8: DE in Paketen zu 3 Lektionen (je eine Sitzung, danach Verifier + Abnahme), dann EN, dann Mini-Projekt.

## Umfang
18 Lektionen `<slug>-intermediate` + `project-intermediate`. `text-intermediate` erst mit M11 (Spezialthemen 18–20).
Alle Kernpakete im webR-Index (R 4.5) geprüft: readxl, haven, janitor, naniar, mice, lavaan, semTools, WRS2, glmmTMB,
marginaleffects, interactions, mediation, pwr, Superpower, simr, modelsummary, rempsyc, purrr, afex, emmeans,
modelbased, ggeffects. Nicht im Browser: renv, here-Projektlogik, Quarto-Rendern, `brms` → „Lokal ausführen“.
Ladezeit je Lektion messen (lavaan, glmmTMB, simr sind groß); bei > 60 s Paketliste kürzen.

## Pakete (Reihenfolge = empfohlener Pfad)

| Paket | Lektionen | Schwerpunkt | Altaufgaben (Triage-Nr.) | Daten |
|---|---|---|---|---|
| P1 | import, cleaning, reshaping | readxl mit Titelzeilen, haven/Labels, mehrere Dateien; janitor, stringr, forcats, lubridate; Joins, Fensterfunktionen | 23; 18, 26; 10, 13, 24 | `raw_export(_xlsx)`, `usability` |
| P2 | missing, visualisation, descriptives | naniar (Muster), Mehrfachimputation mit mice als Ausblick; Modellplots mit KI, patchwork, ggsave; `across()` über Skalen, gruppierte Tabellen | 14, 15; 48, 52; 5 | `survey`, `driving_sim` |
| P3 | scales, sem, group-comparisons | Reliabilität ω, Itemanalyse, EFA; CFA mit lavaan, Fit deuten; einfaktorielle/Messwiederholungs-ANOVA mit afex, Kontraste mit emmeans/modelbased, Holm | 30, 31, 36, 37, 38 | `acceptance` (neu), `usability` |
| P4 | robust, regression, glm | Wilcoxon/Kruskal + Effektgrößen, WRS2 (getrimmte Mittel); multiple Regression, Interaktionen, Diagnostik mit performance; logistische und Poisson-Regression, marginaleffects | 35 | `usability` (Erfolg/Timeout, Fehlerzahl), `survey` |
| P5 | mixed-models, moderation-mediation, power | lme4/lmerTest, Random Slopes, ICC, gekreuzte Effekte (Person × Aufgabe); Moderation mit interactions, Mediation mit lavaan; pwr, Simulation mit Superpower/simr | 40–46 | `driving_sim`, `usability`, `acceptance` |
| P6 | reporting, reproducibility, programming | modelsummary, rempsyc, APA-Tabellen nach Word; Projektstruktur, renv/git als „Lokal ausführen“; eigene Funktionen, tidy eval, purrr (`map`, `possibly`, nest + Modelle) | 53, 54; 4, 19–21, 25, 28, 29 | alle |
| P7 | project-intermediate | Usability-Studie aus `raw_export_xlsx` bis Bericht: Bereinigen, Mixed Model (Person × Aufgabe), Kontraste, Abbildung, Tabelle, Text | – | `raw_export_xlsx`, `usability` |
| P8–P9 | EN-Fassung | wie M8 Teil 3: 3 Pakete pro Sitzung übersetzen, dann Projekt | – | – |

Ab Intermediate pro Lektion 3 Pflicht- + 1–2 Zusatzübungen, mindestens eine `interpret`- oder `debug`-Übung. Wissenscheck 5 Fragen.
Voraussetzungen: jeweilige Beginner-Lektion; sem → scales-intermediate; mixed-models → group-comparisons-intermediate, regression-intermediate; moderation-mediation → regression-intermediate; glm → regression-intermediate.

## Daten (vor P3)
- Neu `acceptance`: Akzeptanzfragebogen zu einem Fahrerassistenzsystem (Technology Acceptance Model), n = 300,
  Faktoren wahrgenommene Nützlichkeit, Bedienbarkeit, Vertrauen, Nutzungsabsicht (je 4–5 Items, 1–7, zwei umgepolt),
  dazu Erfahrung, Alter. Für CFA (Faktorstruktur mit einem schwachen Item), Mediation (Bedienbarkeit → Nützlichkeit → Absicht),
  Moderation (Erfahrung). Skript in `data-raw/`, Eintrag in `data/datasets.yml`, Tests.
- `usability` prüfen, ob Erfolg (Timeout = Misserfolg) und Fehlerzahl für glm reichen; sonst Spalte `errors` (Zählwert) ergänzen.

## Werkzeuge (bei Bedarf, jeweils mit Tests)
- Check für lavaan-/merMod-Objekte: über `parameters::model_parameters()` vergleichen statt über das Objekt.
- Kursplan: Spalte Intermediate wird aktiv, sobald die erste Lektion existiert (vorhanden); Pfadlogik „Als Nächstes“ über Stufen hinweg testen.

## Offen (bei Abnahme klären, keine Blockade)
- `acceptance` als TAM-Fragebogen: abgenommen.
- Mediation mit lavaan (SPEC) oder zusätzlich `mediation`-Paket im Vergleich zeigen.
