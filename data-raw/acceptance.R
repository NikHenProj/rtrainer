# Simulated acceptance questionnaire for a driver assistance system
# (lane-keeping and adaptive cruise control), based on the Technology
# Acceptance Model (TAM). 300 drivers, all answered after a test drive.
# Scales (all 1-7, 1 = strongly disagree, 7 = strongly agree):
# - perceived usefulness pu_1 to pu_5
# - perceived ease of use peou_1 to peou_4 (peou_3 reverse-keyed)
# - trust trust_1 to trust_5 (trust_4 reverse-keyed)
# - behavioural intention bi_1 to bi_4
# Run from the project root: Rscript data-raw/acceptance.R
#
# Built-in structure (population values, latent variables standardised):
# - loadings about .70-.85; pu_5 ("makes driving more fun") is a weak item,
#   loading about .35
# - experience (years of using driver assistance) -> ease of use .30
# - ease of use -> usefulness .50 (mediation: ease -> usefulness -> intention)
# - ease of use -> trust .30
# - intention: usefulness .40, trust .30, ease of use .10, and usefulness x
#   experience (standardised) .15 (moderation: usefulness matters more for
#   experienced drivers)
# - age: -0.10 SD intention per decade
# No missing values.

set.seed(20261026)

n <- 300

likert <- function(latent, n_points = 7, cuts_sd = 1.4) {
  cuts <- seq(-cuts_sd, cuts_sd, length.out = n_points - 1)
  findInterval(latent, cuts) + 1L
}

age <- round(pmin(pmax(stats::rnorm(n, 42, 13), 18), 78))
experience <- pmin(stats::rpois(n, exp(1.1 - 0.008 * (age - 42))), 15)
experience_z <- (experience - mean(experience)) / stats::sd(experience)

peou <- 0.30 * experience_z + sqrt(1 - 0.30^2) * stats::rnorm(n)
pu <- 0.50 * peou + sqrt(1 - 0.50^2) * stats::rnorm(n)
trust <- 0.30 * peou + sqrt(1 - 0.30^2) * stats::rnorm(n)
bi <- 0.40 * pu + 0.30 * trust + 0.10 * peou +
  0.15 * pu * experience_z - 0.10 * (age - 42) / 10 +
  0.75 * stats::rnorm(n)
bi <- (bi - mean(bi)) / stats::sd(bi)

items <- function(latent, prefix, loadings, keys) {
  out <- vapply(
    seq_along(loadings),
    \(j) likert(keys[j] * (loadings[j] * latent + sqrt(1 - loadings[j]^2) * stats::rnorm(n))),
    integer(n)
  )
  colnames(out) <- paste0(prefix, "_", seq_along(loadings))
  tibble::as_tibble(out)
}

acceptance <- dplyr::bind_cols(
  tibble::tibble(
    respondent = sprintf("a%03d", seq_len(n)),
    age = age,
    gender = sample(c("female", "male", "diverse"), n, replace = TRUE, prob = c(0.46, 0.51, 0.03)),
    experience = as.integer(experience)
  ),
  items(pu, "pu", c(0.80, 0.78, 0.82, 0.75, 0.35), rep(1, 5)),
  items(peou, "peou", c(0.78, 0.80, 0.72, 0.76), c(1, 1, -1, 1)),
  items(trust, "trust", c(0.80, 0.82, 0.76, 0.72, 0.78), c(1, 1, 1, -1, 1)),
  items(bi, "bi", c(0.85, 0.83, 0.80, 0.78), rep(1, 4))
)

dir.create("data", showWarnings = FALSE)
utils::write.csv(acceptance, "data/acceptance.csv", row.names = FALSE)
