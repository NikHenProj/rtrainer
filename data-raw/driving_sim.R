# Simulated driving-simulator study: take-over requests (TOR) with three
# warning modalities, 40 participants, 4 repeated trials per condition.
# Run from the package root: Rscript data-raw/driving_sim.R

set.seed(20261025)

n_vp <- 40
conditions <- c("visuell", "auditiv", "haptisch")
n_trial <- 4

vp <- data.frame(
  vp_id = sprintf("vp%02d", seq_len(n_vp)),
  age = round(stats::runif(n_vp, 19, 68)),
  gender = sample(c("w", "m", "d"), n_vp, replace = TRUE, prob = c(0.48, 0.48, 0.04)),
  u0 = stats::rnorm(n_vp, 0, 120), # random intercept RT (ms)
  u1 = stats::rnorm(n_vp, 0, 12), # random slope over trials (ms per trial)
  v0 = stats::rnorm(n_vp, 0, 0.04) # random intercept lane deviation (m)
)

d <- expand.grid(trial = seq_len(n_trial), condition = conditions,
                 vp_id = vp$vp_id, stringsAsFactors = FALSE)
d <- merge(d, vp, by = "vp_id", sort = FALSE)
d <- d[order(d$vp_id, match(d$condition, conditions), d$trial), ]

cond_rt <- c(visuell = 180, auditiv = 0, haptisch = -70)
cond_ld <- c(visuell = 0.06, auditiv = 0, haptisch = -0.02)

d$rt_ms <- round(1050 + cond_rt[d$condition] + 4 * (d$age - 40) +
                   (-25 + d$u1) * (d$trial - 1) + d$u0 + stats::rnorm(nrow(d), 0, 110))
d$lane_dev <- round(0.25 + cond_ld[d$condition] + 0.0015 * (d$age - 40) +
                      0.0006 * (d$rt_ms - 1050) / 10 + d$v0 +
                      stats::rnorm(nrow(d), 0, 0.05), 3)
d$lane_dev <- pmax(d$lane_dev, 0.02)

# Some missing values: sensor dropouts and one participant without age
d$rt_ms[sample(nrow(d), 12)] <- NA
d$lane_dev[sample(nrow(d), 9)] <- NA
d$age[d$vp_id == "vp17"] <- NA

driving_sim <- d[c("vp_id", "age", "gender", "condition", "trial", "rt_ms", "lane_dev")]
rownames(driving_sim) <- NULL

dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
utils::write.csv(driving_sim, "inst/extdata/driving_sim.csv", row.names = FALSE)
