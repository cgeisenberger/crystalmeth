# attach necessary packages
library(minfi)
library(conumee)



# Normal Controls for CNV plots -----

# Illumina 450K platform
ctrl_dir <- "./data-raw/controls450k/"
ctrl_basenames <- list.files(path = ctrl_dir, pattern = "_Grn.idat")
ctrl_basenames <- stringr::str_remove(ctrl_basenames, "_Grn.idat")

ctrl_raw <- minfi::read.metharray(basenames = file.path(ctrl_dir, ctrl_basenames))
NormalControls450k <- minfi::preprocessIllumina(ctrl_raw)

usethis::use_data(NormalControls450k, overwrite = TRUE)

# Illumina EPIC platform
ctrl_dir <- "./data-raw/controlsEpic/"
ctrl_basenames <- list.files(path = ctrl_dir, pattern = "_Grn.idat")
ctrl_basenames <- stringr::str_remove(ctrl_basenames, "_Grn.idat")

ctrl_raw <- minfi::read.metharray(basenames = file.path(ctrl_dir, ctrl_basenames))
NormalControlsEpic <- minfi::preprocessIllumina(ctrl_raw)

usethis::use_data(NormalControlsEpic, overwrite = TRUE)



# Annotation for Conumee CNV plots -----

# Illumina 450K platform
ConumeeAnno450k <- conumee::CNV.create_anno(array_type = "450k")
usethis::use_data(ConumeeAnno450k, overwrite = TRUE)

# Illumina EPIC platform
ConumeeAnnoEpic <- conumee::CNV.create_anno(array_type = "EPIC")
usethis::use_data(ConumeeAnnoEpic, overwrite = TRUE)

