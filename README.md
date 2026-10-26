# rtrainer

<!-- badges: start -->
[![R-CMD-check](https://github.com/NikHenProj/rtrainer/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/NikHenProj/rtrainer/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Lokaler, offline nutzbarer Trainer für fortgeschrittenes R: eine Shiny-App mit
65 Aufgaben (Basics, dplyr, tidyr, purrr, Programmierung, Statistik, Mixed
Models, ggplot2, Reproduzierbarkeit), automatischer Prüfung, gestuften
Hinweisen und verteilter Wiederholung (Leitner oder SM-2). Die Aufgaben sind
YAML-Dateien, eigene lassen sich in wenigen Minuten ergänzen.

Zielgruppe: Leute, die R schon produktiv nutzen (Tidyverse, `lm()`, ggplot2)
und tiefer einsteigen wollen. Die meisten Aufgaben arbeiten mit dem
mitgelieferten Datensatz `driving_sim` (Fahrsimulator-Studie, 40 Personen ×
3 Bedingungen × 4 Trials, siehe `?driving_sim`).

## Installation

```r
# aus einem lokalen Klon
# install.packages("pak")
pak::local_install("pfad/zu/rtrainer")

# Pakete, die die Aufgaben verwenden (Suggests)
install.packages(c("dplyr", "tidyr", "purrr", "stringr", "ggplot2", "lme4",
                   "lmerTest", "bench", "here", "renv", "targets", "rmarkdown"))
```

Voraussetzung ist R >= 4.3. Systemabhängigkeiten gibt es keine. Aufgaben,
deren Pakete fehlen, schlagen beim Prüfen mit einer Meldung fehl, die
übrigen funktionieren trotzdem.

## Start

Ausführlicher: `vignette("erste-schritte", "rtrainer")` und
`vignette("eigene-aufgaben", "rtrainer")`.

```r
rtrainer::start()                                  # Daily: fällige Wiederholungen + neue Aufgaben, Themen gemischt
rtrainer::start("free")                            # freie Auswahl mit Filtern (Thema, Level, Tags)
rtrainer::start("exam", n = 15, time_limit = 30)   # Prüfung: ohne Hinweise/Lösung, mit Timer
rtrainer::start(topics = c("dplyr", "purrr"))      # Daily nur für bestimmte Themen
```

`rtrainer::start()` statt `start()` nach `library(rtrainer)`: Der Name
überdeckt sonst `stats::start()`.

Tastenkürzel im Editor: Strg+Enter führt aus, Strg+Umschalt+Enter prüft.
Das Dashboard zeigt Streak, Wochenaktivität, Trefferquote pro Thema,
Kalibrierung (Trefferquote je Sicherheitsstufe) und ein Fehlerjournal.

Der Fortschritt liegt als JSON in `tools::R_user_dir("rtrainer", "data")` und
wird atomar geschrieben. Anderer Ort:

```r
options(rtrainer.data_dir = "~/sync/rtrainer")
```

## Eigene Aufgaben

```r
rtrainer::new_exercise("meine-themen", "rt-median", dir = "~/r-aufgaben")
# Vorlage ~/r-aufgaben/meine-themen/rt-median.yml ausfüllen, dann:
rtrainer::add_exercise_dir("~/r-aufgaben")         # einmalig registrieren
rtrainer::check_all_solutions()                    # Selbsttest: Lösung besteht, Starter scheitert
```

Eine Aufgabe besteht aus `prompt`, optional `setup` und `starter`, der
Musterlösung `solution`, `hints`, `explanation` und einem `check`:

| `check.type` | prüft |
|---|---|
| `value` | letzter Wert (Toleranz, Data Frames mit/ohne Zeilen- und Spaltenreihenfolge) |
| `object` | ein benanntes Objekt (Existenz, Klasse, optional Wert) |
| `output` | gedruckte Ausgabe |
| `function` | eine Funktion gegen Testfälle |
| `regex`, `ast` | statisch: Muster bzw. verwendete/verbotene Funktionen |
| `plot` | ggplot-Struktur gegen den Plot der Musterlösung |

Dazu kommen `forbid`/`require` (Funktionen sperren oder verlangen) und
`common_mistakes` (Regex auf den Code mit gezieltem Hinweis). Aufgabenarten
(`kind`): `write`, `predict` (Ergebnis vorhersagen), `debug` (Fehler
reparieren), `complete` (Lücken füllen).

## Lernförderung

Die App setzt gut belegte Lernprinzipien um, abgestimmt auf Fortgeschrittene:

- **Problem zuerst** statt ausgearbeiteter Beispiele (Expertise-Reversal);
  Hinweise nur auf Abruf, Lösung erst nach einem Versuch.
- **Abrufübung** und **verteiltes Üben**: Leitner-Boxen 1-5 mit Intervallen
  0/1/3/7/21 Tagen. Wer falsch liegt, kommt in Box 1. „Leicht“ zählt nur bei
  weniger als 2 Hinweisen. SM-2 ist als Alternative wählbar.
- **Interleaving**: Der Daily-Modus mischt Themen statt sie blockweise zu üben.
- **Sicherheits-Rating** vor dem Prüfen (1-3, abschaltbar). Bei sicheren
  Fehlern gibt es elaboriertes Feedback (Erwartung, Ergebnis, typische
  Fehlvorstellung) und die Aufgabe kommt in der Sitzung noch einmal.
- **predict/debug/complete** prüfen mentale Modelle, trainieren Fehlersuche
  und blenden Gerüste schrittweise aus (Fading).

Belegt ist das vor allem für Wissensfragen (Dunlosky et al., 2013), für
Programmieraufgaben weniger. Die Kalibrierungsdaten im Dashboard zeigen, ob es
bei dir wirkt.

## Warum Shiny und nicht learnr?

learnr ist für lineare Tutorials gebaut. rtrainer braucht Dinge, die dort
schwer umzusetzen sind: Fortschritt über Sitzungen hinweg mit eigener
Wiederholungslogik, Aufgaben als YAML-Daten statt als Rmd-Dokumente, gemischte
Sitzungen aus mehreren Themen, Prüfungsmodus mit Timer, Sicherheits-Rating
und ein Dashboard. Außerdem läuft jeder Prüfvorgang in einem frischen
R-Prozess. Ein abstürzender oder hängender Nutzercode reißt so die App nicht
mit.

Wer trotzdem learnr nutzen will (etwa für einen Kurs), kann exportieren:

```r
rtrainer::export_learnr(c("dplyr", "purrr"), path = "tutorials")
rmarkdown::run("tutorials/dplyr.Rmd")   # braucht learnr, gradethis und Pandoc
```

Pro Thema entsteht eine `.Rmd` mit Setup-, Übungs-, Hinweis- und
Lösungs-Chunks. `value`-, `object`- und `output`-Checks werden zu
gradethis-Checks. Für die übrigen Check-Typen und für `forbid`/`require`
steht im Tutorial ein Hinweis, dass dort nicht automatisch geprüft wird.
gradethis gibt es nicht auf CRAN, es wird so installiert:
`install.packages("gradethis", repos = c("https://rstudio.r-universe.dev", getOption("repos")))`.

## Sicherheit: keine Sandbox

Nutzercode läuft per `callr::r()` in einem eigenen R-Prozess. Das
Arbeitsverzeichnis ist ein temporäres Verzeichnis, der Timeout liegt bei
10 Sekunden. Fehler, Warnungen und Ausgaben werden mit `evaluate`
abgefangen. Das schützt die App vor **Versehen** wie Endlosschleifen,
`q()` oder Abstürzen.

Es ist **keine Sicherheits-Sandbox**: Der Code läuft mit deinen
Benutzerrechten und kann auf absolute Pfade, das Netzwerk und
Systembefehle zugreifen. Führe nur Aufgaben aus Quellen aus, denen du
vertraust. Für YAML-Dateien von Dritten gilt das ebenfalls, denn `setup`
und `solution` werden ausgeführt.

## Lizenz

MIT
