#git config --global user.email ""
#git config --global user.name ""


message("This is part of the UMGCC FCSS automated instrument QC proccess. It runs automatically at 10 AM, taking about a minute. Please ignore, the window will close on its own once files are copied. Thanks!")

library(dplyr)
library(stringr)
library(lubridate)

Today <- Sys.Date()
Today <- as.Date(Today)

Instrument <- "CS"
WorkingDirectory <- getwd()
MainFolder <- file.path(WorkingDirectory, "data")
WorkingFolder <- file.path(WorkingDirectory, "data", Instrument)
StorageFolder <- file.path(WorkingFolder, "Archive")

# Gains
Gains <- list.files(StorageFolder, pattern="Archived", full.names=TRUE)
Gains <- read.csv(Gains, check.names = FALSE)
LastGainItem <- Gains %>% slice(1) %>% pull(DateTime)
LastGainItem <- ymd_hms(LastGainItem)
LastGainItem <- as.Date(LastGainItem)
PotentialGainDays <- seq.Date(from = LastGainItem, to = Today, by = "day")

# MFIs
MFIs <- list.files(StorageFolder, pattern="Bead", full.names=TRUE)
MFIs <- read.csv(MFIs, check.names=FALSE)
LastMFIItem <- MFIs %>% slice(1) %>% pull(DateTime)
LastMFIItem <- ymd_hms(LastMFIItem)
LastMFIItem <- as.Date(LastMFIItem)
PotentialMFIDays <- seq.Date(from = LastMFIItem, to = Today, by = "day")

# Gain Starting Locations

SetupFolder <- file.path("C:", "CytekbioExport", "Setup")
TheSetupFiles <- list.files(SetupFolder, pattern="DailyQC", full.names=TRUE)

Dates <- as.character(PotentialGainDays)
Dates <- gsub("-", "", Dates)

GainMatches <- TheSetupFiles[str_detect(TheSetupFiles, str_c(Dates, collapse = "|"))]

# MFI Starting Locations

FCSFolder <- file.path("C:", "CytekbioExport", "FcsFiles", "Experiments", 
                       "TestLocation")
TheFCSFiles <- list.files(FCSFolder, pattern=".fcs", full.names=TRUE)

days <- format(PotentialMFIDays, "%d")

MFIMatches <- TheFCSFiles[str_detect(TheFCSFiles, str_c(days, collapse = "|"))]

# Copy Over
file.copy(GainMatches, WorkingFolder)
file.copy(MFIMatches, WorkingFolder)

# Process Start

walk(.x=Instrument, .f=Luciernaga:::DailyQCParse, MainFolder=MainFolder, Maintainer=FALSE)
walk(.x=Instrument, .f=Luciernaga:::QCBeadParse, MainFolder=MainFolder)

# Stage to Git
#RepositoryMainFolder <- getwd() #Need to set at beggining?
#setwd(RepositoryMainFolder)
#system("git add .")
#commit_message <- paste0("Update for ", Instrument, " on ", Today)
#system(paste("git commit -m", shQuote(commit_message)))






