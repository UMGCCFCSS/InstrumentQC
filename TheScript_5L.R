#git config --global user.email ""
#git config --global user.name ""
#usethis::edit_r_environ()

WorkingDirectory <- "C:/Users/Aurora/Documents/InstrumentQC"

setwd(WorkingDirectory)

message("This is part of the UMGCC FCSS automated instrument QC proccess. It runs automatically at 10 AM, taking about a minute. Please ignore, the window will close on its own once files are copied. Thanks!")

AnyFlags <- list.files(WorkingDirectory, pattern="Flag.csv", full.names=TRUE)

if (length(AnyFlags) == 0){

library(git2r)
RepositoryPath <- "C:/Users/Aurora/Documents/InstrumentQC"
TheRepo <- repository(RepositoryPath)
git2r::pull(TheRepo)

library(dplyr)
library(stringr)
library(lubridate)
library(purrr)

Today <- Sys.Date()
Today <- as.Date(Today)

Instrument <- "5L"

WorkingDirectory <- "C:/Users/Aurora/Documents/InstrumentQC"
MainFolder <- file.path(WorkingDirectory, "data")
WorkingFolder <- file.path(WorkingDirectory, "data", Instrument)
StorageFolder <- file.path(WorkingFolder, "Archive")

# Gains
Gains <- list.files(StorageFolder, pattern="Archived", full.names=TRUE)
Gains <- read.csv(Gains[1], check.names = FALSE)
LastGainItem <- Gains %>% dplyr::slice(1) %>% dplyr::pull(DateTime)
LastGainItem <- lubridate::ymd_hms(LastGainItem)
#LastGainItem <- lubridate::mdy_hm(LastGainItem)
LastGainItem <- as.Date(LastGainItem)
PotentialGainDays <- seq.Date(from = LastGainItem, to = Today, by = "day")
GainRemoveIndex <- which(PotentialGainDays == LastGainItem)
PotentialGainDays <- PotentialGainDays[-GainRemoveIndex]

# MFIs
MFIs <- list.files(StorageFolder, pattern="Bead", full.names=TRUE)
MFIs <- read.csv(MFIs[1], check.names=FALSE)
LastMFIItem <- MFIs %>% dplyr::slice(1) %>% dplyr::pull(DateTime)
#LastMFIItem <- MFIs %>% dplyr::slice(1) %>% dplyr::pull(DATE)
LastMFIItem <- ymd_hms(LastMFIItem)
#LastMFIItem <- mdy(LastMFIItem)
LastMFIItem <- as.Date(LastMFIItem)
PotentialMFIDays <- seq.Date(from = LastMFIItem, to = Today, by = "day")
MFIRemoveIndex <- which(PotentialMFIDays == LastMFIItem)
PotentialMFIDays <- PotentialMFIDays[-MFIRemoveIndex]

if (!length(PotentialGainDays) == 0){
# Gain Starting Locations

SetupFolder <- file.path("C:", "CytekbioExport", "Setup")
TheSetupFiles <- list.files(SetupFolder, pattern="DailyQC", full.names=TRUE)

Dates <- as.character(PotentialGainDays)
Dates <- gsub("-", "", Dates)

GainMatches <- TheSetupFiles[str_detect(TheSetupFiles, str_c(Dates, collapse = "|"))]

if (!length(GainMatches) == 0){
  file.copy(GainMatches, WorkingFolder)
  walk(.x=Instrument, .f=Luciernaga:::DailyQCParse, MainFolder=MainFolder)
}
}
  
if (!length(PotentialMFIDays) == 0){
# MFI Starting Locations

FCSFolder <- file.path("D:", "Aurora 5_FCS Files", "Experiments", "Admin")
MonthStyle <- format(Today, "%Y-%m")
MonthFolder <- paste0("QC_", MonthStyle)
MonthFolder <- file.path(FCSFolder, MonthFolder)
TheFCSFiles <- list.files(MonthFolder, pattern="fcs", full.names=TRUE, recursive=TRUE)

days <- format(PotentialMFIDays, "%d")

MFIMatches <- TheFCSFiles[str_detect(basename(TheFCSFiles), str_c(days, collapse = "|"))]

if (!length(MFIMatches) == 0){
file.copy(MFIMatches, WorkingFolder)
walk(.x=Instrument, .f=Luciernaga:::QCBeadParse, MainFolder=MainFolder)
}
}

if (!any(length(PotentialGainDays)|length(PotentialMFIDays) == 0)){
# Stage to Git
add(TheRepo, "*")

TheCommitMessage <- paste0("Update for ", Instrument, " on ", Today)
commit(TheRepo, message = TheCommitMessage)
cred <- cred_token(token = "GITHUB_PAT")
push(TheRepo, credentials = cred)
} else {message("No files to process")}

} else {message("Automation Skipped")}
