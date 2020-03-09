#' Extract basename from IDAT filename.
#'
#' Given the name of an IDAT file (such as \emph{200134080018_R03C01_Grn.idat})
#' \code{get_basename()} will strip the suffix and return the corresponding basename
#' (\emph{200134080018_R03C01}).
#'
#' @param file Vector of file name(s)
#' @return Vector with basenames
#' @keywords internal

get_basename <- function(file){
  if( length(file) > 1) {
    # if multiple files, use sapply + recursion
    basename <- sapply(file, FUN = get_basename, simplify = TRUE)
  } else {
    if (base::grepl(pattern = "_Grn.idat$", x = file)) {
      basename <- stringr::str_remove(file, pattern = "_Grn.idat$")
    } else if (base::grepl(pattern = "_Red.idat$", x = file)) {
      basename <- stringr::str_remove(file, pattern = "_Red.idat$")
    } else {
      error("Unknown file type, must contain suffix _Grn.idat or _Red.idat")
    }
  }
  return(unname(basename))
}


#' Guess type of DNA methylation array.
#'
#' Will report the platform of a DNA methylation array given the number
#' of probes measured. Adapted from an internal function in \code{minfi} package.
#' Returns \emph{unknown} if array platform cannot be determined.
#'
#' @param n_probes Number of probes detected
#' @return Array type, one of:
#' \itemize{
#'   \item IlluminaHumanMethylationEPIC
#'   \item IlluminaHumanMethylation450k
#'   \item IlluminaHumanMethylation27k
#'   \item HorvathMammalMethylChip40
#'   \item unknown
#' }
#' @keywords internal

guess_array_type <- function(n_probes) {
  if (n_probes >= 622000 && n_probes <= 623000) {
    array = "IlluminaHumanMethylation450k"
  } else if (n_probes >= 1050000 && n_probes <= 1053000) {
    # NOTE: "Current EPIC scan type"
    array = "IlluminaHumanMethylationEPIC"
  } else if (n_probes >= 1032000 && n_probes <= 1033000) {
    # NOTE: "Old EPIC scan type"
  } else if (n_probes >= 54000 && n_probes <= 56000) {
    array = "IlluminaHumanMethylation27k"
  } else if (n_probes >= 41000 & n_probes <= 41100) {
    array = "HorvathMammalMethylChip40"
  } else {
    array = "Unknown"
  }
  return(array)
}


#' Extract variable names from randomForest classifier.
#'
#' This function will return the names of the variables used to train a random forest classifier.
#' Internally, it extracts a matrix of variable importance scores and returns its rownames.
#'
#' @param rf Object of class randomForest
#' @return Vector of variable names.
#' @keywords internal

get_rf_variables <- function(rf){
  vars <- randomForest::importance(rf)
  vars <- rownames(vars)
  return(vars)
}


#' Impute missing values.
#'
#' This function imputes missing data with data points samples randomly from the non-missing entries.
#' Returns the input data unchanged if all data are missing.
#'
#' @param mat Matrix (with or without missing data)
#' @return List with two slots:
#'  \item{imputed}{Updated version of input matrix with NAs replaced}
#'  \item{n}{Number of data points which were replaced}


impute_random <- function(mat){
  stopifnot(is.matrix(mat))

  if (all(is.na(mat))) {
    warning("No non-NA data points, returning object unchanged")
    na_num <- nrow(mat)
    return(list(imputed = mat, n = na_num))
  } else {
    na_pos <- is.na(mat)
    na_num <- sum(na_pos)
    mat[na_pos] <- sample(x = mat[!na_pos], size = na_num, replace = TRUE)
    return(list(imputed = mat, n = na_num))
  }
}

