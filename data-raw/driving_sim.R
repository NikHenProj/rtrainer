# Simulated driving-simulator study: take-over requests (TOR) with three
# warning modalities (within), two experience groups (between),
# 40 participants, 4 repeated trials per condition.
# Run from the project root: Rscript data-raw/driving_sim.R
#
# Built-in effects (population values):
# - condition: visual +180 ms, auditory 0 ms, haptic -70 ms (reaction time)
# - experience: experienced -120 ms vs. novice (about d = 0.9 on person means)
# - trial: -25 ms per trial (learning), random slopes per participant
# - age: +4 ms per year
# - lane_dev rises with reaction time and for visual warnings
# Missing values: 12 rt_ms (sensor dropouts), 9 lane_dev, age of p17.

set.seed(20261026)

n_participants <- 40
conditions <- c("visual", "auditory", "haptic")
n_trials <- 4

participants <- tibble::tibble(
  participant = sprintf("p%02d", seq_len(n_participants)),
  experience = rep(c("novice", "experienced"), each = n_participants / 2),
  age = round(stats::runif(n_participants, 19, 68)),
  gender = sample(
    c("female", "male", "diverse"),
    n_participants,
    replace = TRUE,
    prob = c(0.48, 0.48, 0.04)
  ),
  u0 = stats::rnorm(n_participants, 0, 110),
  u1 = stats::rnorm(n_participants, 0, 12),
  v0 = stats::rnorm(n_participants, 0, 0.04)
)

effect_rt <- c(visual = 180, auditory = 0, haptic = -70)
effect_lane <- c(visual = 0.06, auditory = 0, haptic = -0.02)

driving_sim <- tidyr::expand_grid(
  participant = participants$participant,
  condition = conditions,
  trial = seq_len(n_trials)
) |>
  dplyr::left_join(participants, by = "participant") |>
  dplyr::mutate(
    rt_ms = round(
      1050 +
        effect_rt[condition] +
        ifelse(experience == "experienced", -120, 0) +
        4 * (age - 40) +
        (-25 + u1) * (trial - 1) +
        u0 +
        stats::rnorm(dplyr::n(), 0, 110)
    ),
    lane_dev = round(
      0.25 +
        effect_lane[condition] +
        0.0015 * (age - 40) +
        0.00006 * (rt_ms - 1050) +
        v0 +
        stats::rnorm(dplyr::n(), 0, 0.05),
      3
    ),
    lane_dev = pmax(lane_dev, 0.02)
  )

driving_sim$rt_ms[sample(nrow(driving_sim), 12)] <- NA
driving_sim$lane_dev[sample(nrow(driving_sim), 9)] <- NA
driving_sim$age[driving_sim$participant == "p17"] <- NA

driving_sim <- driving_sim |>
  dplyr::select(
    participant, experience, age, gender, condition, trial, rt_ms, lane_dev
  )

dir.create("data", showWarnings = FALSE)
utils::write.csv(driving_sim, "data/driving_sim.csv", row.names = FALSE)
