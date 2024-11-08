library(dplyr)
library(purrr)
library(lubridate)
library(Luciernaga)
library(flowWorkspace)

LevyJenningsParse <- function(MainFolder, x, Maintainer=FALSE){

  Folder <- file.path(MainFolder, x)
  LJTrackingFiles <- list.files(Folder, pattern="LJ",
                                full.names = TRUE)

  if (!length(LJTrackingFiles)==0){

    if (length(LJTrackingFiles)==1){

      Parsed <- QC_FilePrep(x=LJTrackingFiles, TrackChange=FALSE)
      Parsed <- Parsed %>% mutate(across(starts_with("Flag"), ~ as.logical(.)))

    } else {stop("Two csv files in the folder found!")}

    TheArchive <- file.path(Folder, "Archive")
    ArchivedDataFile <- list.files(TheArchive, pattern="Archived",
                                   full.names = TRUE)

    if (!length(ArchivedDataFile)==0){

      if(length(ArchivedDataFile)==1){
        ArchivedData <- read.csv(ArchivedDataFile, check.names=FALSE)
      } else {message("Two csv files in the folder found!")}

      # Troubleshooting
      if (!ncol(ArchivedData) == ncol(Parsed)){

       if (Maintainer==TRUE){
        TheseColumns <- setdiff(colnames(Parsed), colnames(ArchivedData))

        for (col in TheseColumns) {
          ArchivedData[[col]] <- NA
        }

       if (!ncol(ArchivedData) == ncol(Parsed)){stop("Still no rescue")}

       } else {
       stop("The number of columns for the new data don't match
       that of the archived data. Please make sure to
       export the Levy-Jennings trackings with all available
       parameters")
       }
      }

      ArchivedData$DateTime <- ymd_hms(ArchivedData$DateTime)
      ArchivedData <- ArchivedData %>% mutate(across(starts_with("Flag"), ~ as.logical(.)))
      NewData <- generics::setdiff(Parsed, ArchivedData)
      UpdatedData <- rbind(NewData, ArchivedData)

      file.remove(ArchivedDataFile)

      } else {UpdatedData <- Parsed}

      file.remove(LJTrackingFiles)

      name <- paste0("ArchivedData", x, ".csv")
      StorageLocation <- file.path(TheArchive, name)
      write.csv(UpdatedData, StorageLocation, row.names=FALSE)
  } else {message("No LevyJennings files to update with in ", x)}

}

QCBeadParse <- function(x, MainFolder){
  Folder <- file.path(MainFolder, x)
  FCS_Files <- list.files(Folder, pattern="fcs", full.names=TRUE)

  if(!length(FCS_Files) == 0){

    QCBeads <- FCS_Files[grep("Before|After", FCS_Files)]
    BeforeAfter_CS <- load_cytoset_from_fcs(files=QCBeads,
                                            transformation=FALSE, truncate_max_range = FALSE)

    BeforeAfter <- map(.x=BeforeAfter_CS, .f=QC_GainMonitoring,
                       sample.name = "TUBENAME", stats="median") %>% bind_rows()

    BeforeAfter <- BeforeAfter %>% mutate(DateTime = DATE+TIME) %>%
      relocate(DateTime, .before=DATE)

    ArchiveFolder <- file.path(Folder, "Archive")
    ArchiveCSV <- list.files(ArchiveFolder, pattern="Bead", full.names=TRUE)

    if (length(ArchiveCSV) == 1){
      ArchiveData <- read.csv(ArchiveCSV, check.names=FALSE)
      ArchiveData$DateTime <- ymd_hms(ArchiveData$DateTime)
      ArchiveData$DATE <- ymd(ArchiveData$DATE)
      ArchiveData$TIME <- hms(ArchiveData$TIME)
      Export <- ArchiveData %>% arrange(desc(DateTime))
      #write.csv(Export, "BeadData5L.csv", row.names=FALSE)

      if (ncol(BeforeAfter) == ncol(ArchiveData)){
        NewData <- generics::setdiff(BeforeAfter, ArchiveData)
        AssembledData <- rbind(NewData, ArchiveData)
        Export <- AssembledData %>% arrange(desc(DateTime))

        file.remove(ArchiveCSV)

        name <- paste0("BeadData", x, ".csv")
        StorageLocation <- file.path(ArchiveFolder, name)

        write.csv(Export, StorageLocation, row.names=FALSE)

        file.remove(FCS_Files)

      } else {
        stop("The number of columns for the new data don't match
       that of the archived data. Please reach out")
      }
    } else {stop("Two BeadData csv files in the archive folder!")}


  } else {message("No fcs files to update with in ", x)}

}

walk(.x=TheList, MainFolder=MainFolder, .f=LevyJenningsParse, Maintainer=FALSE)
walk(.x=TheList, .f=QCBeadParse, MainFolder=MainFolder)
