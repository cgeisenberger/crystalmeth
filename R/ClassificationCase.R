#' R6 Class Representing a diagnostic sample
#'
#' @description
#' ClassificationCase provides a coherent structure to keep all information
#' of one diagnostic case used for methylation prediction within a single object.
#' @export

ClassificationCase <- R6::R6Class("ClassificationCase",
                              public = list(
                                #' @field array_basename Basename (prefix of IDAT file).
                                array_basename = NA,

                                #' @field array_nprobes Number of array probes.
                                array_nprobes = NA,

                                #' @field array_platform Array platform (auto-detected).
                                array_platform = NA,

                                #' @field array_path Directory containing the input files.
                                array_path = NA,

                                #' @field data_beta Matrix of beta values.
                                data_beta = NA,

                                #' @field data_na_n Number of NA data points.
                                data_na_n = NA,

                                #' @field data_na_probes Names of NA data points.
                                data_na_probes = NA,

                                #' @field data_norm MethylSet with preprocessed data
                                data_norm = NA,

                                #' @field data_norm_method Method used for normalization.
                                data_norm_method = NA,

                                #' @field data_raw RGSet containing raw array data.
                                data_raw = NA,

                                #' @field class_algorithm Object of type "randomForest". Contains the classifier
                                #' object which needs to be supplied while the methods
                                #' run_classification() or run_workflow().
                                class_algorithm = NA,

                                #' @field class_calibration_model Object containing the model for Random Forest
                                #' score calibration. Needs to be compatible with predict() command.
                                class_calibration_model = NA,

                                #' @field class_type Predicted class of sample.
                                class_type = NA,

                                #' @field class_type_calibrated Calibrated predicted class of sample.
                                class_type_calibrated = NA,

                                #' @field class_votes Tibble with n columns and 1 row, where n corresponds
                                #' to the number of classes.
                                class_votes = NA,

                                #' @field class_votes_calibrated Tibble with n columns and 1 row, where n corresponds
                                #' to the number of classes.
                                class_votes_calibrated = NA,

                                #' @field cnv Segmented copy number data created by conumee.
                                cnv = NA,

                                #' @field purity List of length 2 with tumor purities estimated
                                #' with RF_Purify package.
                                purity = NA,

                                #' @field error Boolean, TRUE if error occured during execution
                                #' (default: FALSE).
                                error = FALSE,

                                #' @field error_msg Contains error code if execution failed
                                #' (default: NULL).
                                error_msg = NULL,

                                #' @field verbose Print informative messages (Boolean, default: TRUE).
                                verbose = NA,

                                #' @description
                                #' Create a new ClassificationCase instance.
                                #' @param array_basename Basename of sample.
                                #' @param array_path Directory which contains Red/Grn IDAT files.
                                #' @param verbose Print informative messages (Default: TRUE).
                                #' @return A new `ClassificationCase` object.
                                initialize = function(basename, path, verbose = TRUE) {
                                  self$array_path <- path
                                  self$array_basename <- basename
                                  self$verbose <- verbose
                                  self$validate(verbose = self$verbose)
                                },


                                #' @description
                                #' Perform (extensive) input file checks. After checking whether
                                #' the input files exists, the data are read (to check for corrupt files) and the information
                                #' is further used to investigate whether the files have the same no. of probes. In addition,
                                #' the array type is guessed based on the number of probes. If any of these steps should go wrong,
                                #' the program records an error code to help narrow down the problem.
                                #' @param verbose Print informative messages (Boolean, default: TRUE).
                                #' Inherits from \code{\link{ClassificationCase$new}}.
                                validate = function(verbose = TRUE) {

                                  if (verbose) message("Initializing object:")

                                  # check if supplied basename is valid
                                  if (length(self$array_basename) != 1) {
                                    self$terminate(error_msg = "Invalid Basename")
                                    stop()
                                  }

                                  if (verbose) message("Basename is valid")

                                  # check if input directory exists
                                  if (!dir.exists(self$array_path)) {
                                    self$terminate(error_msg = "Input directory does not exist")
                                    stop()
                                  }

                                  if (verbose) message("Input directory exists")

                                  # check if red and green IDAT files exist
                                  file_grn <- file.path(self$array_path, paste0(self$array_basename, "_Grn.idat"))
                                  file_red <- file.path(self$array_path, paste0(self$array_basename, "_Red.idat"))

                                  if (!file.exists(file_grn)) {
                                    self$terminate(error_msg = "Green channel IDAT file not found.")
                                    stop()
                                  }

                                  if (!file.exists(file_red)) {
                                    self$terminate(error_msg = "Red channel IDAT file not found.")
                                    stop()
                                  }

                                  if (verbose) message("Input files exist")

                                  # test if arrays can be read and have the same amount of probes
                                  grn <- tryCatch(expr = {illuminaio::readIDAT(file = file_grn)},
                                                  error = function() "error")
                                  red <- tryCatch(expr = {illuminaio::readIDAT(file = file_red)},
                                                  error = function() "error")

                                  if (!is.list(grn)){
                                    self$terminate(error_msg = "Green channel IDAT file could not be read.")
                                    stop()
                                  }

                                  if (!is.list(red)){
                                    self$terminate(error_msg = "Red channel IDAT file couldl not be read.")
                                    stop()
                                  }

                                  if (verbose) message("Files read successfully!")

                                  # extract number of physical probes
                                  nprobes_grn <- nrow(grn[["Quants"]])
                                  nprobes_red <- nrow(red[["Quants"]])

                                  # quit if number of probes do not match
                                  if (nprobes_grn != nprobes_red) {
                                    self$terminate(error_msg = "Number of probes differ for Red and Green IDATs.")
                                    stop()
                                  } else {
                                    self$array_nprobes <- nprobes_grn
                                    if (verbose) message("Matching number of probes for RED and GRN files")
                                  }

                                  # detect platform based on number of probes
                                  self$array_platform <- guess_array_type(self$array_nprobes)

                                  # quit if array type is unsupported
                                  supp <- c("IlluminaHumanMethylation450k", "IlluminaHumanMethylationEPIC")

                                  if (!self$array_platform %in% supp) {
                                    self$terminate(error_msg = "Array platform not supported.")
                                    stop()
                                  }

                                  if (verbose) message(paste0("Detected platform: ", self$array_platform))
                                  if (verbose) message("Input checks completed succesfully")
                                },


                                #' @description
                                #' Internal function to terminate processing and process error messages.
                                #' @param error_code Error code encountered.
                                terminate = function(error_msg) {
                                  if (length(error_msg) != 1){
                                    stop("Invalid error code")
                                  } else {
                                    error_msg <- as.character(error_msg)
                                  }
                                  self$error <- TRUE
                                  self$error_msg <- error_msg
                                  message(paste0("Oops, something went wrong (Error: ", error_msg, ")"))
                                },


                                #' @description
                                #' Wrapper around minfi::read.metharray to load raw data for sample.
                                #' @param verbose Print helpful messages (default: TRUE)
                                load_data = function(verbose = TRUE) {
                                  path <- file.path(self$array_path, self$array_basename)
                                  self$data_raw <- minfi::read.metharray(path)
                                  if (verbose) message(paste0("Successfully loaded data for: ", self$array_basename))
                                  invisible(self)
                                },


                                #' @description
                                #' Perform background normalization
                                #' @param preprocess_function Function used for preprocessing of the data.
                                #' If NULL, will use minfi::preprocessIllumina() to perform background
                                #' intensity correction (Default: NULL)
                                #' @param verbose Print helpful messages (default: TRUE)
                                normalize_data = function(preprocess_function = NULL, verbose = TRUE) {
                                  if (is.null(preprocess_function)) {
                                    preprocess_function <- minfi::preprocessIllumina
                                  }
                                  self$data_norm <- preprocess_function(self$data_raw)
                                  self$data_norm_method <- unname(self$data_norm@preprocessMethod[1])
                                  if (verbose) message(paste0("Data normalized with Method: ", self$data_norm_method))
                                  invisible(self)
                                },


                                #' @description
                                #' Extract beta values from MethylSet object
                                #' @param verbose Print helpful messages (default: TRUE)
                                get_betas = function(verbose = TRUE) {
                                  self$data_beta <- minfi::getBeta(self$data_norm)
                                  if (verbose) message("Extracted beta values")
                                  invisible(self)
                                },


                                #' @description
                                #' Perform missing data imputation.
                                #' @param imputation_function Function used to perform imputation.
                                #' Has to be able to use matrix of beta values for a single sample
                                #' as input. If NULL, performs random data imputation (beta values
                                #' are to fill in gaps are sampled from available data, Default: NULL)
                                #' @param verbose Print helpful messages (Default: TRUE)
                                impute_data = function(imputation_function = NULL, verbose = TRUE) {
                                  # imputation returns (1) matrix and (2) proportion of NAs
                                  if (is.null(imputation_function)) {
                                    imputation_function <- impute_random
                                  }
                                  imp <- imputation_function(self$data_beta)
                                  # update beta values in place
                                  self$data_beta <- imp$imputed
                                  self$data_na_n <- imp$n
                                  self$data_na_probes <- imp$probes
                                  if (verbose) message(paste0("Imputed data for n = ", imp$n, " probes"))
                                  invisible(self)
                                },


                                #' @description
                                #' Classify tumor sample
                                #' @param verbose Print helpful messages (default: TRUE)
                                #' @param rf_model RandomForest predictor object
                                run_classification = function(rf_model, verbose = TRUE) {
                                  # copy classifier into object
                                  self$class_algorithm <- rf_model
                                  # extract variables
                                  vars <- get_rf_variables(self$class_algorithm)
                                  # select beta values
                                  input_data <- self$data_beta[vars, ,drop = FALSE]

                                  # determine class of sample
                                  self$class_type <- predict(object = self$class_algorithm, newdata = t(input_data), type = "response")
                                  # convert to character vector of length 1
                                  self$class_type <- as.character(unname(self$class_type))

                                  # determine class scores, store as tibble
                                  self$class_votes <- predict(object = self$class_algorithm,
                                                              newdata = t(input_data),
                                                              type = "vote")
                                  # convert to tibble
                                  attr(self$class_votes, "class") <- NULL
                                  self$class_votes <-
                                    self$class_votes %>%
                                    as.matrix %>%
                                    as_tibble
                                  if (verbose) message("Classification completed")
                                  invisible(self)
                                },

                                #' @description
                                #' Classify tumor sample
                                #' @param verbose Print helpful messages (default: TRUE)
                                #' @param calibration_model Model for calibrating random forest scores
                                calibrate_scores = function(calibration_model, verbose = TRUE) {

                                  # store calibration model in object
                                  self$class_calibration_model <- calibration_model

                                  # get calibrated class
                                  class <- predict(object = calibration_model,
                                                   newx = as.matrix(self$class_votes),
                                                   type = "class")
                                  self$class_type_calibrated <- as.vector(unname(class))

                                  # get calibrated scores
                                  scores <- predict(object = calibration_model,
                                                    newx = as.matrix(self$class_votes),
                                                    s = "lambda.1se",
                                                    type = "response")
                                  #re-format to tibble and store
                                  scores <- scores[, , 1] %>% t %>% as_tibble()

                                  self$class_votes_calibrated <- scores
                                  if (verbose) message("Score calibration completed")
                                  invisible(self)
                                },

                                #' @description
                                #' Prepare copy-number plot
                                #' @param verbose Print helpful messages (default: TRUE)
                                prepare_cnv = function(verbose = TRUE) {

                                  # pick prepared annotation and normal controls for platform
                                  anno <- switch(self$array_platform,
                                                 IlluminaHumanMethylationEPIC = get("ConumeeAnnoEpic"),
                                                 IlluminaHumanMethylation450k = get("ConumeeAnno450k"))
                                  ctrls <- switch(self$array_platform,
                                                  IlluminaHumanMethylationEPIC = get("NormalControlsEpic"),
                                                  IlluminaHumanMethylation450k = get("NormalControls450k"))

                                  # prepare query and reference samples
                                  sample <- conumee::CNV.load(self$data_norm)
                                  ctrls <- conumee::CNV.load(ctrls)

                                  # extract probe information for anno, query and reference data
                                  probes_anno <- names(anno@probes)  # ordered by location
                                  probes_query <- rownames(sample@intensity)
                                  probes_ref <- rownames(ctrls@intensity)

                                  # if no. of probes doesn't match, throw warning and filter
                                  # this is cause by slightly different numbers of probes
                                  # in different releases of the EPIC array
                                  if (!all(probes_anno %in% probes_query)) {
                                    warning("Different EPIC platforms, filtering probes for CNV calling")
                                    probes_common <- Reduce(f = intersect, x = list(probes_anno, probes_query, probes_ref))
                                    anno@probes <- anno@probes[probes_common, ]
                                  }

                                  # fit CNV object with updated annotation
                                  cnv_fit <- conumee::CNV.fit(query = sample, ref = ctrls, anno = anno)
                                  cnv_binned <- conumee::CNV.bin(cnv_fit)
                                  self$cnv <- conumee::CNV.segment(cnv_binned)
                                  if (verbose) message("Successfully computed CNV profile")
                                  invisible(self)
                                },


                                #' @description
                                #' Perform tumor purity estimation
                                #' @param verbose Print helpful messages (default: TRUE)
                                estimate_purity = function(verbose = TRUE) {
                                  betas <- self$data_beta

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

                                  # save data as tibble
                                  self$purity = tibble(method = c("ABSOLUTE", "ESTIMATE"),
                                                       purity = c(purity_absolute, purity_estimate))

                                  if (verbose) message("Tumor purity estimation completed")
                                  invisible(self)
                                },


                                #' @description
                                #' Run full sample workflow
                                #' @param verbose Print helpful messages (default: TRUE)
                                #' @param rf_object RandomForest predictor object. Passed to
                                #' run_classification()
                                run_full_workflow = function(rf_model, calibration_model, verbose = TRUE) {
                                  self$load_data(verbose = verbose)
                                  self$normalize_data(verbose = verbose)
                                  self$get_betas(verbose = verbose)
                                  self$impute_data(verbose = verbose)
                                  self$run_classification(rf_model = rf_model, verbose = verbose)
                                  self$calibrate_scores(calibration_model = calibration_model, verbose = verbose)
                                  self$estimate_purity(verbose = verbose)
                                  self$prepare_cnv(verbose = verbose)
                                })
)
