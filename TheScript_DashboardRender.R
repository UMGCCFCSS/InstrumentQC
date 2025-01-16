library(git2r)
Local <- file.path("C:", "Users", "12692")
RepositoryPath <- file.path(Local, "Documents", "InstrumentQC")
TheRepo <- repository(RepositoryPath)
git2r::pull(TheRepo)

library(quarto)
QuartoProject <- file.path(RepositoryPath, "InstrumentQC.Rproj")
quarto::quarto_render(input=RepositoryPath)

Today <- Sys.time()
Today <- as.Date(Today)

# Stage to Git
add(TheRepo, "*")

TheCommitMessage <- paste0("Updated dashboard on ", Today)
commit(TheRepo, message = TheCommitMessage)
cred <- cred_token(token = "GITHUB_PAT")
push(TheRepo, credentials = cred)
