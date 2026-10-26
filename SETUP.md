# Einrichtung (einmalig)

1. Diesen Ordner als Projektwurzel nutzen (`cd rtrainer-project`, `git init`).
2. Claude Code im Ordner starten: `claude`.
3. Externe Skills (Variante A oder B):
   - A (Marketplace): `/plugin marketplace add posit-dev/skills`, dann die Skills r-package-development, r-testthat, r-tidyverse-style, shiny-bslib, create-release-checklist auswählen. Für Anthropic: `/plugin marketplace add anthropics/skills`.
   - B (Ordner kopieren, Claude kann das selbst): Repo klonen und den Skill-Ordner mit der SKILL.md nach `.claude/skills/` kopieren. Vorher SKILL.md lesen (ein Skill ist ein Prompt mit Shell-Zugriff).
4. R-Abhängigkeiten: `install.packages(c("devtools","testthat","withr","lintr","styler","shinytest2","knitr","rmarkdown"))`, dann `devtools::install_deps(dependencies = TRUE)`.
5. Inhalt von KICKOFF_PROMPT.md einfügen.

## Inhalt
- CLAUDE.md – Dauerregeln (kurz), STATUS.md – Stand/Übergabe zwischen Sitzungen
- docs/SPEC.md – vollständige Anforderungen inkl. Lernförderung
- .claude/skills/ – drei Projekt-Skills; .claude/agents/rtrainer-verifier.md – Verifikations-Subagent (Modell: haiku)
- DESCRIPTION, R/, tests/, inst/ – Paketstand (nicht in R ausgeführt)

## Token sparen
`/usage` prüfen, `/clear` zwischen Meilensteinen, `/compact` mit Fokus (Ziel, geänderte Dateien, echte Testergebnisse, nächster Schritt), ungenutzte MCP-Server per `/mcp` abschalten, Sonnet als Standard, Opus nur für Architekturentscheidungen.
