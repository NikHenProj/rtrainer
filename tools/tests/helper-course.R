root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
source(file.path(root, "tools", "checks.R"))
source(file.path(root, "tools", "generate.R"))
source(file.path(root, "tools", "selftest.R"))

# A valid exercise as a list; tests modify single fields.
toy_exercise <- function(...) {
  ex <- list(
    id = "toy-b-mean",
    lesson = "toy-beginner",
    order = 1,
    title = list(de = "Mittelwert", en = "Mean"),
    kind = "write",
    required = TRUE,
    packages = list(),
    data = list("toy"),
    setup = "",
    prompt = list(de = "Berechne den Mittelwert von `x`.", en = "Compute the mean of `x`."),
    starter = "toy$x",
    solution = "mean(toy$x)",
    hints = list(list(de = "Nutze `mean()`.", en = "Use `mean()`.")),
    explanation = list(de = "Der Mittelwert.", en = "The mean."),
    check = list(type = "value"),
    common_mistakes = list(
      list(pattern = "median\\(", message = list(de = "Nicht der Median.", en = "Not the median."))
    )
  )
  changes <- list(...)
  ex[names(changes)] <- changes
  ex
}

toy_quiz <- function() {
  list(
    lesson = "toy-beginner",
    pass = 0.8,
    questions = list(list(
      id = "toy-q1",
      prompt = list(de = "Frage?", en = "Question?"),
      options = list(
        list(text = list(de = "Ja", en = "Yes"), correct = TRUE, explain = list(de = "Gut.", en = "Good.")),
        list(text = list(de = "Nein", en = "No"), correct = FALSE, explain = list(de = "Falsch.", en = "Wrong."))
      )
    ))
  )
}

# Write a minimal course (one topic, one lesson) into `dir`.
make_course <- function(dir, exercises = list(toy_exercise()), quiz = toy_quiz(),
                        front_matter = "engine: markdown\nwebr:\n  packages: []\nresources:\n  - ../data/toy.csv") {
  dir.create(file.path(dir, "tools"), recursive = TRUE)
  file.copy(file.path(root, "tools", "checks.R"), file.path(dir, "tools"))
  dir.create(file.path(dir, "data"))
  utils::write.csv(data.frame(x = c(1, 2, 3, 10)), file.path(dir, "data", "toy.csv"), row.names = FALSE)
  yaml::write_yaml(
    list(toy = list(file = "toy.csv", load = 'toy <- read.csv("data/toy.csv")')),
    file.path(dir, "data", "datasets.yml")
  )
  yaml::write_yaml(list(
    levels = list(
      list(id = "beginner", title = list(de = "Beginner", en = "Beginner")),
      list(id = "intermediate", title = list(de = "Intermediate", en = "Intermediate"))
    ),
    topics = list(
      list(slug = "toy", levels = list("beginner", "intermediate"), title = list(de = "Spielzeug", en = "Toy")),
      list(slug = "next", levels = list("beginner"), title = list(de = "Danach", en = "Next"))
    )
  ), file.path(dir, "curriculum.yml"))
  lesson_dir <- file.path(dir, "exercises", "toy", "beginner")
  dir.create(lesson_dir, recursive = TRUE)
  yaml::write_yaml(list(
    lesson = "toy-beginner", minutes = 10, prerequisites = list("next-beginner"),
    packages = list(), data = list("toy"),
    goals = list(de = list("Mittelwert"), en = list("Mean"))
  ), file.path(lesson_dir, "lesson.yml"))
  for (i in seq_along(exercises)) {
    yaml::write_yaml(exercises[[i]], file.path(lesson_dir, sprintf("%02d-%s.yml", i, exercises[[i]]$id)))
  }
  if (!is.null(quiz)) yaml::write_yaml(quiz, file.path(lesson_dir, "quiz.yml"))
  dir.create(file.path(dir, "de"))
  writeLines(c("---", "title: Toy", front_matter, "---", ""), file.path(dir, "de", "toy-beginner.qmd"))
  invisible(dir)
}
