---
name: rtrainer-write-exercise
description: Use when creating, editing, or reviewing rtrainer exercises (YAML in inst/exercises or user directories), including kinds (write, predict, debug, complete), hints, explanations, checks, misconceptions, and datasets such as driving_sim.csv.
---

# Aufgaben schreiben

## Schema
Pflicht: id, topic, title, level (1-3), prompt, solution, check. Empfohlen: kind, tags, packages, setup, starter, hints (2-3), explanation, misconception, seed, common_mistakes.
Vorlage: `rtrainer::new_exercise(topic, id, dir)`. Beispiel: `inst/exercises/02-dplyr/group-summarise.yml`.

## Aufgabenarten (`kind`)
- `write` (Standard): Code schreiben; Starter nur Gerüst/Kommentar.
- `predict`: Code steht im Prompt (Setup erzeugt die Objekte), Nutzer tippt den erwarteten Wert als R-Literal (`c(4, NA, 7)`); Check `type: value`, Code-Antworten werden abgelehnt. Starter nur Kommentar. Prüft mentales Modell, z. B. Recycling, NA-Verhalten, Lazy Evaluation, Gruppierung nach `summarise()`.
- `debug`: Starter enthält einen typischen Fehler; Nutzer repariert ihn. `misconception` benennt die Fehlvorstellung.
- `complete`: Lösung mit Lücken (`___`); nur für neue/schwere Themen (Mixed Models, targets, tidy evaluation), Lücken über 2-3 Aufgaben ausblenden (Fading). Bekannte Themen: nicht `complete`, sondern `write`.

## Qualitätsregeln
- Ein Lernziel pro Aufgabe; Niveau fortgeschritten. Problem zuerst: kein ausgearbeitetes Beispiel vor dem Versuch (Expertise-Reversal).
- Prompt konkret: Ausgabeform, Spaltennamen, Rundung eindeutig.
- Hinweise stufenweise: grob, konkret, fast Lösung; nie der vollständige Code.
- Erklärung (elaboriert): warum die Lösung funktioniert, ein typischer Fallstrick, bei Statistik Interpretation mit Effektgröße und Konfidenzintervall (nicht nur p-Wert). 2-5 Sätze.
- `misconception`: eine Zeile zur häufigen Fehlvorstellung hinter dem Fehler; `common_mistakes` (2-4) mit Regex und gezielter Rückmeldung, die erklärt, WARUM es falsch ist.
- Transfer: Pro Konzept mindestens eine Variante in anderem Kontext (z. B. `driving_sim.csv` statt `mtcars`), gleiche Tags.
- Starter darf NICHT bestehen. Deterministisch: `seed` setzen. `packages:` setzen; lme4/ggplot2-Tests mit `skip_if_not_installed()`.
- Praxisnah: bevorzugt `driving_sim.csv` (`driving_sim <- read.csv(rtrainer_data("driving_sim.csv"))` im `setup`; Spalten: vp_id, age, gender, condition (visuell/auditiv/haptisch), trial 1-4, rt_ms, lane_dev).
- Check-Typ passend: value, object, function (mit Randfällen NA, leerer Vektor), ast, plot, output.
- `plot` (ggplot2, Vergleich mit der Musterlösung, kein Pixelvergleich): `name` (sonst letzter Wert), `geoms: [point, smooth]` (Klasse, `geom_histogram` = `bar`, `geom_jitter` = `point`), `mapping: {x: a, y: b}`, `facet: [var]`, `scales: [x]` (Transformation, Reihenfolge, Breaks), `layers: {errorbar: [x, ymin, ymax]}` (gebaute Layer-Daten, fängt falsche Statistik), `theme: [legend.position]`, `tolerance`. Beispiel: `inst/exercises/08-ggplot2/`.
- `post` (jeder Check-Typ): R-Code im Worker nach dem Nutzercode, Wert muss dem der Lösung entsprechen (z. B. PNG-Größe nach `ggsave()` in `tempdir()`); `post_message` als Meldung.

## Abschluss je Aufgabe
1. `read_exercise(path)` ohne Fehler.
2. `check_exercise(ex, ex$solution)$correct` TRUE, mit `ex$starter` FALSE.
3. Laufzeit < 5 s. Dann `rtrainer-verifier`.

## Verteilung (Soll)
Basics 6, dplyr 10, tidyr 6, purrr 7, Programmierung 8, Statistik 10, Mixed Models 8, ggplot2 6, Reproduzierbarkeit 4. Mindestens 10 % `predict`, 10 % `debug`, 10 % `complete` (nur in neuen Themen).
