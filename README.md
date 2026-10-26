# rtrainer

[![site](https://github.com/NikHenProj/rtrainer/actions/workflows/site.yaml/badge.svg)](https://github.com/NikHenProj/rtrainer/actions/workflows/site.yaml)

Zweisprachiger R-Kurs (Deutsch/Englisch) für Human Factors und UX: Lektionen mit live ausführbarem R im Browser (webR über [quarto-live](https://r-wasm.github.io/quarto-live/)), automatisch geprüften Übungen, Wissenscheck und Wiederholung nach dem Leitner-System. Kein Login, der Fortschritt bleibt im Browser.

**Kurs:** <https://nikhenproj.github.io/rtrainer/>

Stand: Grundgerüst mit der ersten Lektion *Gruppenvergleiche – Beginner* (Deutsch). Fahrplan und Entscheidungen: [docs/SPEC.md](docs/SPEC.md), aktueller Stand: [STATUS.md](STATUS.md). Die frühere Shiny-App (R-Paket) liegt im Tag `v0-shiny`.

## Lokal arbeiten

Voraussetzungen: Quarto ≥ 1.6, R ≥ 4.3 mit `yaml`, `jsonlite`, `testthat`, `withr`, `dplyr`, `tidyr`, `tibble`, `effectsize`, `parameters`.

```bash
Rscript tools/selftest.R                          # jede Übung: Lösung besteht, Starter scheitert
Rscript -e 'testthat::test_dir("tools/tests")'    # Tests für Generator und Checks
quarto preview                                    # Vorschau (erzeugt vorher die Übungsblöcke)
quarto render                                     # ganze Seite nach _site/
```

## Aufbau

| Pfad | Inhalt |
|---|---|
| `curriculum.yml` | 23 Themen × Stufen (Beginner/Intermediate/Expert) |
| `exercises/<thema>/<stufe>/` | `lesson.yml` (Metadaten), `quiz.yml` (Wissenscheck), eine YAML-Datei pro Übung |
| `de/`, `en/` | Seiten: Kursplan, Lektionen (Text), Wiederholen, Pakete, Glossar |
| `tools/generate.R` | YAML → quarto-live-Blöcke, Kursplan-Matrix, Wiederholungskarten (`_generated/`, läuft vor jedem Render) |
| `tools/checks.R` | Prüffunktionen, laufen im Browser und im Selbsttest |
| `tools/selftest.R`, `tools/tests/` | Selbsttest aller Übungen, Tests der Werkzeuge |
| `data/`, `data-raw/` | Simulierte Datensätze und ihre Skripte; `data/datasets.yml` beschreibt das Laden |
| `assets/` | Theme (SCSS), Fortschritt (`progress.js`), Lektionsseite (`lesson.js`) |
| `legacy/` | 65 Aufgaben der Shiny-Version, warten auf die Triage |

## Neue Übung

YAML-Datei in `exercises/<thema>/<stufe>/` anlegen (Vorlage: `exercises/group-comparisons/beginner/ttest.yml`), Selbsttest laufen lassen, rendern. Felder: `id, lesson, order, title{de,en}, kind (write|interpret|debug|complete|predict), required, packages, data, setup, prompt{de,en}, starter, solution, hints[{de,en}], explanation{de,en}, misconception{de,en}, check{type: value|object|output, …}, common_mistakes[{pattern, message{de,en}}]`.

## Lizenz

MIT
