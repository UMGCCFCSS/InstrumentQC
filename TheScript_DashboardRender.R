library(git2r)
OneDrive <- file.path("C:", "Users", "drach", "OneDrive - University of Maryland School of Medicine")
RepositoryPath <- file.path(OneDrive, "Documents", "InstrumentQC")
TheRepo <- repository(RepositoryPath)
git2r::pull(TheRepo)

#library(quarto)
#quarto::quarto_render(input=RepositoryPath, output_format="all")

# Stage to Git
add(TheRepo, "*")

TheCommitMessage <- paste0("Updated dashboard on ", Today)
commit(TheRepo, message = TheCommitMessage)
cred <- cred_token(token = "GITHUB_PAT")
push(TheRepo, credentials = cred)
