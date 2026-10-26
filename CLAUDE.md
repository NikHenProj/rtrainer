# rtrainer

Zweisprachiger R-Kurs (DE/EN) als Quarto-Website mit quarto-live/webR: Lektionen (erst erklären, dann üben) + Leitner-Wiederholung im Browser. Öffentlich auf GitHub Pages (`NikHenProj/rtrainer`).
Kurstexte Deutsch und Englisch; Code, Kommentare, Funktionsnamen, Datenspalten Englisch.
Spezifikation: docs/SPEC.md – NICHT komplett lesen, nur den relevanten Abschnitt (`grep -n "^## " docs/SPEC.md`).
Aktueller Stand und nächster Schritt: STATUS.md (zuerst lesen).
Alter Stand (Shiny-App als R-Paket): Tag `v0-shiny`, nicht weiterpflegen.

## Zielperson
Nick, Human-Factors-/UX-Forscher, Linux, R-Praxis (Tidyverse, lme4, ggplot2). Kurs reicht aber von Beginner bis Expert. Kompakte, praxisnahe Inhalte, echte Werkzeuge an realistischen Daten, keine Nachbauten von Basisfunktionen.

## Feste Entscheidungen (Grilling 2026-10-26, nicht neu diskutieren)
- Quarto-Website + quarto-live/webR, online, Pakete pro Lektion; nicht Lauffähiges im Browser → Kasten „Lokal ausführen“.
- Struktur: 23 Themen × Stufen Beginner/Intermediate/Expert; empfohlener Pfad stufenweise, alles frei zugänglich, Voraussetzungen anzeigen.
- Lektion: Forschungsfrage → Konzept → live Beispiel → Paketvergleich → Übungen → Wissenscheck → Spickzettel. Abgeschlossen = Pflichtübungen + Wissenscheck ≥ 80 %.
- Hauptweg tidyverse + easystats; rstatix, afex, modelbased/emmeans, psych, lavaan; Berichtskette bis APA-Text/Tabelle/Word.
- Übungen als YAML (Single Source) → Generator erzeugt Lektionsblöcke und Wiederholungskarten; Selbsttest: Lösung besteht, Starter scheitert.
- Wiederholung: Leitner Boxen 1–5, 0/1/3/7/21 Tage; richtig+leicht +1, okay =, schwer −1, falsch → Box 1; „Leicht“ nur bei < 2 Hinweisen. Sicherheits-Rating nur auf der Wiederholungsseite. Kein Prüfungsmodus.
- Fortschritt in localStorage, Export/Import als Datei.
- DE und EN komplett (`/de/`, `/en/`), gleiche Übungs-IDs; Deutsch zuerst, nach Abnahme Englisch.
- Daten simuliert, englische Spaltennamen/Faktorstufen.
- Optik: Swiss/minimal, IBM Plex Sans + JetBrains Mono, eine Akzentfarbe, Hell/Dunkel, WCAG AA, keine Gamification außer dezentem Fortschritt/Streak.

## Skills und Agenten
UX: `cognitive-accessibility:wayfinding-navigation`, `ui-ux-pro-max:ui-ux-pro-max`, `frontend-design`. Projekt: `rtrainer-write-exercise`, `rtrainer-verify`; Subagent `rtrainer-verifier` (günstig, liefert nur Kurzbericht). Stil: `r-tidyverse-style`.
Bei Konflikt gilt: projektspezifische Regeln vor allgemeinen Skills.

## Token-Disziplin
- Verifikation (Selbsttest, Render, Rauchtest) immer über Subagent `rtrainer-verifier`; Logs nie komplett ausgeben.
- Gezielt lesen: Dateien/Zeilenbereiche nennen statt ganzer Verzeichnisse.
- Eine Sitzung pro Meilenstein bzw. Lektionspaket. Am Ende STATUS.md aktualisieren, Start-Prompt für die nächste Sitzung ausgeben, `/clear` empfehlen.
- Lektionen in Paketen (max. ~3 pro Durchgang) schreiben, danach verifizieren.

## Befehle (ab Meilenstein 6; bis dahin noch nicht vorhanden)
- `quarto preview` – lokale Vorschau
- `Rscript tools/selftest.R` – alle Übungen: Lösung besteht, Starter scheitert
- `Rscript tools/generate.R` – YAML-Übungen → quarto-live-Blöcke/Wiederholungskarten
- `quarto render` – ganze Seite (DE + EN)

## Stil
- R: `|>`, tidyverse-Stil, lintr/styler-konform. JS/CSS: klein, ohne Build-Schritt, Farben als CSS-Variablen.
- Neue Pakete im Kurs nur, wenn im webR-Index vorhanden oder als „Lokal ausführen“ markiert.
- Jede Verhaltensänderung an Generator/Checks/Fortschritt bekommt Tests (richtig, falsch, Randfall).

## Arbeitsweise
- Meilensteine laut SPEC.md; nach jedem: Selbsttest + Render grün, kurze Zusammenfassung, nächster Schritt.
- Nie behaupten, etwas sei grün, ohne es ausgeführt zu haben; echte (gekürzte) Ausgabe zeigen.
- Entscheidungen in NEWS.md notieren; nur bei echter Blockade nachfragen. Push nur nach Rückfrage.
