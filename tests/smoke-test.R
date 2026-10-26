# Browser smoke test of the rendered site (_site) with headless Chrome:
# a lesson exercise is solved and checked in webR, progress is stored,
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

cat(sprintf("\n%d failure(s)\n", length(failures)))
if (length(failures) > 0) quit(status = 1)
