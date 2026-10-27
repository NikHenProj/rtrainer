datasets <- yaml::read_yaml(file.path(root, "data", "datasets.yml"))

load_dataset <- function(name) {
  env <- new.env()
  withr::with_dir(root, eval(parse(text = datasets[[name]]$load), envir = env))
  env
}

test_that("every dataset has a file, a script and bilingual descriptions", {
  for (name in names(datasets)) {
    d <- datasets[[name]]
    expect_true(file.exists(file.path(root, "data", d$file)), info = name)
    expect_true(file.exists(file.path(root, d$script)), info = name)
    expect_true(all(c("de", "en") %in% names(d$description)), info = name)
  }
})

test_that("load code creates the dataset object", {
  expect_s3_class(load_dataset("survey")$survey, "tbl_df")
  expect_s3_class(load_dataset("usability")$usability, "tbl_df")
  expect_true(file.exists(file.path(root, load_dataset("raw_export")$raw_export_csv)))
  expect_true(file.exists(file.path(root, load_dataset("raw_export_xlsx")$raw_export_xlsx)))
})

test_that("survey has the documented structure and problems", {
  survey <- load_dataset("survey")$survey
  expect_equal(nrow(survey), 160)
  expect_equal(levels(survey$interface), c("touch", "voice"))
  expect_true(all(c(sprintf("sus_%02d", 1:10), sprintf("trust_%d", 1:6)) %in% names(survey)))
  expect_true(all(is.na(survey[survey$respondent == "r041", paste0("trust_", 1:6)])))
  expect_setequal(survey$respondent[survey$attention_check != 4], c("r027", "r088", "r133"))
  expect_true(all(survey$tlx_mental %% 5 == 0, na.rm = TRUE))
})

test_that("usability lacks prototype C for p07 and caps time at 180 s", {
  usability <- load_dataset("usability")$usability
  expect_equal(nrow(usability), 24 * 3 * 4 - 4)
  expect_false(any(usability$participant == "p07" & usability$prototype == "C"))
  expect_lte(max(usability$time_s), 180)
  expect_setequal(unique(usability$success), c(0, 1))
})

test_that("raw export CSV needs skip, semicolon and decimal comma", {
  path <- file.path(root, "data", "raw_export.csv")
  raw <- utils::read.csv2(path, skip = 3, check.names = FALSE)[-1, ]
  expect_equal(nrow(raw), 82)
  expect_true(all(c("TEST_1", "TEST_2") %in% raw$`Response ID`))
  expect_equal(sum(duplicated(raw)), 2)
})

test_that("acceptance has four TAM scales with two reverse-keyed items", {
  acceptance <- load_dataset("acceptance")$acceptance
  items <- c(
    paste0("pu_", 1:5), paste0("peou_", 1:4),
    paste0("trust_", 1:5), paste0("bi_", 1:4)
  )
  expect_equal(nrow(acceptance), 300)
  expect_true(all(c("respondent", "age", "experience", items) %in% names(acceptance)))
  expect_false(anyNA(acceptance))
  expect_true(all(unlist(acceptance[items]) %in% 1:7))
  # Reverse-keyed items correlate negatively with the rest of their scale.
  expect_lt(cor(acceptance$peou_3, acceptance$peou_1), 0)
  expect_lt(cor(acceptance$trust_4, acceptance$trust_1), 0)
  expect_gt(cor(acceptance$peou_2, acceptance$peou_1), 0.4)
})

test_that("acceptance has one weak item and fits the four-factor model", {
  skip_if_not_installed("lavaan")
  d <- load_dataset("acceptance")$acceptance
  model <- "
    pu =~ pu_1 + pu_2 + pu_3 + pu_4 + pu_5
    peou =~ peou_1 + peou_2 + peou_3 + peou_4
    trust =~ trust_1 + trust_2 + trust_3 + trust_4 + trust_5
    bi =~ bi_1 + bi_2 + bi_3 + bi_4
  "
  fit <- lavaan::cfa(model, data = d)
  std <- lavaan::standardizedSolution(fit)
  loadings <- abs(std$est.std[std$op == "=~"])
  names(loadings) <- std$rhs[std$op == "=~"]
  expect_lt(loadings[["pu_5"]], 0.5)
  expect_true(all(loadings[names(loadings) != "pu_5"] > 0.6))
  fit_measures <- lavaan::fitMeasures(fit, c("cfi", "rmsea"))
  expect_gt(fit_measures[["cfi"]], 0.95)
  expect_lt(fit_measures[["rmsea"]], 0.06)
})

tam_items <- c(paste0("pu_", 1:5), paste0("peou_", 1:4), paste0("trust_", 1:5), paste0("bi_", 1:4))

test_that("tam_markets: two markets of 300, acceptance items, ordinal 1-7", {
  d <- load_dataset("tam_markets")$tam_markets
  acceptance <- load_dataset("acceptance")$acceptance
  expect_equal(levels(d$market), c("de", "us"))
  expect_equal(as.vector(table(d$market)), c(300, 300))
  expect_true(all(tam_items %in% names(acceptance)))
  expect_true(all(c("respondent", "market", "age", "experience", tam_items) %in% names(d)))
  expect_false(anyNA(d))
  expect_false(anyDuplicated(d$respondent) > 0)
  expect_true(all(unlist(d[tam_items]) %in% 1:7))
  expect_lt(cor(d$peou_3, d$peou_1), 0)
  expect_lt(cor(d$trust_4, d$trust_1), 0)
  # Ceiling effect on peou_1 only.
  top <- vapply(tam_items, function(i) mean(d[[i]] == 7), numeric(1))
  expect_gt(top[["peou_1"]], 0.4)
  expect_true(all(top[names(top) != "peou_1"] < 0.25))
})

test_that("tam_markets: metric invariance holds, scalar fails, partial with pu_3 holds", {
  skip_if_not_installed("lavaan")
  d <- load_dataset("tam_markets")$tam_markets
  model <- "
    pu =~ pu_1 + pu_2 + pu_3 + pu_4 + pu_5
    peou =~ peou_1 + peou_2 + peou_3 + peou_4
    trust =~ trust_1 + trust_2 + trust_3 + trust_4 + trust_5
    bi =~ bi_1 + bi_2 + bi_3 + bi_4
  "
  fit <- function(...) lavaan::cfa(model, data = d, group = "market", ...)
  configural <- fit()
  metric <- fit(group.equal = "loadings")
  scalar <- fit(group.equal = c("loadings", "intercepts"))
  partial <- fit(group.equal = c("loadings", "intercepts"), group.partial = "pu_3 ~ 1")
  p <- function(a, b) lavaan::lavTestLRT(a, b)[2, "Pr(>Chisq)"]
  expect_gt(p(configural, metric), 0.05)
  expect_lt(p(metric, scalar), 0.001)
  expect_gt(p(metric, partial), 0.05)
  # The largest score test for the scalar model points at pu_3's intercept.
  score <- lavaan::lavTestScore(scalar)$uni
  top <- score$lhs[which.max(score$X2)]
  pt <- lavaan::parTable(scalar)
  expect_equal(unique(pt$lhs[pt$plabel == top & pt$op == "~1"]), "pu_3")
})

test_that("bayes_draws: long form, 2000 draws per model, prior draws, plausible summaries", {
  d <- load_dataset("bayes_draws")$bayes_draws
  expect_named(d, c("model", "chain", "iteration", "draw", "parameter", "value"))
  expect_setequal(unique(d$model), c("drive_rt", "usability_success"))
  expect_false(anyNA(d))
  n_draws <- tapply(d$draw, d$model, function(x) length(unique(x)))
  expect_equal(as.vector(n_draws), c(2000, 2000))
  expect_setequal(unique(d$chain), 1:4)
  drive <- d[d$model == "drive_rt", ]
  expect_true(all(c(
    "b_Intercept", "b_conditionauditory", "b_conditionhaptic", "b_trial_c",
    "sd_participant__Intercept", "sigma"
  ) %in% drive$parameter))
  expect_true(any(startsWith(drive$parameter, "prior_b")))
  # One value per draw and parameter.
  expect_equal(anyDuplicated(d[c("model", "draw", "parameter")]), 0)
  # Posterior means close to the frequentist estimates.
  post_mean <- function(model, parameter) mean(d$value[d$model == model & d$parameter == parameter])
  driving_sim <- load_dataset("driving_sim")$driving_sim
  driving_sim$trial_c <- driving_sim$trial - 2.5
  ols <- stats::coef(stats::lm(rt_ms ~ condition * trial_c, data = driving_sim))
  expect_equal(post_mean("drive_rt", "b_conditionhaptic"), ols[["conditionhaptic"]], tolerance = 0.2)
  expect_gt(post_mean("drive_rt", "sigma"), 0)
  usability <- load_dataset("usability")$usability
  logit <- stats::coef(stats::glm(success ~ prototype, family = stats::binomial, data = usability))
  expect_equal(sign(post_mean("usability_success", "b_prototypeB")), sign(logit[["prototypeB"]]))
})

test_that("bayes_draws pivots to a posterior draws object with good convergence", {
  skip_if_not_installed("posterior")
  d <- load_dataset("bayes_draws")$bayes_draws
  wide <- tidyr::pivot_wider(
    d[d$model == "drive_rt", c("chain", "iteration", "draw", "parameter", "value")],
    names_from = parameter, values_from = value
  )
  draws <- posterior::as_draws_df(dplyr::rename(wide, .chain = chain, .iteration = iteration, .draw = draw))
  summary <- posterior::summarise_draws(posterior::subset_draws(draws, variable = "^b_", regex = TRUE))
  expect_true(all(summary$rhat < 1.01))
  expect_true(all(summary$ess_bulk > 400))
})
