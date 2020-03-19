#' Scan a directory for IDAT files.
#'
#' \code{scan_directory} scans a directory, detects IDAT and non-IDAT files and
#' reports basenames for complete cases .
#'
#' This function scans a directory. Its main purpose is to identify cases
#' with paired (_Grn.idat and _Red.idat) IDAT files. It will also report
#' any invalid files (types other than .idat) or cases where one of the
#' input files is missing.
#'
#' \strong{Note}: Will report basenames, not filenames for IDAT files
#'
#' Use accessor functions \code{\link{get_all}}, \code{\link{get_invalid}},
#' \code{\link{get_cases}}, \code{\link{get_green_only}} and
#' \code{\link{get_red_only}} to extract data.
#'
#' This implementation might currently be overkill, but was created with
#' forward compatibility in mind (might be replaced by a specialized class in
#' future versions).
#'
#' @param dir Directory to scan.
#' @return Returns a list with the following slots:
#'  \item{all}{List of all files in dir}
#'  \item{invalid}{List of non-IDAT files}
#'  \item{green_only}{Basenames of cases with missing RED channel data}
#'  \item{red_only}{Basenames of cases with missing GREEN channel data}
#'  \item{cases}{Basenames of cases with correctly paired IDAT files}
#' @export

scan_directory <- function(dir){

  files_all <- list.files(path = dir)
  files_idat <- list.files(path = dir, pattern = "_(Red|Grn).idat$")

  # identify non-IDAT files
  files_non_idat <- setdiff(files_all, files_idat)

  # detect red and green files
  files_red <- list.files(path = dir, pattern = "_Red.idat$")
  files_grn <- list.files(path = dir, pattern = "_Grn.idat$")

  # extract basenames
  bn_grn <- get_basename(files_grn)
  bn_red <- get_basename(files_red)

  # check if some samples have only red/green available
  grn_only <- setdiff(bn_grn, bn_red)
  red_only <- setdiff(bn_red, bn_grn)

  # get samples with matching red and green IDAT files
  bn <- intersect(bn_red, bn_grn)

  # save all information as list object
  res <- list(all = files_all,
              invalid = files_non_idat,
              green_only = grn_only,
              red_only = red_only,
              cases = bn)
  return(res)
}


#' Accessor functions for scan_directory() output.
#'
#' After scanning a directory with \code{\link{scan_directory()}}, the accessor
#' functions listed here can be used to extract useful information.
#'
#' \describe{
#'   \item{get_all}{Lists all files}
#'   \item{get_invalid}{Lists all non-idat files}
#'   \item{get_green_only}{Lists \emph{basenames} with missing RED channel data}
#'   \item{get_red_only}{Lists \emph{basenames} with missing GREEN channel data}
#'   \item{get_cases}{Lists \emph{basenames} of complete cases}
#' }
#'
#' @param obj Output of \code{scan_directory}
#' @return Vector with file names or basenames (see above)
#' @export

get_all <- function(obj){
  return(obj[["all"]])
}


#' @rdname get_all
#' @export

get_invalid <- function(obj){
  return(obj[["invalid"]])
}


#' @rdname get_all
#' @export
get_green_only <- function(obj){
  return(obj[["green_only"]])
}


#' @rdname get_all
#' @export
get_red_only <- function(obj){
  return(obj[["red_only"]])
}


#' @rdname get_all
#' @export
get_cases <- function(obj){
  return(obj[["cases"]])
}
