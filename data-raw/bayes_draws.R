# Posterior and prior draws of two Bayesian models, estimated locally with
# brms, for the bayes lessons. brms cannot estimate in webR (no Stan
# compiler), so the lessons work with these precomputed draws.
# Needs brms and rstan (Stan toolchain); does not run in CI. The CSV
# data/bayes_draws.csv is checked in.
# Run from the project root: Rscript data-raw/bayes_draws.R
#
# Models (4 chains x 500 draws: 2000 after 1000 warm-up, thinned by 4 to keep
# the file small for the browser; adapt_delta .95; sample_prior = "yes"):
# - drive_rt: driving_sim, rt_ms ~ condition * trial_c + (1 | participant),
#   gaussian; trial_c = trial - 2.5. Priors: Intercept normal(1200, 300),
#   b normal(0, 200), sd and sigma exponential(1 / 200).
# - usability_success: usability, success ~ prototype + (1 | participant) +
#   (1 | task), bernoulli (logit). Priors: Intercept normal(0, 1.5),
#   b normal(0, 1), sd exponential(1).
# Long form: model, chain, iteration, draw (1-2000 within a model),
# parameter (brms names; prior draws start with `prior_`), value
# (4 significant digits). Wide per model with tidyr::pivot_wider(),
# then posterior::as_draws_df() works directly.

set.seed(20261027)

source_dataset <- function(name) {
  datasets <- yaml::read_yaml("data/datasets.yml")
  env <- new.env()
  eval(parse(text = datasets[[name]]$load), envir = env)
  env[[name]]
}

driving_sim <- source_dataset("driving_sim")
driving_sim$trial_c <- driving_sim$trial - 2.5
usability <- source_dataset("usability")

fit_args <- list(chains = 4, iter = 3000, warmup = 1000, thin = 4, cores = 4,
  control = list(adapt_delta = 0.95), sample_prior = "yes", seed = 20261027, refresh = 0)

drive_rt <- do.call(brms::brm, c(list(
  formula = rt_ms ~ condition * trial_c + (1 | participant),
  data = driving_sim,
  family = gaussian(),
  prior = c(
    brms::prior(normal(1200, 300), class = Intercept),
    brms::prior(normal(0, 200), class = b),
    brms::prior(exponential(0.005), class = sd),
    brms::prior(exponential(0.005), class = sigma)
  )
), fit_args))

usability_success <- do.call(brms::brm, c(list(
  formula = success ~ prototype + (1 | participant) + (1 | task),
  data = usability,
  family = brms::bernoulli(),
  prior = c(
    brms::prior(normal(0, 1.5), class = Intercept),
    brms::prior(normal(0, 1), class = b),
    brms::prior(exponential(1), class = sd)
  )
), fit_args))

long_draws <- function(fit, model) {
  draws <- posterior::as_draws_df(fit)
  keep <- grep("^(b_|sd_|sigma$|prior_)", posterior::variables(draws), value = TRUE)
  draws <- posterior::subset_draws(draws, variable = keep)
  wide <- tibble::as_tibble(draws)
  wide |>
    tidyr::pivot_longer(dplyr::all_of(keep), names_to = "parameter", values_to = "value") |>
    dplyr::transmute(
      model = model,
      chain = .data$.chain,
      iteration = .data$.iteration,
      draw = .data$.draw,
      parameter = .data$parameter,
      value = signif(.data$value, 4)
    )
}

bayes_draws <- dplyr::bind_rows(
  long_draws(drive_rt, "drive_rt"),
  long_draws(usability_success, "usability_success")
)

print(summary(drive_rt)$fixed)
print(summary(usability_success)$fixed)

dir.create("data", showWarnings = FALSE)
utils::write.csv(bayes_draws, "data/bayes_draws.csv", row.names = FALSE, quote = FALSE)
