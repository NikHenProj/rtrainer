# Simulated online questionnaire after using an in-car infotainment prototype.
# Between-subjects: interface = touch vs. voice, 160 respondents.
# Scales: SUS (10 items, 1-5), NASA-TLX raw (6 subscales, 0-100 in steps of 5),
# trust in automation (6 items, 1-7; items 3 and 5 reverse-keyed).
# Run from the project root: Rscript data-raw/survey.R
#
# Built-in effects (population values):
# - interface: voice +0.6 SD usability (about +9 SUS points), -12 TLX mental demand,
#   -8 TLX physical demand, +6 TLX frustration (misrecognitions)
# - usability and trust correlate r = .5 (latent); workload correlates r = -.4
#   with usability
# - age: -0.15 SD usability per decade; tech_affinity (1-5) +0.3 SD per point
# - SUS: odd items positive, even items negative wording (standard SUS keying)
# - trust: loadings about .7-.8, reverse-keyed items t3 and t5 (alpha about .9
#   after recoding)
# Data problems on purpose:
# - item nonresponse: about 3 % of item cells missing (MCAR)
# - r041 and r112 skipped the whole trust block
# - attention_check: instructed answer is 4; r027, r088, r133 fail it
# - r133 straightlines (all SUS items 3, all trust items 4)
# - age of r019 missing, gender "prefer not to say" for a few

set.seed(20261027)

n <- 160
items_sus <- sprintf("sus_%02d", 1:10)
items_tlx <- c(
  "tlx_mental", "tlx_physical", "tlx_temporal",
  "tlx_performance", "tlx_effort", "tlx_frustration"
)
items_trust <- sprintf("trust_%d", 1:6)

likert <- function(latent, n_points, cuts_sd = 1.1) {
  cuts <- seq(-cuts_sd, cuts_sd, length.out = n_points - 1)
  findInterval(latent, cuts) + 1L
}

respondents <- tibble::tibble(
  respondent = sprintf("r%03d", seq_len(n)),
  interface = sample(rep(c("touch", "voice"), each = n / 2)),
  age = round(pmin(pmax(stats::rnorm(n, 38, 12), 18), 74)),
  gender = sample(
    c("female", "male", "diverse", "prefer not to say"),
    n,
    replace = TRUE,
    prob = c(0.47, 0.47, 0.03, 0.03)
  ),
  tech_affinity = sample(1:5, n, replace = TRUE, prob = c(0.08, 0.17, 0.35, 0.27, 0.13))
)

# Latent traits: usability (u), trust (t), workload (w)
z <- matrix(stats::rnorm(n * 3), ncol = 3)
latent_cor <- matrix(c(1, 0.5, -0.4, 0.5, 1, -0.2, -0.4, -0.2, 1), 3)
z <- z %*% chol(latent_cor)

u <- z[, 1] +
  ifelse(respondents$interface == "voice", 0.6, 0) -
  0.15 * (respondents$age - 40) / 10 +
  0.3 * (respondents$tech_affinity - 3)
t <- z[, 2]
w <- z[, 3]

sus_keys <- rep(c(1, -1), 5)
sus <- vapply(
  seq_along(items_sus),
  \(j) likert(sus_keys[j] * 0.75 * u + stats::rnorm(n, 0, 0.6), 5),
  integer(n)
)
colnames(sus) <- items_sus

tlx_effect <- list(
  tlx_mental = c(touch = 0, voice = -12),
  tlx_physical = c(touch = 0, voice = -8),
  tlx_temporal = c(touch = 0, voice = 0),
  tlx_performance = c(touch = 0, voice = 0),
  tlx_effort = c(touch = 0, voice = -4),
  tlx_frustration = c(touch = 0, voice = 6)
)
tlx_base <- c(55, 30, 45, 30, 50, 35)
tlx <- vapply(
  seq_along(items_tlx),
  \(j) {
    raw <- tlx_base[j] +
      tlx_effect[[j]][respondents$interface] +
      14 * w +
      stats::rnorm(n, 0, 12)
    as.integer(5 * round(pmin(pmax(raw, 0), 100) / 5))
  },
  integer(n)
)
colnames(tlx) <- items_tlx

trust_keys <- c(1, 1, -1, 1, -1, 1)
trust_loadings <- c(0.8, 0.75, 0.7, 0.8, 0.7, 0.75)
trust <- vapply(
  seq_along(items_trust),
  \(j) likert(
    trust_keys[j] * trust_loadings[j] * t + stats::rnorm(n, 0, 0.55),
    7,
    cuts_sd = 1.4
  ),
  integer(n)
)
colnames(trust) <- items_trust

survey <- dplyr::bind_cols(
  respondents,
  tibble::as_tibble(sus),
  tibble::as_tibble(tlx),
  attention_check = 4L,
  tibble::as_tibble(trust)
)

# Item nonresponse (MCAR, about 3 %)
item_cols <- c(items_sus, items_tlx, items_trust)
for (col in item_cols) {
  survey[[col]][stats::runif(n) < 0.03] <- NA
}

survey[survey$respondent %in% c("r041", "r112"), items_trust] <- NA
survey$attention_check[survey$respondent %in% c("r027", "r088")] <- c(2L, 6L)
straightliner <- survey$respondent == "r133"
survey[straightliner, items_sus] <- 3L
survey[straightliner, items_trust] <- 4L
survey$attention_check[straightliner] <- 3L
survey$age[survey$respondent == "r019"] <- NA

dir.create("data", showWarnings = FALSE)
utils::write.csv(survey, "data/survey.csv", row.names = FALSE, na = "")
