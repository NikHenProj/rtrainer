# Simulated acceptance questionnaire in two markets (de, us), same items as
# `acceptance` (data-raw/acceptance.R), for measurement invariance, ordinal
# CFA, IRT and multi-group moderation. 300 drivers per market.
# Scales (all 1-7, 1 = strongly disagree, 7 = strongly agree):
# - perceived usefulness pu_1 to pu_5
# - perceived ease of use peou_1 to peou_4 (peou_3 reverse-keyed)
# - trust trust_1 to trust_5 (trust_4 reverse-keyed)
# - behavioural intention bi_1 to bi_4
# Run from the project root: Rscript data-raw/tam_markets.R
#
# Built-in structure (population values, latent variables standardised
# within de):
# - same loadings in both markets (metric invariance holds); pu_5 is weak
# - pu_3 ("improves my safety") is answered 0.6 higher in us at equal
#   usefulness: its intercept is not invariant (scalar invariance fails,
#   partial invariance with pu_3 freed holds)
# - peou_1 ("easy to switch on") has a ceiling effect: most answers 6 or 7
# - latent means in us: usefulness +0.25, trust -0.20
# - usefulness -> intention .30 in de, .50 in us (multi-group moderation);
#   trust -> intention .30, ease of use -> usefulness .50 in both
# No missing values.

set.seed(20261027)

n <- 300

likert <- function(latent, n_points = 7, cuts_sd = 1.4) {
  cuts <- seq(-cuts_sd, cuts_sd, length.out = n_points - 1)
  findInterval(latent, cuts) + 1L
}

simulate_market <- function(market, n) {
  us <- market == "us"
  age <- round(pmin(pmax(stats::rnorm(n, if (us) 40 else 44, 13), 18), 78))
  experience <- pmin(stats::rpois(n, exp(1.1 - 0.008 * (age - 42))), 15)
  peou <- stats::rnorm(n)
  pu <- 0.25 * us + 0.50 * peou + sqrt(1 - 0.50^2) * stats::rnorm(n)
  trust <- -0.20 * us + 0.30 * peou + sqrt(1 - 0.30^2) * stats::rnorm(n)
  bi <- (if (us) 0.50 else 0.30) * pu + 0.30 * trust + 0.75 * stats::rnorm(n)

  # Item = loading * latent + intercept + noise, cut into 1-7.
  items <- function(latent, prefix, loadings, keys, intercepts = 0) {
    intercepts <- rep_len(intercepts, length(loadings))
    out <- vapply(
      seq_along(loadings),
      \(j) likert(keys[j] * (loadings[j] * latent + sqrt(1 - loadings[j]^2) * stats::rnorm(n)) + intercepts[j]),
      integer(n)
    )
    colnames(out) <- paste0(prefix, "_", seq_along(loadings))
    tibble::as_tibble(out)
  }

  dplyr::bind_cols(
    tibble::tibble(
      market = market,
      age = age,
      gender = sample(c("female", "male", "diverse"), n, replace = TRUE, prob = c(0.47, 0.50, 0.03)),
      experience = as.integer(experience)
    ),
    items(pu, "pu", c(0.80, 0.78, 0.82, 0.75, 0.35), rep(1, 5), c(0, 0, if (us) 0.6 else 0, 0, 0)),
    items(peou, "peou", c(0.78, 0.80, 0.72, 0.76), c(1, 1, -1, 1), c(1.6, 0, 0, 0)),
    items(trust, "trust", c(0.80, 0.82, 0.76, 0.72, 0.78), c(1, 1, 1, -1, 1)),
    items(bi, "bi", c(0.85, 0.83, 0.80, 0.78), rep(1, 4))
  )
}

tam_markets <- dplyr::bind_rows(simulate_market("de", n), simulate_market("us", n))
tam_markets <- dplyr::bind_cols(
  tibble::tibble(respondent = sprintf("m%03d", seq_len(nrow(tam_markets)))),
  tam_markets
)

dir.create("data", showWarnings = FALSE)
utils::write.csv(tam_markets, "data/tam_markets.csv", row.names = FALSE)
