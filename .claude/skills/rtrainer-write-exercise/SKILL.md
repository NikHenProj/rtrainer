---
name: rtrainer-write-exercise
description: Use when creating, editing, reviewing or migrating rtrainer course exercises (YAML in exercises/<topic>/<level>/), including kinds (write, interpret, debug, complete, predict), bilingual texts, hints, explanations, checks, misconceptions, datasets, and triage of the legacy exercises from tag v0-shiny.
---

# Übungen schreiben (Quarto-Kurs)

Grundlage: docs/SPEC.md, Abschnitte „Übungen (Single Source)“, „Paket-Standard“, „Daten“, „Lernförderung“.
Das YAML-Schema wird in Meilenstein 6 finalisiert; maßgeblich ist dann das Beispiel `exercises/group-comparisons/beginner/` und die Validierung in `tools/generate.R`.

## Schema (Entwurf)
`id, lesson (<slug>-<level>), title{de,en}, kind, required, packages, data, setup, starter, solution, hints[{de,en}], explanation{de,en}, misconception{de,en}, check{type, …}, common_mistakes[{pattern, message{de,en}}]`.
Jeder Text DE **und** EN; Code, Daten, Spaltennamen nur Englisch.

## Was eine gute Übung ist
- Echtes Werkzeug aus dem Paket-Standard (tidyverse + easystats, rstatix, afex, modelbased, psych, lavaan …), realistische Daten, Ergebnis **interpretieren** lassen. Keine Nachbauten von Basisfunktionen (eigene `sd()`, Schleifen statt Vektorisierung als Selbstzweck).
- Ein Lernziel pro Übung; passt zur Stufe der Lektion; steigende Schwierigkeit innerhalb der Lektion.
- Arten: `write` (Code schreiben), `interpret` (Ausgabe deuten, z. B. `report()`/`parameters()`), `debug` (typischer Fehler, `misconception` benennt die Fehlvorstellung), `complete` (Lücken `______`, nur bei neuen Themen), `predict` (Ergebnis vorhersagen).
- Prompt konkret: Ausgabeform, Spaltennamen, Rundung eindeutig.
- Hinweise gestuft: grob, konkret, fast Lösung; nie der vollständige Code.
- Erklärung: warum es funktioniert, ein Fallstrick, bei Statistik Effektgröße + KI + APA-Formulierung (nicht nur p).
- `common_mistakes` (2–4) mit Regex und Begründung, WARUM es falsch ist.
- Nur Pakete aus dem webR-Index; sonst Abschnitt „Lokal ausführen“ statt Übung.
- Browser-tauglich: Laufzeit klein (Simulationen 50–100 Wiederholungen), Daten KB bis wenige MB.

## Abschluss je Übung
1. Generator validiert ohne Fehler.
2. Selbsttest: Lösung besteht, Starter scheitert (`Rscript tools/selftest.R`).
3. Dann `rtrainer-verifier`.

## Alte Aufgaben (Tag `v0-shiny`, `inst/exercises/`)
Bei der Triage je Aufgabe: behalten (in welche Lektion, was anpassen) oder streichen (Grund). Liste Nick zur Freigabe vorlegen, nichts ungefragt migrieren.
