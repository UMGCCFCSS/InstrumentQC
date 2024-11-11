This repository contains the code for the Instrument QC dashboard for the [UMGCC FCSS](https://www.medschool.umaryland.edu/cibr/core/umgccc_flow/) Cytek Auroras. 

Instrument QC is carried out daily using [SpectroFlo QC beads](https://cytekbio.com/products/spectroflo-qc-beads-2000-series?variant=11145972580388). A before and after acquisition .fcs file of 3000 beads is acquired separately from automated QC to track changes in MFI. 

The before and after QC .fcs file and the Levy-Jennings tracking .csv file are then processed in [R](https://www.r-project.org/) using the [Luciernaga](https://github.com/DavidRach/Luciernaga) package. 
The results are then passed to the dashboard, which was created with [Quarto](https://quarto.org/).

Creation of the dashboard and it's maintenance was done by [David Rach](https://github.com/DavidRach). All code is available under the AGPL3-0 copyleft license. 
