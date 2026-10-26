# Simulated moderated usability test of three app prototypes (within subjects).
# 24 participants (12 novice, 12 expert users) x 3 prototypes (A, B, C)
# x 4 tasks; prototype order counterbalanced with a Latin square (position 1-3).
# Per task: success (0/1), time_s (timeout 180 s), errors (count),
# seq = Single Ease Question (1-7).
# Run from the project root: Rscript data-raw/usability.R
#
# Built-in effects (population values):
# - success: baseline 75 % (A); B +1.0 logit (about 87 %), C -0.3 logit
# - time: C 20 % faster than A, B 10 % faster; expert users 25 % faster;
#   learning: -8 % per position; task difficulty: checkout slowest
# - errors: Poisson, B halves the error rate; failed tasks have more errors
# - seq rises with success and falls with time
# Data problems on purpose:
# - failed tasks that hit the timeout have time_s = 180 (censored)
# - p07 aborted the session: prototype C missing entirely (no rows)
# - 3 seq ratings missing (participant did not answer)

set.seed(20261028)

n_participants <- 24
prototypes <- c("A", "B", "C")
tasks <- c("search", "filter", "compare", "checkout")
latin_square <- list(c("A", "B", "C"), c("B", "C", "A"), c("C", "A", "B"))

participants <- tibble::tibble(
  participant = sprintf("p%02d", seq_len(n_participants)),
  expertise = rep(c("novice", "expert"), times = n_participants / 2),
  sequence = rep(1:3, length.out = n_participants),
  u_success = stats::rnorm(n_participants, 0, 0.7),
  u_time = stats::rnorm(n_participants, 0, 0.18)
)

effect_success <- c(A = 0, B = 1.0, C = -0.3)
effect_time <- c(A = 0, B = log(0.9), C = log(0.8))
effect_errors <- c(A = 1, B = 0.5, C = 1)
task_time <- c(search = 35, filter = 45, compare = 60, checkout = 85)
task_success <- c(search = 0.6, filter = 0.2, compare = -0.2, checkout = -0.4)

usability <- participants |>
  dplyr::mutate(
    prototype = lapply(sequence, \(s) latin_square[[s]]),
    position = list(1:3)
  ) |>
  tidyr::unnest(c(prototype, position)) |>
  tidyr::expand_grid(task = tasks) |>
  dplyr::mutate(
    p_success = stats::plogis(
      1.1 + effect_success[prototype] + task_success[task] + u_success +
        ifelse(expertise == "expert", 0.5, 0)
    ),
    success = stats::rbinom(dplyr::n(), 1, p_success),
    time_s = task_time[task] *
      exp(
        effect_time[prototype] +
          ifelse(expertise == "expert", log(0.75), 0) +
          log(0.92) * (position - 1) +
          ifelse(success == 1, 0, 0.9) +
          u_time +
          stats::rnorm(dplyr::n(), 0, 0.3)
      ),
    time_s = round(pmin(time_s, 180), 1),
    errors = stats::rpois(
      dplyr::n(),
      effect_errors[prototype] * ifelse(success == 1, 0.6, 2.2)
    ),
    seq = round(
      5.2 + 1.2 * (success - 0.75) - 0.02 * (time_s - 50) +
        stats::rnorm(dplyr::n(), 0, 0.8)
    ),
    seq = as.integer(pmin(pmax(seq, 1), 7))
  )

usability <- usability |>
  dplyr::filter(!(participant == "p07" & prototype == "C"))
usability$seq[sample(nrow(usability), 3)] <- NA

usability <- usability |>
  dplyr::arrange(participant, position, match(task, tasks)) |>
  dplyr::select(
    participant, expertise, position, prototype, task,
    success, time_s, errors, seq
  )

dir.create("data", showWarnings = FALSE)
utils::write.csv(usability, "data/usability.csv", row.names = FALSE)
