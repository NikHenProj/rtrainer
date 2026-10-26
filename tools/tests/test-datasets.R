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
