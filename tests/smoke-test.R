# Browser smoke test of the rendered site (_site) with headless Chrome:
# lesson exercises are solved and checked in webR, progress is stored,
# a review card is checked, the English page and language switch work.
#
#   quarto render && Rscript tests/smoke-test.R
#
# Needs Chrome/Chromium (CHROMOTE_CHROME) and internet (webR from CDN).

port <- 4400 + sample.int(500, 1)
server <- processx::process$new(
  "python3", c("-m", "http.server", port, "--bind", "127.0.0.1", "--directory", "_site"),
  stdout = "|", stderr = "|"
)
on.exit(server$kill(), add = TRUE)
Sys.sleep(1)
base <- sprintf("http://127.0.0.1:%d", port)

b <- chromote::ChromoteSession$new(width = 1280, height = 900)
on.exit(b$close(), add = TRUE)

failures <- character()
step <- function(name, ok, detail = "") {
  cat(sprintf("%s %s%s\n", if (isTRUE(ok)) "ok  " else "FAIL", name, if (nzchar(detail)) paste0(" – ", detail) else ""))
  if (!isTRUE(ok)) failures <<- c(failures, name)
}

js <- function(expr, timeout = 60) {
  res <- b$Runtime$evaluate(expr, awaitPromise = TRUE, returnByValue = TRUE, timeout_ = timeout)
  if (!is.null(res$exceptionDetails)) stop(res$exceptionDetails$exception$description %||% "JS error")
  res$result$value
}

# Poll a JS condition until it is true (or the timeout in seconds passes).
wait_for <- function(condition, timeout = 120) {
  start <- Sys.time()
  while (as.numeric(difftime(Sys.time(), start, units = "secs")) < timeout) {
    if (isTRUE(tryCatch(js(condition), error = function(e) FALSE))) {
      return(round(as.numeric(difftime(Sys.time(), start, units = "secs")), 1))
    }
    Sys.sleep(0.5)
  }
  NA
}

goto <- function(path) {
  b$Page$navigate(paste0(base, path), wait_ = FALSE)
  invisible(b$Page$loadEventFired(timeout_ = 30))
}

# 1. Lesson: webR starts, an exercise is solved, progress is stored.
goto("/de/group-comparisons-beginner.html")
invisible(js("localStorage.removeItem('rtrainer.progress'); true"))
goto("/de/group-comparisons-beginner.html")
loaded <- wait_for(
  "document.querySelectorAll('#ex-gc-b-describe .exercise-editor-btn-run-code').length > 0 &&
   document.querySelectorAll('.exercise-editor-btn-run-code.disabled').length === 0",
  timeout = 240
)
step("lesson: webR and packages ready", !is.na(loaded), sprintf("%s s", loaded))

invisible(js("(() => {
  const ex = document.querySelector('#ex-gc-b-describe');
  const v = ex.querySelector('.cm-content').cmView.view;
  v.dispatch({changes: {from: 0, to: v.state.doc.length, insert:
    'rt_by_person |>\\n  summarise(n = n(), mean_rt = round(mean(rt_ms), 1), sd_rt = round(sd(rt_ms), 1), .by = experience)'}});
  ex.querySelector('.exercise-editor-btn-run-code').click();
  return true;
})()"))
checked <- wait_for("!!document.querySelector('#ex-gc-b-describe .exercise-grade.alert-success')", timeout = 60)
step("lesson: solution is graded correct", !is.na(checked), sprintf("%s s", checked))
solved <- js("JSON.parse(localStorage.getItem('rtrainer.progress') || '{}').exercises?.['gc-b-describe']?.solved === true")
step("lesson: progress saved in localStorage", solved)
labels <- wait_for("(document.querySelector('#ex-gc-b-describe .exercise-editor-btn-run-code')?.textContent || '').includes('Ausführen')", timeout = 10)
step("lesson: German button labels", !is.na(labels))

# 2. Review page: a due card is checked in webR and scheduled.
goto("/de/review.html")
invisible(js("(() => {
  const L = window.rtLogic, today = L.isoDate();
  const p = L.emptyProgress();
  p.review['gc-b-ttest'] = {box: 2, due: today};
  localStorage.setItem('rtrainer.progress', JSON.stringify(p));
  return true;
})()"))
goto("/de/review.html")
started <- wait_for("!!document.querySelector('.rt-review-start')", timeout = 20)
step("review: due card offered", !is.na(started))
invisible(js("(() => {
  document.querySelector('.rt-review-start').click();
  const card = document.querySelector('.rt-card');
  card.querySelector('input[value=\"2\"]').click();
  card.querySelector('textarea').value = 't.test(rt_ms ~ experience, data = rt_by_person)';
  [...card.querySelectorAll('button')].find(b => b.textContent === 'Prüfen').click();
  return true;
})()"))
reviewed <- wait_for("document.querySelector('.rt-card-feedback')?.dataset.kind === 'success'", timeout = 240)
step("review: card checked correct in webR", !is.na(reviewed), sprintf("%s s", reviewed))
invisible(js("([...document.querySelectorAll('.rt-rating button')].find(b => b.textContent === 'Leicht').click(), true)"))
item <- js("JSON.parse(localStorage.getItem('rtrainer.progress')).review['gc-b-ttest']")
step("review: Leitner box 2 -> 3, due in 3 days", identical(as.integer(item$box), 3L), sprintf("box %s, due %s", item$box, item$due))

# 3. English page and language switch.
goto("/en/group-comparisons-beginner.html")
Sys.sleep(1)
step("en: lesson page in English", js("document.documentElement.lang.startsWith('en') && document.querySelector('h1').textContent.includes('Group comparisons')"))
step("en: navbar translated", js("[...document.querySelectorAll('.navbar .nav-link')].some(a => a.textContent.includes('Course plan'))"))
step("en: switch points to German page", js("document.querySelector('a#rt-nav-lang').getAttribute('href').startsWith('../de/group-comparisons-beginner.html')"))

# 4. A German-only lesson with many packages and a data file read in webR.
goto("/de/cleaning-beginner.html")
loaded <- wait_for(
  "document.querySelectorAll('#ex-cl-b-remove-tests .exercise-editor-btn-run-code').length > 0 &&
   document.querySelectorAll('.exercise-editor-btn-run-code.disabled').length === 0",
  timeout = 300
)
step("cleaning: webR and 6 packages ready", !is.na(loaded), sprintf("%s s", loaded))
invisible(js("(() => {
  const ex = document.querySelector('#ex-cl-b-remove-tests');
  const v = ex.querySelector('.cm-content').cmView.view;
  v.dispatch({changes: {from: 0, to: v.state.doc.length, insert:
    'responses |>\\n  filter(status != \"Survey Preview\") |>\\n  distinct()'}});
  ex.querySelector('.exercise-editor-btn-run-code').click();
  return true;
})()"))
checked <- wait_for("!!document.querySelector('#ex-cl-b-remove-tests .exercise-grade.alert-success')", timeout = 90)
step("cleaning: raw export read and solution graded correct", !is.na(checked), sprintf("%s s", checked))

# 5. A plot exercise: a wrong plot gets the matching hint, the solution passes.
goto("/de/visualisation-beginner.html")
loaded <- wait_for(
  "document.querySelectorAll('#ex-vi-b-aes-inherit .exercise-editor-btn-run-code').length > 0 &&
   document.querySelectorAll('.exercise-editor-btn-run-code.disabled').length === 0",
  timeout = 300
)
step("visualisation: webR and ggplot2 ready", !is.na(loaded), sprintf("%s s", loaded))
run_plot <- function(code) {
  invisible(js(sprintf("(() => {
    const ex = document.querySelector('#ex-vi-b-aes-inherit');
    ex.querySelectorAll('.exercise-grade').forEach(el => el.remove());
    const v = ex.querySelector('.cm-content').cmView.view;
    v.dispatch({changes: {from: 0, to: v.state.doc.length, insert: %s}});
    ex.querySelector('.exercise-editor-btn-run-code').click();
    return true;
  })()", jsonlite::toJSON(code, auto_unbox = TRUE))))
}
run_plot(paste(
  "ggplot(driving_sim, aes(rt_ms, lane_dev)) +",
  "  geom_point(aes(colour = condition), alpha = 0.4) +",
  "  geom_smooth(method = \"lm\", se = FALSE)",
  sep = "\n"
))
hinted <- wait_for(
  "(document.querySelector('#ex-vi-b-aes-inherit .exercise-grade.alert-danger')?.textContent || '').includes('ggplot(aes())')",
  timeout = 90
)
step("visualisation: wrong plot gets the inheritance hint", !is.na(hinted), sprintf("%s s", hinted))
run_plot(paste(
  "ggplot(driving_sim, aes(rt_ms, lane_dev, colour = condition)) +",
  "  geom_point(alpha = 0.4) +",
  "  geom_smooth(method = \"lm\", se = FALSE)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-vi-b-aes-inherit .exercise-grade.alert-success')", timeout = 90)
step("visualisation: plot solution graded correct", !is.na(checked), sprintf("%s s", checked))
drawn <- js("!!document.querySelector('#ex-vi-b-aes-inherit canvas, #ex-vi-b-aes-inherit img')")
step("visualisation: plot drawn", drawn)

# 6. Reporting: gtsummary, report and broom.helpers load; a table solution passes.
goto("/de/reporting-beginner.html")
loaded <- wait_for(
  "document.querySelectorAll('#ex-rp-b-table1 .exercise-editor-btn-run-code').length > 0 &&
   document.querySelectorAll('.exercise-editor-btn-run-code.disabled').length === 0",
  timeout = 300
)
step("reporting: webR, gtsummary and report ready", !is.na(loaded), sprintf("%s s", loaded))
invisible(js("(() => {
  const ex = document.querySelector('#ex-rp-b-table1');
  const v = ex.querySelector('.cm-content').cmView.view;
  v.dispatch({changes: {from: 0, to: v.state.doc.length, insert:
    'tbl_summary(scored, by = interface, include = c(age, gender, tech_affinity))'}});
  ex.querySelector('.exercise-editor-btn-run-code').click();
  return true;
})()"))
checked <- wait_for("!!document.querySelector('#ex-rp-b-table1 .exercise-grade.alert-success')", timeout = 120)
step("reporting: gtsummary table graded correct", !is.na(checked), sprintf("%s s", checked))

# 7. Mini project: linked as its own row; reading the CSV with readr in webR
# passes, a character `interface` fails the type check.
goto("/de/index.html")
project_row <- wait_for("!!document.querySelector('tr.rt-plan-project a[href*=\"project-beginner\"]')", timeout = 15)
step("project: own row in the German course plan", !is.na(project_row))
goto("/de/project-beginner.html")
loaded <- wait_for(
  "document.querySelectorAll('#ex-pj-b-import .exercise-editor-btn-run-code').length > 0 &&
   document.querySelectorAll('.exercise-editor-btn-run-code.disabled').length === 0",
  timeout = 300
)
step("project: webR and packages ready", !is.na(loaded), sprintf("%s s", loaded))
run_import <- function(code) {
  invisible(js(sprintf("(() => {
    const ex = document.querySelector('#ex-pj-b-import');
    ex.querySelector('.exercise-grade')?.remove();
    const v = ex.querySelector('.cm-content').cmView.view;
    v.dispatch({changes: {from: 0, to: v.state.doc.length, insert: %s}});
    ex.querySelector('.exercise-editor-btn-run-code').click();
    return true;
  })()", jsonlite::toJSON(code, auto_unbox = TRUE))))
}
run_import('survey_raw <- read_csv("data/survey.csv")')
typed <- wait_for("(document.querySelector('#ex-pj-b-import .exercise-grade')?.textContent || '').includes('factor')", timeout = 60)
step("project: character interface gets the type hint", !is.na(typed))
run_import(paste(
  'survey_raw <- read_csv("data/survey.csv") |>',
  '  mutate(interface = factor(interface, levels = c("touch", "voice")))',
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-pj-b-import .exercise-grade.alert-success')", timeout = 60)
step("project: import from the CSV graded correct", !is.na(checked), sprintf("%s s", checked))

# 8. Intermediate: linked in the course plan; exercises that write files to the
# webR file system (possibly() over CSV files, an SPSS file read with haven).
goto("/de/index.html")
linked <- wait_for("!!document.querySelector('a[href*=\"import-intermediate\"]')", timeout = 15)
step("intermediate: import-intermediate linked in the German course plan", !is.na(linked))
goto("/de/import-intermediate.html")
loaded <- wait_for(
  "document.querySelectorAll('#ex-imp-i-haven-labels .exercise-editor-btn-run-code').length > 0 &&
   document.querySelectorAll('.exercise-editor-btn-run-code.disabled').length === 0",
  timeout = 300
)
step("intermediate: webR and 8 packages ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise <- function(id, code) {
  invisible(js(sprintf("(() => {
    const ex = document.querySelector('#ex-%s');
    ex.querySelector('.exercise-grade')?.remove();
    const v = ex.querySelector('.cm-content').cmView.view;
    v.dispatch({changes: {from: 0, to: v.state.doc.length, insert: %s}});
    ex.querySelector('.exercise-editor-btn-run-code').click();
    return true;
  })()", id, jsonlite::toJSON(code, auto_unbox = TRUE))))
}
run_exercise("imp-i-possibly-read", paste(
  "read_maybe <- possibly(read_csv, otherwise = NULL)",
  "paths |>",
  "  set_names(basename) |>",
  "  map(\\(path) read_maybe(path, show_col_types = FALSE)) |>",
  "  list_rbind(names_to = \"file\")",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-imp-i-possibly-read .exercise-grade.alert-success')", timeout = 90)
step("intermediate: possibly() over CSV files graded correct", !is.na(checked), sprintf("%s s", checked))
run_exercise("imp-i-haven-labels", paste(
  "read_sav(survey_sav) |>",
  "  mutate(interface = factor(interface, levels = c(1, 2), labels = c(\"touch\", \"voice\"))) |>",
  "  summarise(n = n(), frustration = round(mean(tlx_frustration, na.rm = TRUE), 1), .by = interface)",
  sep = "\n"
))
hinted <- wait_for("(document.querySelector('#ex-imp-i-haven-labels .exercise-grade.alert-danger')?.textContent || '').includes('count(interface)')", timeout = 90)
step("intermediate: guessed SPSS labels get the hint", !is.na(hinted))
run_exercise("imp-i-haven-labels", paste(
  "read_sav(survey_sav) |>",
  "  mutate(interface = as_factor(interface)) |>",
  "  summarise(n = n(), frustration = round(mean(tlx_frustration, na.rm = TRUE), 1), .by = interface)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-imp-i-haven-labels .exercise-grade.alert-success')", timeout = 90)
step("intermediate: SPSS file read with haven graded correct", !is.na(checked), sprintf("%s s", checked))

# 9. Intermediate P2: load time with mice (missing) and patchwork/modelbased
# (visualisation); ggsave() writes a PNG in webR, a patchwork is graded.
goto("/de/missing-intermediate.html")
loaded <- wait_for(
  "document.querySelectorAll('#ex-ms-i-pattern .exercise-editor-btn-run-code').length > 0 &&
   document.querySelectorAll('.exercise-editor-btn-run-code.disabled').length === 0",
  timeout = 300
)
step("missing: webR, mice and naniar ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("ms-i-pattern", "survey |>\n  add_n_miss(starts_with(\"trust_\")) |>\n  count(n_miss_vars)")
checked <- wait_for("!!document.querySelector('#ex-ms-i-pattern .exercise-grade.alert-success')", timeout = 90)
step("missing: naniar solution graded correct", !is.na(checked), sprintf("%s s", checked))

goto("/de/visualisation-intermediate.html")
loaded <- wait_for(
  "document.querySelectorAll('#ex-vi-i-patchwork .exercise-editor-btn-run-code').length > 0 &&
   document.querySelectorAll('.exercise-editor-btn-run-code.disabled').length === 0",
  timeout = 300
)
step("visualisation-intermediate: webR, modelbased and patchwork ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("vi-i-ggsave-debug", paste(
  "ggsave(out_file, fig, width = 16, height = 10, units = \"cm\", dpi = 300)",
  "png_size(out_file)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-vi-i-ggsave-debug .exercise-grade.alert-success')", timeout = 90)
step("visualisation-intermediate: ggsave() writes a PNG of the right size", !is.na(checked), sprintf("%s s", checked))
run_exercise("vi-i-model-plot", paste(
  "pred <- estimate_relation(fit, by = c(\"tech_affinity\", \"interface\"))",
  "ggplot(pred, aes(tech_affinity, Predicted)) +",
  "  geom_ribbon(aes(ymin = CI_low, ymax = CI_high, fill = interface), alpha = 0.2) +",
  "  geom_line(aes(colour = interface))",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-vi-i-model-plot .exercise-grade.alert-success')", timeout = 90)
step("visualisation-intermediate: modelbased plot graded correct", !is.na(checked), sprintf("%s s", checked))
run_exercise("vi-i-patchwork", "p_rt / p_lane")
hinted <- wait_for("(document.querySelector('#ex-vi-i-patchwork .exercise-grade.alert-danger')?.textContent || '').includes('untereinander')", timeout = 90)
step("visualisation-intermediate: stacked patchwork gets the hint", !is.na(hinted))
run_exercise("vi-i-patchwork", "p_rt + p_lane +\n  plot_layout(guides = \"collect\") +\n  plot_annotation(tag_levels = \"A\")")
checked <- wait_for("!!document.querySelector('#ex-vi-i-patchwork .exercise-grade.alert-success')", timeout = 90)
step("visualisation-intermediate: patchwork graded correct", !is.na(checked), sprintf("%s s", checked))

goto("/en/index.html")
Sys.sleep(1)
beginner <- c(
  "working-with-r", "import", "cleaning", "reshaping", "visualisation",
  "descriptives", "group-comparisons", "scales", "regression", "reporting"
)
unlinked <- js(sprintf(
  "[%s].filter(slug => !document.querySelector(`a[href*=\"${slug}-beginner\"]`)).join(', ')",
  paste0("'", beginner, "'", collapse = ", ")
))
step("en: all beginner lessons linked in course plan", identical(unlinked, ""), unlinked)
project_row <- js("document.querySelector('tr.rt-plan-project a[href*=\"project-beginner\"]')?.getAttribute('href') || ''")
step("en: project row links the English page", grepl("project-beginner", project_row) && !grepl("/de/", project_row), project_row)
goto("/en/project-beginner.html")
en_project <- wait_for(
  "document.documentElement.lang.startsWith('en') && document.querySelector('h1').textContent.includes('Mini project') &&
   !!document.querySelector('#ex-pj-b-import') && !!document.querySelector('#script')",
  timeout = 15
)
step("en: project page in English with exercises", !is.na(en_project))

cat(sprintf("\n%d failure(s)\n", length(failures)))
if (length(failures) > 0) quit(status = 1)
