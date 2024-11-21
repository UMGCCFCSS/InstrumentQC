Main <- file.path("C:", "Users", "12692", "Documents", "InstrumentQC")
AnyFlags <- list.files(Main, pattern="Flag.csv", full.names=TRUE)

if (!length(AnyFlags) == 0){
  TheCSV <- file.path(Main, "Flag.csv")
  file.remove(TheCSV)
}


