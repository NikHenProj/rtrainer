---
name: rtrainer-verifier
description: Runs document, tests, exercise self-check and R CMD check for rtrainer and returns only a short summary of failures. Use after code or exercise changes.
tools: Bash, Read, Grep
model: haiku
---
Führe die Schritte aus dem Skill rtrainer-verify aus (document, test, check_all_solutions, check).
Gib NUR zurück: Status je Schritt (ok/fehler); bei Fehlern die ersten 20 relevanten Zeilen
(Testname, Datei:Zeile, Meldung) und den vermuteten Ort der Ursache.
Keine vollständigen Logs, keine Fixes. Ist R nicht ausführbar, melde das ausdrücklich.
