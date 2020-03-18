library(R6)
library(tidyverse)

# error codes
# 100 = input file error
# 101 = invalid basename (length != 1)
# 102 = input directory does not exist. (File transfer during upload went wrong.)
# 103 = Green idat file does not exist in input directory.
# 104 = Red idat file does not exist in input directory.
# 105 = Unable to read Green IDAT file (Corrupt file?)
# 106 = Unable to read Red IDAT file (Corrupt file?)
# 107 = Number of probes for Red and Green IDAT file do not match
# 108 = Array type not supported


# Bare bones implementation of ClassificationCase Class
# functions are added later via 'ClassificationCase$set'

ClassificationCase <- R6Class("ClassificationCase",
                              public = list(
                                basename = NA,
                                beta_values = NA,
                                class_type = NA,
                                class_votes = NA,
                                cnv = NA,
                                error = FALSE,
                                error_code = NULL,
                                imputed_n = NA,
                                n_probes = NA,
                                normalization_method = NA,
                                normalized_data = NA,
                                path = NA,
                                platform = NA,
                                purity = NA,
                                raw_data = NA,
                                rf = NA,
                                verbose = NA,
                                initialize = function(basename, path, verbose = TRUE) {
                                  self$path <- path
                                  self$basename <- basename
                                  self$verbose <- verbose
                                  self$validate(verbose = self$verbose)
                                }
                              )
)



# initialization function -----
# performs extensive validation of the input files


ClassificationCase$set("public", "validate", function(verbose = TRUE) {

  # check if supplied basename is valid
  if (length(self$basename) != 1) {
    self$terminate(error_code = "101")
    stop()
  }

  if (verbose) message("Initializing object, running standard checks:")
  if (verbose) message("Basename is valid")

  # check if input directory exists
  if (!dir.exists(self$path)) {
    self$terminate(error_code = "102")
    stop()
  }

  if (verbose) message("Input directory exists")

  # check if red and green idat files exist
  file_grn <- file.path(self$path, paste0(self$basename, "_Grn.idat"))
  file_red <- file.path(self$path, paste0(self$basename, "_Red.idat"))

  if (!file.exists(file_grn)) {
    self$terminate(error_code = "103")
    stop()
  }

  if (!file.exists(file_red)) {
    self$terminate(error_code = "104")
    stop()
  }

  if (verbose) message("Input files exists")

  if (verbose) message("Testing if files can be read...")

  # test if arrays can be read and have the same amount of probes
  grn <- tryCatch(expr = {illuminaio::readIDAT(file = file_grn)},
                      error = function() "error")
  red <- tryCatch(expr = {illuminaio::readIDAT(file = file_red)},
                  error = function() "error")

  if (!is.list(grn)){
    self$terminate(error_code = "105")
    stop()
  }

  if (!is.list(red)){
    self$terminate(error_code = "106")
    stop()
  }

  if (verbose) message("Files read successfully!")

  # extract number of physical probes
  nprobes_grn <- nrow(grn[["Quants"]])
  nprobes_red <- nrow(red[["Quants"]])

  # quit if number of probes do not match
  if (nprobes_grn != nprobes_red) {
    self$terminate(error_code = "107")
    stop()
  }

  self$n_probes <- nprobes_grn

  if (verbose) message("Matching number of probes for RED and GRN files")

  # detect platform based on number of probes
  self$platform <- guess_array_type(self$n_probes)

  # quit if array type is unsupported
  supp <- c("IlluminaHumanMethylation450k", "IlluminaHumanMethylationEPIC")

  if (!self$platform %in% supp) {
    self$terminate(error_code = "108")
    stop()
  }

  if (verbose) message(paste0("Detected platform: ", self$platform))
  if (verbose) message("Input checks completed succesfully")
})



# terminator function -----

ClassificationCase$set("public", "terminate", function(error_code) {
  if (length(error_code) != 1){
    stop("Invalid error code")
  } else {
    error_code <- as.character(error_code)
  }
  self$error <- TRUE
  self$error_code <- error_code
  message(paste0("Encountered fatal error, execution stopped (Error code: ", error_code, ")"))
})



# load data -----

ClassificationCase$set("public", "load_data", function(verbose = TRUE) {
  path <- file.path(self$path, self$basename)
  self$raw_data <- minfi::read.metharray(path)
  if (verbose) message(paste0("Successfully loaded data for: ", self$basename))
  invisible(self)
})



# normalization -----

ClassificationCase$set("public", "normalize_data",
                       function(preprocess_function = NULL, verbose = TRUE) {
                         if (is.null(preprocess_function)) {
                           preprocess_function <- minfi::preprocessIllumina
                         }
                         self$normalized_data <- preprocess_function(self$raw_data)
                         self$normalization_method <- unname(self$normalized_data@preprocessMethod[1])
                         if (verbose) message(paste0("Data normalized with Method: ", self$normalization_method))
                         invisible(self)
})



# extract beta values -----

ClassificationCase$set("public", "get_betas", function(verbose = TRUE) {
                         self$beta_values <- minfi::getBeta(self$normalized_data)
                         if (verbose) message("Extracted beta values")
                         invisible(self)
                       })



# missing data imputation -----

ClassificationCase$set("public", "impute_data",
                       function(imputation_function = NULL, verbose = TRUE) {
  # imputation returns (1) matrix and (2) proportion of NAs
  if (is.null(imputation_function)) {
    imputation_function <- impute_random
  }
  imp <- imputation_function(self$beta_values)
  # update beta values in place
  self$beta_values <- imp$imputed
  self$imputed_n <- imp$n
  if (verbose) message(paste0("Imputed data for n = ", imp$n, " probes"))
  invisible(self)
})



# run classification -----

ClassificationCase$set("public", "run_classification", function(rf_object, verbose = TRUE) {
  self$rf <- rf_object
  # extract variables
  vars <- get_rf_variables(self$rf)
  # select beta values
  input_data <- self$beta_values[vars, ,drop = FALSE]
  self$class_type <- predict(object = self$rf, newdata = t(input_data), type = "response")
  self$class_votes <- predict(object = self$rf, newdata = t(input_data), type = "vote")
  if (verbose) message("Classification completed")
  invisible(self)
})



# generate copy number profiles -----

ClassificationCase$set("public", "prepare_cnv", function(verbose = TRUE) {

  # pick prepared annotation and normal controls for platform
  anno <- switch(self$platform,
                 IlluminaHumanMethylationEPIC = get("ConumeeAnnoEpic"),
                 IlluminaHumanMethylation450k = get("ConumeeAnno450k"))
  ctrls <- switch(self$platform,
                  IlluminaHumanMethylationEPIC = get("NormalControlsEpic"),
                  IlluminaHumanMethylation450k = get("NormalControls450k"))

  # run conumee workflow
  sample <- conumee::CNV.load(self$normalized_data)
  ctrls <- conumee::CNV.load(ctrls)
  cnv_fit <- conumee::CNV.fit(query = sample, ref = ctrls, anno = anno)
  cnv_binned <- conumee::CNV.bin(cnv_fit)
  self$cnv <- conumee::CNV.segment(cnv_binned)
  if (verbose) message("Successfully computed CNV profile")
  invisible(self)
})



# perform tumor purity estimation -----

ClassificationCase$set("public", "estimate_purity", function(verbose = TRUE) {

  betas <- self$beta_values

  # load RF purity estimation objects
  rf_absolute <- get("RFpurify_ABSOLUTE")
  rf_estimate <- get("RFpurify_ESTIMATE")

  # extract variables used for classifier
  vars_absolute <- get_rf_variables(rf_absolute)
  vars_estimate <- get_rf_variables(rf_estimate)

  # prepare data for purity estimation
  betas_absolute <- betas[match(vars_absolute, rownames(betas)), , drop = FALSE]
  betas_estimate <- betas[match(vars_estimate, rownames(betas)), , drop = FALSE]

  # perform estimation
  purity_absolute <- predict(rf_absolute, t(betas_absolute))
  purity_estimate <- predict(rf_estimate, t(betas_estimate))

  # convert to percentages
  purity_absolute <- round(purity_absolute * 100, digits = 2)
  purity_estimate <- round(purity_estimate * 100, digits = 2)

  # save data
  self$purity = list(absolute = unname(purity_absolute),
                     estimate = unname(purity_estimate))

  if (verbose) message("Tumor purity estimation completed")
  invisible(self)
})



# wrapper for full workflow -----
ClassificationCase$set("public", "run_workflow",
                       function(rf_object, verbose = TRUE) {
                         self$load_data(verbose = verbose)
                         self$normalize_data(verbose = verbose)
                         self$get_betas(verbose = verbose)
                         self$impute_data(verbose = verbose)
                         self$run_classification(rf_object = rf_object, verbose = verbose)
                         self$prepare_cnv(verbose = verbose)
                         self$estimate_purity(verbose = verbose)
})




