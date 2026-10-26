Lies CLAUDE.md und STATUS.md. Details stehen in docs/SPEC.md – lies nur die Abschnitte, die du für den aktuellen Schritt brauchst.

Token-Disziplin: Verifikation immer über den Subagenten rtrainer-verifier, keine vollständigen Logs. Pro Meilenstein bzw. Aufgaben-Thema eine Sitzung: am Ende STATUS.md aktualisieren (Stand, Entscheidungen, nächster Schritt) und mir `/clear` empfehlen.

Schritt 0 (nur falls Skills fehlen): Prüfe `.claude/skills/` und `~/.claude/skills/`. Für fehlende externe Skills (r-package-development, r-testthat, shiny-bslib, r-tidyverse-style, create-release-checklist, webapp-testing, skill-creator) schlage die Installation vor (Marketplace oder git clone + cp -r nach .claude/skills/). Fasse vorher den Inhalt der jeweiligen SKILL.md kurz zusammen und warte auf meine Freigabe. Ohne Freigabe arbeite mit den Projektregeln weiter.

Vorgehen:
1. Bringe den bestehenden Stand zum Laufen (rtrainer-verifier, r-testthat). Prüfe gezielt die "Bekannten Risiken" in SPEC.md. Berichte Fixes und gekürzte Testausgabe.
2. Meilenstein 3: Shiny-App, start(), Modi daily/exam, Dashboard, inkl. der UI-Punkte aus "Lernförderung" (shiny-bslib, rtrainer-shiny-app; Browser-Test mit webapp-testing oder shinytest2).
3. Meilenstein 4: 60+ Aufgaben themenweise (rtrainer-write-exercise), nach jedem Thema rtrainer-verifier und neue Sitzung.
4. Meilenstein 5: export_learnr, Vignetten, README, GitHub Actions (r-package-development), Review mit r-tidyverse-style, create-release-checklist.

Stoppe nach jedem Meilenstein mit Zusammenfassung (Entscheidungen, Testausgabe, Lücken, nächster Schritt). Frage nur bei echten Blockaden. Behaupte nie grüne Tests ohne Ausführung.
