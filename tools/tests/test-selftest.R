test_that("selftest passes when solution passes and starter fails", {
  dir <- withr::local_tempdir()
  make_course(dir)
  res <- selftest(dir)
  expect_true(res$solution_passes)
  expect_true(res$starter_fails)
})

test_that("selftest flags a starter that already passes", {
  dir <- withr::local_tempdir()
  make_course(dir, exercises = list(toy_exercise(starter = "sum(toy$x) / 4")))
  res <- selftest(dir)
  expect_true(res$solution_passes)
  expect_false(res$starter_fails)
  expect_match(res$message, "starter passes")
})

test_that("selftest reports a failing solution", {
  dir <- withr::local_tempdir()
  make_course(dir, exercises = list(toy_exercise(solution = "stop('boom')")))
  res <- selftest(dir)
  expect_false(res$solution_passes)
  expect_match(res$message, "boom")
})

test_that("all course exercises pass the self-test", {
  res <- selftest(root)
  expect_true(all(res$solution_passes & res$starter_fails))
})
