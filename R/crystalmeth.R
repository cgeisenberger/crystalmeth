#' crystalmeth: A streamlined workflow for DNA methylation-based classification of tumours.
#'
#' The crystalmeth package provides a coherent framework to use DNA methylation data for
#' diagnostic purposes. Essentially, the workflow is split into four step which are outlined
#' in further detail below. For more information and feature requests, refer to the
#' \href{https://github.com/cgeisenberger/crystalmeth}{Github Repository}.
#'
#'
#' The major steps in processing samples are:
#'
#' \enumerate{
#'   \item Detect input (via \code{scan_directory()})
#'   \item Initiate an object of class \code{ClassificationCase} for every pair of IDAT files
#'   \item Process samples
#'   \item Render a diagnostic report for each case
#' }
#'
#' @section Input detection:
#' The first step is to load data for the cases that should be classified.
#' Currently, only raw data (IDAT files) are supported as some features (such as CNV calling)
#' need access to raw intensity measurements of the array. Support for loading other types of
#' data suchs as Beta values, MSet or RgSet objects may be included in future versions.
#'
#' @section Sample processing:
#' After detecting the input files, data has to be loaded into memory. \pkg{Crystalmeth} offers
#' a handy object type called \emph{ClassificationCase} for this purpose. Upon initiation,
#' it performs a thorough check of the input files. Afterwards, a single command \code{case$run_workflow()}
#' will load, preprocess and impute missing data. Furthermore, the sample is classified,
#' tumor purity estimation performed and a copy-number profile is generated.
#'
#' @section Report generation:
#' The package comes with the function \code{render_report()}, a handy wrapper around \code{rmarkdown::render()}.
#' It will create a report based on a markdown template for an object of type \code{ClassificationCase}.
#'
#'
#' @docType package
#' @name crystalmeth

NULL
