# Einrichtung (einmalig)

1. Diesen Ordner als Projektwurzel nutzen (`cd rtrainer-project`, `git init`).
2. Claude Code im Ordner starten: `claude`.
3. Externe Skills (Variante A oder B):
   - A (Marketplace): `/plugin marketplace add posit-dev/skills`, dann die Skills r-package-development, r-testthat, r-tidyverse-style, shiny-bslib, create-release-checklist auswählen. Für Anthropic: `/plugin marketplace add anthropics/skills`.
   - B (Ordner kopieren, Claude kann das selbst): Repo klonen und den Skill-Ordner mit der SKILL.md nach `.claude/skills/` kopieren. Vorher SKILL.md lesen (ein Skill ist ein Prompt mit Shell-Zugriff).
4. Werkzeuge: Quarto (>= 1.6), R (>= 4.3) mit `install.packages(c("yaml","testthat","withr","tidyverse","easystats","rstatix"))`; quarto-live per `quarto add r-wasm/quarto-live`. (Stand vor dem Umbau: Tag `v0-shiny`.)
5. Inhalt von KICKOFF_PROMPT.md einfügen.

## Inhalt
- CLAUDE.md – Dauerregeln (kurz), STATUS.md – Stand/Übergabe zwischen Sitzungen
- docs/SPEC.md – vollständige Anforderungen inkl. Lernförderung
- .claude/skills/ – Projekt-Skills rtrainer-write-exercise, rtrainer-verify; .claude/agents/rtrainer-verifier.md – Verifikations-Subagent (Modell: haiku)
- Quarto-Projekt (siehe README.md und SPEC.md „Repository“); alter Paketstand im Tag `v0-shiny`

## Token sparen
`/usage` prüfen, `/clear` zwischen Meilensteinen, `/compact` mit Fokus (Ziel, geänderte Dateien, echte Testergebnisse, nächster Schritt), ungenutzte MCP-Server per `/mcp` abschalten, Sonnet als Standard, Opus nur für Architekturentscheidungen.
