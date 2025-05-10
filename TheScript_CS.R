#git config --global user.email ""
#git config --global user.name ""
#usethis::edit_r_environ()

# Setup in Correct Directory
Linux <- file.path("/home", "david", "Documents", "InstrumentQC")
Windows <- file.path("C:", "Users", "Aurora CS", "Documents", "InstrumentQC")

OperatingSystem <- Sys.info()["sysname"]
if(OperatingSystem == "Linux"){OS <- Linux
} else if (OperatingSystem == "Windows"){OS <- Windows}

WorkingDirectory <- OS
setwd(WorkingDirectory)
source("renv/activate.R")

library(stringr)
library(purrr)

# Find out current date
Today <- Sys.Date()
Today <- as.Date(Today)

# Check for Flag Files
AnyFlags <- list.files(WorkingDirectory, pattern="Flag.csv", full.names=TRUE)

if (length(AnyFlags) == 0){

# Git Pull
RepositoryPath <- WorkingDirectory
TheRepo <- git2r::repository(RepositoryPath)
git2r::pull(TheRepo)

# Locating Archive Folder
Instrument <- "CS"
MainFolder <- file.path(WorkingDirectory, "data")
WorkingFolder <- file.path(WorkingDirectory, "data", Instrument)
StorageFolder <- file.path(WorkingFolder, "Archive")

# Gains
Gains <- list.files(StorageFolder, pattern="Archived", full.names=TRUE)
Gains <- read.csv(Gains[1], check.names = FALSE)
LastGainItem <- Gains |> dplyr::slice(1) |> dplyr::pull(DateTime)
LastGainItem <- lubridate::ymd_hms(LastGainItem)
LastGainItem <- as.Date(LastGainItem)
PotentialGainDays <- seq.Date(from = LastGainItem, to = Today, by = "day")
GainRemoveIndex <- which(PotentialGainDays == LastGainItem)
PotentialGainDays <- PotentialGainDays[-GainRemoveIndex]

# MFIs
MFIs <- list.files(StorageFolder, pattern="Bead", full.names=TRUE)
MFIs <- read.csv(MFIs[1], check.names=FALSE)
LastMFIItem <- MFIs |> dplyr::slice(1) |> dplyr::pull(DateTime)
LastMFIItem <- lubridate::ymd_hms(LastMFIItem)
LastMFIItem <- as.Date(LastMFIItem)
PotentialMFIDays <- seq.Date(from = LastMFIItem, to = Today, by = "day")
MFIRemoveIndex <- which(PotentialMFIDays == LastMFIItem)
PotentialMFIDays <- PotentialMFIDays[-MFIRemoveIndex] 

if (!length(PotentialGainDays) == 0){
# Gain Starting Locations

SetupFolder <- file.path("C:", "CytekbioExport_CS", "Setup")
TheSetupFiles <- list.files(SetupFolder, pattern="DailyQC", full.names=TRUE)

Dates <- as.character(PotentialGainDays)
Dates <- gsub("-", "", Dates)

GainMatches <- TheSetupFiles[str_detect(TheSetupFiles, str_c(Dates, collapse = "|"))]

if (!length(GainMatches) == 0){
file.copy(GainMatches, WorkingFolder)
walk(.x=Instrument, .f=Luciernaga:::DailyQCParse, MainFolder=MainFolder)
}
} else {message("QC data has already been transferred")
  GainMatches <- NULL
  }

if (!length(PotentialMFIDays) == 0){
# MFI Starting Locations

FCSFolder <- file.path("C:", "CytekbioExport_CS", "FcsFiles", "Admin")
MonthStyle <- format(Today, "%Y-%m")
MonthFolder <- paste0("QC ", MonthStyle)
MonthFolder <- file.path(FCSFolder, MonthFolder)
TheFCSFiles <- list.files(MonthFolder, pattern="fcs", full.names=TRUE, recursive=TRUE)

days <- format(PotentialMFIDays, "%d")

MFIMatches <- TheFCSFiles[str_detect(basename(TheFCSFiles), str_c(days, collapse = "|"))]

if (!length(MFIMatches) == 0){
file.copy(MFIMatches, WorkingFolder)
walk(.x=Instrument, .f=Luciernaga:::QCBeadParse, MainFolder=MainFolder)
}
} else {message("QC data has already been transferred")
  MFIMatches <- NULL
  }

if (any(length(PotentialGainDays)|length(PotentialMFIDays) > 0)){
  
  if (any(length(GainMatches)|length(MFIMatches) > 0)){
    # Stage to Git
    git2r::add(TheRepo, "*")
    
    TheCommitMessage <- paste0("Update for ", Instrument, " on ", Today)
    git2r::commit(TheRepo, message = TheCommitMessage)
    cred <- git2r::cred_token(token = "GITHUB_PAT")
    git2r::push(TheRepo, credentials = cred)
    message("Done ", Today)
  } else {message("No files to process ", Today)}
} else {message("No files to process ", Today)}
} else {message("Automation Skipped ", Today)}