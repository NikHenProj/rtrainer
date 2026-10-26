# Simulated messy export of an online feedback survey after a remote app study,
# as it comes from a survey tool. Two waves were exported with different
# settings and pasted together by hand, so formats differ between rows.
# The same responses are written twice:
# - data/raw_export.csv: semicolon-separated, decimal comma, 3 lines of export
#   info above the header, a second header row with the question text
# - data/raw_export.xlsx: sheet "Export" (title rows above the header, a total
#   row below the data, wave 1 dates as real Excel dates, wave 2 as text),
#   sheet "Codebook"
# Run from the project root: Rscript data-raw/raw_export.R
#
# Data problems on purpose:
# - column names with spaces, brackets and question codes ("Q1_Age", ...)
# - dates: wave 1 "2026-03-04 10:15:22", wave 2 "04.03.2026 10:15" or
#   "3/4/2026 10:15 AM"
# - age as text: "34 years", "n/a", "-99", "" and one implausible 230
# - gender: female/Female/F/woman, male/M/"Male ", diverse, empty
# - device: iPhone/iphone/"iPhone 15", Android/"android phone", Desktop/"desktop PC"
# - satisfaction items as text labels (Strongly disagree ... Strongly agree)
# - recommend (0-10) with -99 as missing code
# - duration with decimal comma
# - 2 test responses (Status "Survey Preview", Response ID "TEST_1", "TEST_2")
# - R_0031 and R_0058 submitted twice (identical rows)
# - comments: free text with semicolons, quotes, a line break

set.seed(20261029)

n <- 78
agree_labels <- c(
  "Strongly disagree", "Disagree", "Neither agree nor disagree",
  "Agree", "Strongly agree"
)

wave <- rep(1:2, times = c(44, n - 44))
start <- as.POSIXct("2026-03-02 08:00:00", tz = "UTC") +
  sort(stats::runif(n, 0, 21 * 24 * 3600))
duration <- round(stats::rlnorm(n, log(330), 0.35), 1)
end <- start + duration

format_start <- function(x, wave) {
  wave2_style <- sample(c("de", "us"), length(x), replace = TRUE)
  ifelse(
    wave == 1,
    format(x, "%Y-%m-%d %H:%M:%S"),
    ifelse(
      wave2_style == "de",
      format(x, "%d.%m.%Y %H:%M"),
      paste(
        as.integer(format(x, "%m")), "/", as.integer(format(x, "%d")), "/",
        format(x, "%Y "), format(x, "%I:%M "),
        ifelse(as.integer(format(x, "%H")) < 12, "AM", "PM"),
        sep = ""
      )
    )
  )
}

age <- round(pmin(pmax(stats::rnorm(n, 36, 11), 18), 70))
age_text <- as.character(age)
age_text[sample(n, 6)] <- paste(age[sample(n, 6)], "years")
age_text[c(9, 52)] <- "n/a"
age_text[c(17, 66)] <- "-99"
age_text[40] <- ""
age_text[23] <- "230"

gender <- sample(
  c("female", "Female", "F", "woman", "male", "M", "Male ", "diverse", ""),
  n,
  replace = TRUE,
  prob = c(0.2, 0.12, 0.08, 0.06, 0.24, 0.12, 0.08, 0.04, 0.06)
)
device <- sample(
  c("iPhone", "iphone", "iPhone 15", "Android", "android phone", "Desktop", "desktop PC"),
  n,
  replace = TRUE,
  prob = c(0.2, 0.1, 0.08, 0.25, 0.1, 0.17, 0.1)
)

satisfaction <- stats::rnorm(n)
agree_item <- function(loading) {
  agree_labels[findInterval(loading * satisfaction + stats::rnorm(n, 0, 0.6), c(-1.3, -0.5, 0.3, 1.1)) + 1]
}
recommend <- pmin(pmax(round(7 + 1.8 * satisfaction + stats::rnorm(n, 0, 1)), 0), 10)
recommend[c(12, 48, 71)] <- -99

comment_pool <- c(
  "", "", "", "", "", "",
  "Search was quick.",
  "Filter button hard to find; I scrolled for a while",
  "The \"compare\" view is great",
  "Checkout asked for my address twice",
  "Too many steps at checkout.\nOtherwise fine.",
  "ok",
  "Font too small on my phone",
  "Liked the dark mode; please keep it",
  "Crashed once when I pressed back",
  "-",
  "Would use it again"
)
comments <- sample(comment_pool, n, replace = TRUE)

raw <- data.frame(
  `Response ID` = sprintf("R_%04d", seq_len(n)),
  `Start Date` = format_start(start, wave),
  `End Date` = format_start(end, wave),
  Status = "IP Address",
  `Duration (in seconds)` = duration,
  Finished = "TRUE",
  Q1_Age = age_text,
  Q2_Gender = gender,
  `Q3 Device` = device,
  Q4_1 = agree_item(0.8),
  Q4_2 = agree_item(0.7),
  Q4_3 = agree_item(-0.7),
  `Q5 (0-10)` = recommend,
  `Q6 - Comments` = comments,
  check.names = FALSE
)
raw$Finished[c(5, 61)] <- "FALSE"
raw$Q4_2[c(5, 61)] <- ""
raw$Q4_3[c(5, 61)] <- ""

test_rows <- raw[c(1, 2), ]
test_rows$`Response ID` <- c("TEST_1", "TEST_2")
test_rows$Status <- "Survey Preview"
test_rows$`Start Date` <- c("2026-03-01 17:02:11", "2026-03-01 17:09:40")
test_rows$`End Date` <- c("2026-03-01 17:03:01", "2026-03-01 17:10:05")
test_rows$`Q6 - Comments` <- c("test test", "ignore")

raw <- rbind(test_rows, raw)
duplicates <- which(raw$`Response ID` %in% c("R_0031", "R_0058"))
raw <- raw[sort(c(seq_len(nrow(raw)), duplicates)), ]
raw$` ` <- ""

question_text <- c(
  "Response ID", "Start Date", "End Date", "Response Type", "Duration (in seconds)",
  "Finished", "How old are you?", "What is your gender?", "Which device did you use?",
  "The app was easy to use.", "I found what I was looking for.",
  "The app was confusing.",
  "How likely are you to recommend the app to a friend? (0-10)",
  "Any other comments?", ""
)

dir.create("data", showWarnings = FALSE)

# CSV: semicolon, decimal comma, export info above the header
csv_file <- "data/raw_export.csv"
writeLines(
  c(
    "Survey export: App feedback (remote study)",
    "Exported: 2026-03-24 09:12 by study admin",
    ""
  ),
  csv_file
)
header <- rbind(question_text)
colnames(header) <- names(raw)
csv_body <- rbind(header, format(raw, decimal.mark = ",", trim = TRUE))
suppressWarnings(utils::write.table(
  csv_body,
  csv_file,
  sep = ";",
  row.names = FALSE,
  qmethod = "double",
  append = TRUE,
  fileEncoding = "UTF-8"
))

# XLSX: title rows, wave 1 dates as Excel dates, total row, codebook sheet
is_wave1 <- grepl("^\\d{4}-", raw$`Start Date`) & !startsWith(raw$`Response ID`, "TEST")
wb <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb, "Export")
openxlsx::writeData(wb, "Export", "Survey export: App feedback (remote study)", startRow = 1)
openxlsx::writeData(wb, "Export", "Exported: 2026-03-24 09:12 by study admin", startRow = 2)
openxlsx::writeData(wb, "Export", raw[, names(raw) != " "], startRow = 4)
for (i in which(is_wave1)) {
  openxlsx::writeData(
    wb,
    "Export",
    as.POSIXct(raw$`Start Date`[i], tz = "UTC"),
    startCol = 2,
    colNames = FALSE,
    startRow = 4 + i
  )
}
openxlsx::addStyle(
  wb,
  "Export",
  openxlsx::createStyle(numFmt = "yyyy-mm-dd hh:mm"),
  rows = 4 + which(is_wave1),
  cols = 2
)
openxlsx::writeData(
  wb,
  "Export",
  sprintf("Total responses: %d", nrow(raw)),
  startRow = 4 + nrow(raw) + 2
)
openxlsx::addWorksheet(wb, "Codebook")
openxlsx::writeData(
  wb,
  "Codebook",
  data.frame(variable = names(raw)[names(raw) != " "], question = question_text[-15])
)
openxlsx::saveWorkbook(wb, "data/raw_export.xlsx", overwrite = TRUE)
