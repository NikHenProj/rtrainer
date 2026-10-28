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

# 10. Intermediate P3: load time with psych (scales), lavaan (sem) and
# afex/emmeans (group comparisons); lavaan and afex models are graded via
# parameters::model_parameters() in webR.
wait_lesson <- function(path, id) {
  goto(path)
  wait_for(sprintf(
    "document.querySelectorAll('#ex-%s .exercise-editor-btn-run-code').length > 0 &&
     document.querySelectorAll('.exercise-editor-btn-run-code.disabled').length === 0",
    id
  ), timeout = 300)
}
loaded <- wait_lesson("/de/scales-intermediate.html", "sc-i-efa")
step("scales-intermediate: webR, psych and GPArotation ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("sc-i-efa", paste(
  "items <- select(acceptance, pu_1:bi_4)",
  "efa <- fa(items, nfactors = 4, rotate = \"oblimin\", fm = \"ml\")",
  "model_parameters(efa, threshold = \"max\") |>",
  "  pivot_longer(starts_with(\"ML\"), names_to = \"factor\", values_to = \"loading\", values_drop_na = TRUE) |>",
  "  select(item = Variable, loading) |>",
  "  mutate(loading = round(loading, 2))",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-sc-i-efa .exercise-grade.alert-success')", timeout = 90)
step("scales-intermediate: EFA solution graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/sem-intermediate.html", "sm-i-cfa")
step("sem-intermediate: webR, lavaan and semTools ready", !is.na(loaded), sprintf("%s s", loaded))
cfa_code <- function(factors) {
  lines <- c(
    pu = "pu =~ pu_1 + pu_2 + pu_3 + pu_4 + pu_5",
    peou = "peou =~ peou_1 + peou_2 + peou_3 + peou_4",
    trust = "trust =~ trust_1 + trust_2 + trust_3 + trust_4 + trust_5",
    bi = "bi =~ bi_1 + bi_2 + bi_3 + bi_4"
  )
  paste0("model <- \"\n", paste(lines[factors], collapse = "\n"), "\n\"\nfit <- cfa(model, data = acceptance)\nfit")
}
run_exercise("sm-i-cfa", cfa_code(c("pu", "peou", "trust")))
hinted <- wait_for("(document.querySelector('#ex-sm-i-cfa .exercise-grade.alert-danger')?.textContent || '').includes('bi =~ bi_1')", timeout = 90)
step("sem-intermediate: model without bi names the missing loadings", !is.na(hinted))
run_exercise("sm-i-cfa", cfa_code(c("pu", "peou", "trust", "bi")))
checked <- wait_for("!!document.querySelector('#ex-sm-i-cfa .exercise-grade.alert-success')", timeout = 90)
step("sem-intermediate: lavaan model graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/group-comparisons-intermediate.html", "gc-i-rm-anova")
step("group-comparisons-intermediate: webR, afex, emmeans and modelbased ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("gc-i-rm-anova", paste(
  "fit <- aov_ez(",
  "  id = \"participant\", dv = \"rt_ms\", data = driving_sim,",
  "  within = \"condition\", between = \"experience\", fun_aggregate = mean",
  ")",
  "fit",
  sep = "\n"
))
hinted <- wait_for("(document.querySelector('#ex-gc-i-rm-anova .exercise-grade.alert-danger')?.textContent || '').includes('na.rm')", timeout = 90)
step("group-comparisons-intermediate: missing na.rm gets the hint", !is.na(hinted))
run_exercise("gc-i-rm-anova", paste(
  "fit <- aov_ez(",
  "  id = \"participant\", dv = \"rt_ms\", data = driving_sim,",
  "  within = \"condition\", between = \"experience\",",
  "  fun_aggregate = mean, na.rm = TRUE",
  ")",
  "fit",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-gc-i-rm-anova .exercise-grade.alert-success')", timeout = 90)
step("group-comparisons-intermediate: afex ANOVA graded correct", !is.na(checked), sprintf("%s s", checked))

# 11. Intermediate P4: load time with rstatix/WRS2 (robust), modelbased
# (regression) and marginaleffects/sandwich (glm); a WRS2 result, an lm
# interaction and cluster-robust marginal effects are graded in webR.
loaded <- wait_lesson("/de/robust-intermediate.html", "rb-i-yuen")
step("robust-intermediate: webR, coin, rstatix, effectsize and WRS2 ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("rb-i-yuen", paste(
  "fit <- yuen(tlx_physical ~ interface, data = survey)",
  "round(c(diff = fit$diff, ci_low = fit$conf.int[1], ci_high = fit$conf.int[2], p = fit$p.value), 3)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-rb-i-yuen .exercise-grade.alert-success')", timeout = 90)
step("robust-intermediate: Yuen test graded correct", !is.na(checked), sprintf("%s s", checked))
# wilcox_effsize() needs coin; coin is attached before rstatix so that
# rstatix's wilcox_test() is not masked by coin's.
run_exercise("rb-i-mann-whitney", paste(
  "per_person <- driving_sim |>",
  "  filter(gender %in% c(\"female\", \"male\")) |>",
  "  summarise(lane = mean(lane_dev, na.rm = TRUE), .by = c(participant, gender))",
  "res <- per_person |> wilcox_test(lane ~ gender)",
  "eff <- per_person |> wilcox_effsize(lane ~ gender)",
  "round(c(W = res$statistic[[1]], p = res$p, r = eff$effsize[[1]]), 3)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-rb-i-mann-whitney .exercise-grade.alert-success')", timeout = 90)
step("robust-intermediate: rstatix wilcox_effsize() (coin) graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/regression-intermediate.html", "rg-i-interaction")
step("regression-intermediate: webR, parameters, performance and modelbased ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("rg-i-interaction", paste(
  "tam_c <- tam |> mutate(pu_c = pu - mean(pu), exp_c = experience - mean(experience))",
  "fit <- lm(bi ~ pu_c * exp_c, data = tam_c)",
  "model_parameters(fit)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-rg-i-interaction .exercise-grade.alert-success')", timeout = 90)
step("regression-intermediate: centred interaction graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/glm-intermediate.html", "gl-i-comparisons")
step("glm-intermediate: webR, marginaleffects and sandwich ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("gl-i-comparisons", "avg_comparisons(fit, variables = \"prototype\")")
hinted <- wait_for("(document.querySelector('#ex-gl-i-comparisons .exercise-grade.alert-danger')?.textContent || '').includes('vcov')", timeout = 90)
step("glm-intermediate: missing vcov gets the hint", !is.na(hinted))
run_exercise("gl-i-comparisons", "avg_comparisons(fit, variables = \"prototype\", vcov = ~participant)")
checked <- wait_for("!!document.querySelector('#ex-gl-i-comparisons .exercise-grade.alert-success')", timeout = 90)
step("glm-intermediate: cluster-robust comparisons graded correct", !is.na(checked), sprintf("%s s", checked))

# 12. Intermediate P5: load time with lme4/lmerTest (mixed models),
# interactions/lavaan (moderation-mediation) and pwr/Superpower/simr (power);
# crossed random effects, a Johnson-Neyman interval, a lavaan mediation
# model, a Superpower design and a simr simulation are graded in webR.
loaded <- wait_lesson("/de/mixed-models-intermediate.html", "mm-i-crossed-icc")
step("mixed-models-intermediate: webR, lme4, lmerTest and performance ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("mm-i-crossed-icc", paste(
  "fit <- lmer(log(time_s) ~ prototype + (1 | participant/task), data = usability)",
  "icc(fit, by_group = TRUE)",
  sep = "\n"
))
hinted <- wait_for("(document.querySelector('#ex-mm-i-crossed-icc .exercise-grade.alert-danger')?.textContent || '').includes('(1 | task)')", timeout = 90)
step("mixed-models-intermediate: nested instead of crossed gets the hint", !is.na(hinted))
run_exercise("mm-i-crossed-icc", paste(
  "fit <- lmer(log(time_s) ~ prototype + (1 | participant) + (1 | task), data = usability)",
  "icc(fit, by_group = TRUE)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-mm-i-crossed-icc .exercise-grade.alert-success')", timeout = 90)
step("mixed-models-intermediate: crossed random effects graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/moderation-mediation-intermediate.html", "mo-i-mediation")
step("moderation-mediation-intermediate: webR, interactions and lavaan ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("mo-i-johnson-neyman", paste(
  "fit <- lm(bi ~ pu * experience, data = tam)",
  "jn <- johnson_neyman(fit, pred = pu, modx = experience)",
  "round(jn$bounds, 2)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-mo-i-johnson-neyman .exercise-grade.alert-success')", timeout = 90)
step("moderation-mediation-intermediate: Johnson-Neyman bounds graded correct", !is.na(checked), sprintf("%s s", checked))
run_exercise("mo-i-mediation", paste(
  "model <- \"",
  "  pu ~ a * peou",
  "  bi ~ b * pu + c * peou",
  "  indirect := a * b",
  "  total := c + a * b",
  "\"",
  "fit <- sem(model, data = tam)",
  "fit",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-mo-i-mediation .exercise-grade.alert-success')", timeout = 90)
step("moderation-mediation-intermediate: lavaan mediation model graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/power-intermediate.html", "pw-i-simr")
step("power-intermediate: webR, pwr, Superpower and simr ready", !is.na(loaded), sprintf("%s s", loaded))
superpower_code <- function(r) paste(
  "design <- ANOVA_design(",
  sprintf("  design = \"3w\", n = 20, mu = c(1000, 960, 940), sd = 140,%s", r),
  "  plot = FALSE",
  ")",
  "result <- ANOVA_exact(design, verbose = FALSE)",
  "round(result$main_results$power, 1)",
  sep = "\n"
)
run_exercise("pw-i-superpower", superpower_code(""))
hinted <- wait_for("(document.querySelector('#ex-pw-i-superpower .exercise-grade.alert-danger')?.textContent || '').includes('r = 0')", timeout = 90)
step("power-intermediate: Superpower design without r gets the hint", !is.na(hinted))
run_exercise("pw-i-superpower", superpower_code(" r = 0.85,"))
checked <- wait_for("!!document.querySelector('#ex-pw-i-superpower .exercise-grade.alert-success')", timeout = 90)
step("power-intermediate: Superpower power graded correct", !is.na(checked), sprintf("%s s", checked))
run_exercise("pw-i-simr", paste(
  "fit <- lmer(rt_ms ~ condition + trial_c + (1 + trial_c | participant), data = sim)",
  "fixef(fit)[\"trial_c\"] <- -15",
  "fit60 <- extend(fit, along = \"participant\", n = 60)",
  "set.seed(42)",
  "ps <- powerSim(fit60, test = fixed(\"trial_c\", \"z\"), nsim = 50, progress = FALSE)",
  "summary(ps)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-pw-i-simr .exercise-grade.alert-success')", timeout = 240)
step("power-intermediate: simr powerSim() graded correct", !is.na(checked), sprintf("%s s", checked))

# 13. Intermediate P6: load time with modelsummary/rempsyc/flextable
# (reporting), here/jsonlite (reproducibility) and purrr/parameters
# (programming); a modelsummary table, an APA table object, here paths in
# the webR file system and one model per participant are graded in webR.
loaded <- wait_lesson("/de/reporting-intermediate.html", "rp-i-nice-table")
step("reporting-intermediate: webR, modelsummary, rempsyc and flextable ready", !is.na(loaded), sprintf("%s s", loaded))
modelsummary_code <- function(named) paste(
  "m1 <- lm(bi ~ pu + peou, data = tam)",
  "m2 <- lm(bi ~ pu + peou + trust, data = tam)",
  sprintf("modelsummary(list(%s), statistic = \"conf.int\",", if (named) "\"Model 1\" = m1, \"Model 2\" = m2" else "m1, m2"),
  "  gof_map = c(\"nobs\", \"r.squared\"), output = \"data.frame\")",
  sep = "\n"
)
run_exercise("rp-i-modelsummary", modelsummary_code(FALSE))
hinted <- wait_for("(document.querySelector('#ex-rp-i-modelsummary .exercise-grade.alert-danger')?.textContent || '').includes('Model 1')", timeout = 90)
step("reporting-intermediate: unnamed models get the hint", !is.na(hinted))
run_exercise("rp-i-modelsummary", modelsummary_code(TRUE))
checked <- wait_for("!!document.querySelector('#ex-rp-i-modelsummary .exercise-grade.alert-success')", timeout = 90)
step("reporting-intermediate: modelsummary table graded correct", !is.na(checked), sprintf("%s s", checked))
run_exercise("rp-i-nice-table", paste(
  "tab <- model_parameters(m2) |>",
  "  as.data.frame() |>",
  "  select(Term = Parameter, b = Coefficient, CI_lower = CI_low, CI_upper = CI_high, t, p)",
  "nice_table(tab)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-rp-i-nice-table .exercise-grade.alert-success')", timeout = 90)
step("reporting-intermediate: rempsyc table object graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/reproducibility-intermediate.html", "rr-i-here-project")
step("reproducibility-intermediate: webR, here and jsonlite ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("rr-i-here-project", paste(
  "here::i_am(\"analysis/01-clean.R\")",
  "raw <- read_csv(here::here(\"data\", \"raw\", \"driving_sim.csv\"), show_col_types = FALSE)",
  "dir.create(here::here(\"output\"), showWarnings = FALSE)",
  "raw |> filter(condition == \"haptic\") |> write_csv(here::here(\"output\", \"haptic.csv\"))",
  "read_csv(here::here(\"output\", \"haptic.csv\"), show_col_types = FALSE)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-rr-i-here-project .exercise-grade.alert-success')", timeout = 90)
step("reproducibility-intermediate: here paths graded correct", !is.na(checked), sprintf("%s s", checked))
run_exercise("rr-i-lockfile", paste(
  "lock <- read_json(.lock_path)",
  "c(R = lock[[\"R\"]][[\"Version\"]], map_chr(lock[[\"Packages\"]], \"Version\"))",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-rr-i-lockfile .exercise-grade.alert-success')", timeout = 90)
step("reproducibility-intermediate: lockfile versions graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/programming-intermediate.html", "pg-i-nest-models")
step("programming-intermediate: webR, purrr and parameters ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("pg-i-map2-debug", "map_dbl(rts, \\(x, cut) round(mean(x > cut, na.rm = TRUE), 3), cut = cutoffs)")
hinted <- wait_for("(document.querySelector('#ex-pg-i-map2-debug .exercise-grade.alert-danger')?.textContent || '').includes('map2_dbl')", timeout = 90)
step("programming-intermediate: map() with extra vector gets the hint", !is.na(hinted))
started <- Sys.time()
run_exercise("pg-i-nest-models", paste(
  "driving_sim |>",
  "  nest(.by = participant) |>",
  "  mutate(",
  "    model = map(data, \\(d) lm(rt_ms ~ condition + trial, data = d)),",
  "    params = map(model, model_parameters),",
  "    n = map_int(model, nobs)",
  "  ) |>",
  "  unnest(params) |>",
  "  filter(Parameter == \"trial\") |>",
  "  select(participant, slope = Coefficient, CI_low, CI_high, n)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-pg-i-nest-models .exercise-grade.alert-success')", timeout = 180)
step("programming-intermediate: one model per participant graded correct", !is.na(checked),
     sprintf("%.1f s", as.numeric(difftime(Sys.time(), started, units = "secs"))))

# 14. Intermediate P7: mini project linked in the course plan; load time with
# readxl/janitor and lme4/lmerTest/emmeans; the Excel export is read in webR,
# pairwise contrasts (hint without Holm, solution) and the figure are graded.
goto("/de/index.html")
Sys.sleep(1)
project_row <- js("document.querySelector('tr.rt-plan-project a[href*=\"project-intermediate\"]')?.getAttribute('href') || ''")
step("project-intermediate: linked in the course plan project row", grepl("project-intermediate", project_row), project_row)
loaded <- wait_lesson("/de/project-intermediate.html", "pj-i-contrasts")
step("project-intermediate: webR, readxl, lme4, lmerTest and emmeans ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("pj-i-import", paste(
  "feedback_raw <- read_excel(raw_export_xlsx, sheet = \"Export\", skip = 3) |>",
  "  clean_names() |>",
  "  filter(!is.na(status))",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-pj-i-import .exercise-grade.alert-success')", timeout = 90)
step("project-intermediate: Excel export read and graded correct", !is.na(checked), sprintf("%s s", checked))
contrasts_code <- function(adjust) paste(
  "prototype_contrasts <- emmeans(fit, ~ prototype, lmer.df = \"satterthwaite\", type = \"response\") |>",
  sprintf("  pairs(reverse = TRUE%s) |>", adjust),
  "  summary(infer = TRUE) |>",
  "  as.data.frame()",
  sep = "\n"
)
run_exercise("pj-i-contrasts", contrasts_code(""))
hinted <- wait_for("(document.querySelector('#ex-pj-i-contrasts .exercise-grade.alert-danger')?.textContent || '').includes('holm')", timeout = 120)
step("project-intermediate: contrasts without Holm get the hint", !is.na(hinted))
run_exercise("pj-i-contrasts", contrasts_code(", adjust = \"holm\""))
checked <- wait_for("!!document.querySelector('#ex-pj-i-contrasts .exercise-grade.alert-success')", timeout = 120)
step("project-intermediate: emmeans contrasts graded correct", !is.na(checked), sprintf("%s s", checked))
run_exercise("pj-i-figure", paste(
  "fig <- ggplot(prototype_contrasts, aes(x = ratio, y = contrast)) +",
  "  geom_vline(xintercept = 1, linetype = \"dashed\") +",
  "  geom_pointrange(aes(xmin = lower.CL, xmax = upper.CL)) +",
  "  labs(x = \"Zeitverhältnis\", y = NULL)",
  "fig",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-pj-i-figure .exercise-grade.alert-success')", timeout = 120)
step("project-intermediate: contrast figure graded correct", !is.na(checked), sprintf("%s s", checked))

# 15. Expert P1: linked in the course plan; the challenge box stands before
# #why with a skip link and is graded like an exercise; load times with
# dtplyr/duckplyr, mice/ggmice and ggdist/ggrepel/ggtext/colorspace.
goto("/de/index.html")
Sys.sleep(1)
expert_p1 <- c("reshaping", "missing", "visualisation")
unlinked <- js(sprintf(
  "[%s].filter(slug => !document.querySelector(`a[href*=\"${slug}-expert\"]`)).join(', ')",
  paste0("'", expert_p1, "'", collapse = ", ")
))
step("expert: P1 lessons linked in the German course plan", identical(unlinked, ""), unlinked)
loaded <- wait_lesson("/de/reshaping-expert.html", "rs-e-glance-windows")
step("reshaping-expert: webR, dtplyr and data.table ready", !is.na(loaded), sprintf("%s s", loaded))
before_why <- js("(() => {
  const box = document.querySelector('.rt-challenge');
  const why = document.getElementById('why');
  return !!box && !!why && !!(box.compareDocumentPosition(why) & Node.DOCUMENT_POSITION_FOLLOWING) &&
    !!box.querySelector('#ex-rs-e-glance-windows');
})()")
step("reshaping-expert: challenge box with the exercise stands before #why", before_why)
# Quarto rewrites the relative href to an absolute URL of the same page.
skip <- js("(() => {
  const a = document.querySelector('.rt-challenge a.rt-challenge-skip');
  return a ? a.pathname + a.hash : '';
})()")
step("reshaping-expert: skip link points to #why", identical(skip, "/de/reshaping-expert.html#why"), skip)
unnumbered <- js("(() => {
  const title = document.querySelector('#ex-rs-e-glance-windows .rt-exercise-title')?.textContent || '';
  const first = document.querySelector('.rt-exercise:not([data-challenge=\"true\"]) .rt-exercise-title')?.textContent || '';
  return title.includes('Herausforderung') && first.includes('Übung 1');
})()")
step("reshaping-expert: challenge unnumbered, first exercise is Übung 1", unnumbered)
glance_code <- function(count) paste(
  "windows |>",
  "  left_join(glances, by = join_by(participant, between(y$time_s, x$start_s, x$end_s))) |>",
  sprintf("  summarise(n_glances = %s, .by = c(participant, condition, trial))", count),
  sep = "\n"
)
run_exercise("rs-e-glance-windows", glance_code("n()"))
hinted <- wait_for("(document.querySelector('#ex-rs-e-glance-windows .exercise-grade.alert-danger')?.textContent || '').includes('zählt Zeilen')", timeout = 90)
step("reshaping-expert: n() in the challenge gets the hint", !is.na(hinted))
run_exercise("rs-e-glance-windows", glance_code("sum(!is.na(time_s))"))
checked <- wait_for("!!document.querySelector('#ex-rs-e-glance-windows .exercise-grade.alert-success')", timeout = 90)
step("reshaping-expert: challenge (inequality join) graded correct", !is.na(checked), sprintf("%s s", checked))
saved <- wait_for("JSON.parse(localStorage.getItem('rtrainer.progress') || '{}').exercises?.['rs-e-glance-windows']?.solved === true", timeout = 10)
step("reshaping-expert: solved challenge saved in progress", !is.na(saved))
run_exercise("rs-e-lazy-debug", paste(
  "lane_log |>",
  "  lazy_dt() |>",
  "  group_by(participant, condition) |>",
  "  summarise(share_out = round(mean(abs(lane_pos) > 0.5), 3)) |>",
  "  as_tibble()",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-rs-e-lazy-debug .exercise-grade.alert-success')", timeout = 90)
step("reshaping-expert: dtplyr solution graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/missing-expert.html", "ms-e-ggmice-strip")
step("missing-expert: webR, mice, ggmice and naniar ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("ms-e-ggmice-strip", paste(
  "ggmice(imp, aes(x = .imp, y = tlx_effort)) +",
  "  geom_jitter(width = 0.25, height = 0)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-ms-e-ggmice-strip .exercise-grade.alert-success')", timeout = 120)
step("missing-expert: mice in webR, ggmice plot graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/visualisation-expert.html", "vi-e-ci-dist")
step("visualisation-expert: webR, ggdist, ggrepel, ggtext and colorspace ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("vi-e-ci-dist", paste(
  "ggplot(ci, aes(y = condition, xdist = rt_dist)) +",
  "  stat_halfeye(.width = c(0.66, 0.95))",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-vi-e-ci-dist .exercise-grade.alert-success')", timeout = 90)
step("visualisation-expert: ggdist plot with xdist graded correct", !is.na(checked), sprintf("%s s", checked))

# 16. Expert P2: linked in the course plan; sem-expert challenge (hint and
# solution) before #why; polychoric matrix with lavCor + EFAtools and a
# TOSTER equivalence test graded; load times with lavaan/EFAtools,
# lavaan/semTools and afex/emmeans/TOSTER.
goto("/de/index.html")
Sys.sleep(1)
expert_p2 <- c("scales", "sem", "group-comparisons")
unlinked <- js(sprintf(
  "[%s].filter(slug => !document.querySelector(`a[href*=\"${slug}-expert\"]`)).join(', ')",
  paste0("'", expert_p2, "'", collapse = ", ")
))
step("expert: P2 lessons linked in the German course plan", identical(unlinked, ""), unlinked)

loaded <- wait_lesson("/de/scales-expert.html", "sc-e-efa-ordinal")
step("scales-expert: webR, psych, EFAtools and lavaan ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("sc-e-efa-ordinal", paste(
  "efa <- EFA(rho, n_factors = 4, N = nrow(items), method = \"ULS\", rotation = \"oblimin\")",
  "tibble(item = names(efa$h2), h2 = round(efa$h2, 2)) |>",
  "  arrange(h2)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-sc-e-efa-ordinal .exercise-grade.alert-success')", timeout = 120)
step("scales-expert: EFA on the lavCor matrix graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/sem-expert.html", "sm-e-invariance")
step("sem-expert: webR, lavaan and semTools ready", !is.na(loaded), sprintf("%s s", loaded))
before_why <- js("(() => {
  const box = document.querySelector('.rt-challenge');
  const why = document.getElementById('why');
  return !!box && !!why && !!(box.compareDocumentPosition(why) & Node.DOCUMENT_POSITION_FOLLOWING) &&
    !!box.querySelector('#ex-sm-e-invariance');
})()")
step("sem-expert: challenge box with the exercise stands before #why", before_why)
invariance_code <- function(scalar_equal) paste(
  "configural <- cfa(tam_model, data = tam, group = \"market\")",
  "metric <- cfa(tam_model, data = tam, group = \"market\", group.equal = \"loadings\")",
  sprintf("scalar <- cfa(tam_model, data = tam, group = \"market\", group.equal = %s)", scalar_equal),
  "list(configural = configural, metric = metric, scalar = scalar) |>",
  "  imap(\\(fit, name) tibble(model = name, !!!as.list(fitMeasures(fit, c(\"chisq\", \"df\", \"cfi\", \"rmsea\"))))) |>",
  "  list_rbind() |>",
  "  mutate(across(chisq:rmsea, \\(x) round(x, 3)))",
  sep = "\n"
)
run_exercise("sm-e-invariance", invariance_code("\"intercepts\""))
hinted <- wait_for("(document.querySelector('#ex-sm-e-invariance .exercise-grade.alert-danger')?.textContent || '').includes('setzt metrische voraus')", timeout = 90)
step("sem-expert: intercepts without loadings in the challenge gets the hint", !is.na(hinted))
run_exercise("sm-e-invariance", invariance_code("c(\"loadings\", \"intercepts\")"))
checked <- wait_for("!!document.querySelector('#ex-sm-e-invariance .exercise-grade.alert-success')", timeout = 90)
step("sem-expert: challenge (three invariance steps) graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/group-comparisons-expert.html", "gc-e-tost")
step("group-comparisons-expert: webR, afex, emmeans and TOSTER ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("gc-e-tost", paste(
  "res <- t_TOST(tlx_temporal ~ interface, data = survey, eqb = 10)",
  "res$TOST",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-gc-e-tost .exercise-grade.alert-success')", timeout = 90)
step("group-comparisons-expert: TOSTER equivalence test graded correct", !is.na(checked), sprintf("%s s", checked))

# 17. Expert P3: linked in the course plan; robust-expert challenge (BCa
# bootstrap, wrong interval type gets the hint) before #why; CR2 with
# clubSandwich and an ordinal mixed model (clmm) graded; load times with
# boot/coin/robustbase/WRS2, sandwich/clubSandwich and MASS/ordinal/pscl.
goto("/de/index.html")
Sys.sleep(1)
expert_p3 <- c("robust", "regression", "glm")
unlinked <- js(sprintf(
  "[%s].filter(slug => !document.querySelector(`a[href*=\"${slug}-expert\"]`)).join(', ')",
  paste0("'", expert_p3, "'", collapse = ", ")
))
step("expert: P3 lessons linked in the German course plan", identical(unlinked, ""), unlinked)

loaded <- wait_lesson("/de/robust-expert.html", "rb-e-bca")
step("robust-expert: webR, boot, coin, robustbase and WRS2 ready", !is.na(loaded), sprintf("%s s", loaded))
before_why <- js("(() => {
  const box = document.querySelector('.rt-challenge');
  const why = document.getElementById('why');
  return !!box && !!why && !!(box.compareDocumentPosition(why) & Node.DOCUMENT_POSITION_FOLLOWING) &&
    !!box.querySelector('#ex-rb-e-bca');
})()")
step("robust-expert: challenge box with the exercise stands before #why", before_why)
bca_code <- function(type) paste(
  "trim_diff <- function(data, i) {",
  "  d <- data[i, ]",
  "  mean(d$tlx_frustration[d$interface == \"voice\"], trim = 0.2) -",
  "    mean(d$tlx_frustration[d$interface == \"touch\"], trim = 0.2)",
  "}",
  "set.seed(2026)",
  "b <- boot(frust, trim_diff, R = 1999, strata = frust$interface)",
  sprintf("ci <- boot.ci(b, type = \"%s\")", type),
  sprintf("ci$%s[4:5]", if (type == "perc") "percent" else type),
  sep = "\n"
)
run_exercise("rb-e-bca", bca_code("perc"))
hinted <- wait_for("(document.querySelector('#ex-rb-e-bca .exercise-grade.alert-danger')?.textContent || '').includes('BCa')", timeout = 90)
step("robust-expert: percentile interval in the challenge gets the hint", !is.na(hinted))
run_exercise("rb-e-bca", bca_code("bca"))
checked <- wait_for("!!document.querySelector('#ex-rb-e-bca .exercise-grade.alert-success')", timeout = 90)
step("robust-expert: challenge (BCa bootstrap) graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/regression-expert.html", "rg-e-cr2")
step("regression-expert: webR, sandwich, clubSandwich and performance ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("rg-e-cr2", paste(
  "ct <- coef_test(fit, vcov = \"CR2\", cluster = solved$participant)",
  "tibble(term = ct$Coef, estimate = ct$beta, se = ct$SE, df = ct$df_Satt, p = ct$p_Satt)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-rg-e-cr2 .exercise-grade.alert-success')", timeout = 90)
step("regression-expert: CR2 with Satterthwaite df graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/glm-expert.html", "gl-e-clmm")
step("glm-expert: webR, MASS, ordinal, nnet and pscl ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("gl-e-clmm", paste(
  "fit <- clmm(seq_o ~ prototype + expertise + (1 | participant), data = ease)",
  "tab <- coef(summary(fit))",
  "terms <- c(\"prototypeB\", \"prototypeC\", \"expertiseexpert\")",
  "tibble(term = terms, or = exp(tab[terms, 1]), se = tab[terms, 2])",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-gl-e-clmm .exercise-grade.alert-success')", timeout = 120)
step("glm-expert: ordinal mixed model (clmm) graded correct", !is.na(checked), sprintf("%s s", checked))

# 18. Expert P4: linked in the course plan; mixed-models-expert challenge
# (rePCA + REML LRT, ML comparison gets the REML hint) before #why; moderated
# mediation in lavaan and a power loop with faux + lmerTest graded; load times
# with lme4/DHARMa, lavaan/interactions and faux/lmerTest.
goto("/de/index.html")
Sys.sleep(1)
expert_p4 <- c("mixed-models", "moderation-mediation", "power")
unlinked <- js(sprintf(
  "[%s].filter(slug => !document.querySelector(`a[href*=\"${slug}-expert\"]`)).join(', ')",
  paste0("'", expert_p4, "'", collapse = ", ")
))
step("expert: P4 lessons linked in the German course plan", identical(unlinked, ""), unlinked)

loaded <- wait_lesson("/de/mixed-models-expert.html", "mm-e-maximal")
step("mixed-models-expert: webR, lme4 and DHARMa ready", !is.na(loaded), sprintf("%s s", loaded))
before_why <- js("(() => {
  const box = document.querySelector('.rt-challenge');
  const why = document.getElementById('why');
  return !!box && !!why && !!(box.compareDocumentPosition(why) & Node.DOCUMENT_POSITION_FOLLOWING) &&
    !!box.querySelector('#ex-mm-e-maximal');
})()")
step("mixed-models-expert: challenge box with the exercise stands before #why", before_why)
maximal_code <- function(refit) paste(
  "pca <- summary(rePCA(fit_max))$participant$importance",
  "dims <- sum(pca[\"Proportion of Variance\", ] > 0.01)",
  "fit_ri <- lmer(rt_ms ~ condition * trial_c + (1 | participant), data = sim)",
  sprintf("lrt <- anova(fit_ri, fit_max%s)", refit),
  "c(dims = dims, chisq = lrt$Chisq[2], df = lrt$Df[2])",
  sep = "\n"
)
run_exercise("mm-e-maximal", maximal_code(""))
hinted <- wait_for("(document.querySelector('#ex-mm-e-maximal .exercise-grade.alert-danger')?.textContent || '').includes('REML')", timeout = 120)
step("mixed-models-expert: ML comparison in the challenge gets the REML hint", !is.na(hinted))
run_exercise("mm-e-maximal", maximal_code(", refit = FALSE"))
checked <- wait_for("!!document.querySelector('#ex-mm-e-maximal .exercise-grade.alert-success')", timeout = 120)
step("mixed-models-expert: challenge (rePCA + REML LRT) graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/moderation-mediation-expert.html", "mo-e-conditional")
step("moderation-mediation-expert: webR, lavaan, lme4 and interactions ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("mo-e-conditional", paste(
  "model <- \"",
  "  pu ~ a * peou",
  "  bi ~ b1 * pu + b3 * pu_exp + exp_c + c * peou",
  "  ind_1 := a * (b1 + b3 * -2)",
  "  ind_3 := a * b1",
  "  ind_5 := a * (b1 + b3 * 2)",
  "\"",
  "fit <- sem(model, data = acc)",
  "parameterEstimates(fit) |>",
  "  filter(op == \":=\") |>",
  "  select(label, est, ci.lower, ci.upper) |>",
  "  as_tibble()",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-mo-e-conditional .exercise-grade.alert-success')", timeout = 90)
step("moderation-mediation-expert: conditional indirect effects graded correct", !is.na(checked), sprintf("%s s", checked))

loaded <- wait_lesson("/de/power-expert.html", "pw-e-loop")
step("power-expert: webR, faux, lme4 and lmerTest ready", !is.na(loaded), sprintf("%s s", loaded))
run_exercise("pw-e-loop", paste(
  "sim_p <- function(n_part, n_task) {",
  "  d <- sim_data(n_part, n_task)",
  "  fit <- suppressMessages(",
  "    lmer(log_time ~ prototype + (1 + prototype | participant) + (1 | task), data = d)",
  "  )",
  "  coef(summary(fit))[\"prototypeB\", \"Pr(>|t|)\"]",
  "}",
  "set.seed(2026)",
  "p <- replicate(20, sim_p(30, 8))",
  "mean(p < .05)",
  sep = "\n"
))
checked <- wait_for("!!document.querySelector('#ex-pw-e-loop .exercise-grade.alert-success')", timeout = 180)
step("power-expert: simulation loop (20 x lmer) graded correct", !is.na(checked), sprintf("%s s", checked))

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
intermediate <- c(
  "import", "cleaning", "reshaping", "missing", "visualisation",
  "descriptives", "scales", "sem", "group-comparisons", "robust",
  "regression", "glm", "mixed-models", "moderation-mediation", "power",
  "reporting", "reproducibility", "programming"
)
unlinked <- js(sprintf(
  "[%s].filter(slug => !document.querySelector(`a[href*=\"${slug}-intermediate\"]`)).join(', ')",
  paste0("'", intermediate, "'", collapse = ", ")
))
step("en: all 18 intermediate lessons linked in course plan", identical(unlinked, ""), unlinked)
linked <- js("[...document.querySelectorAll('a[href*=\"-expert\"]')].map(a => a.getAttribute('href')).join(', ')")
step("en: German-only expert lessons not linked", identical(linked, ""), linked)
project_row <- js("document.querySelector('tr.rt-plan-project a[href*=\"project-beginner\"]')?.getAttribute('href') || ''")
step("en: project row links the English page", grepl("project-beginner", project_row) && !grepl("/de/", project_row), project_row)
project_row <- js("document.querySelector('tr.rt-plan-project a[href*=\"project-intermediate\"]')?.getAttribute('href') || ''")
step("en: project row links the English intermediate project", grepl("project-intermediate", project_row) && !grepl("/de/", project_row), project_row)
goto("/en/project-beginner.html")
en_project <- wait_for(
  "document.documentElement.lang.startsWith('en') && document.querySelector('h1').textContent.includes('Mini project') &&
   !!document.querySelector('#ex-pj-b-import') && !!document.querySelector('#script')",
  timeout = 15
)
step("en: project page in English with exercises", !is.na(en_project))
goto("/en/group-comparisons-intermediate.html")
en_intermediate <- wait_for(
  "document.documentElement.lang.startsWith('en') && document.querySelector('h1').textContent.includes('Group comparisons') &&
   !!document.querySelector('#ex-gc-i-rm-anova') && !!document.querySelector('.rt-pager a')",
  timeout = 15
)
step("en: intermediate page in English with exercise and pager", !is.na(en_intermediate))

cat(sprintf("\n%d failure(s)\n", length(failures)))
if (length(failures) > 0) quit(status = 1)
