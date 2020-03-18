#' Render diagnostic report for ClassificationCase object
#'
#' \strong{Note}: Will report basenames, not filenames for IDAT files
#'
#' Use this function to render a diagnostic report as PDF after running the full
#' workflow for a \emph{ClassificationCase} object. Internally, render_report generates
#' a new environment and and passes the parameters to rmarkdown::render().
#'
#' @param case Object of type ClassificationCase.
#' @param template Template (.Rmd file) to generate report.
#' @param out_dir Output directory of report.
#' @param out_file Name of output file, objects basename if unspecified (Default: NULL).
#' @return Full path of report file.


render_report <- function(case, template, out_dir, out_file = NULL){

  # store case object new environment (necessary to pass data to render())
  report_env <- new.env()
  assign(x = "case", value = case$clone(), envir = report_env)

  # use basename if file name is not specified
  if (is.null(out_file)) {
    out_file <- paste0(case$basename, ".pdf")
  }

  # render report
  rmarkdown::render(input = template,
                    output_dir = out_dir,
                    output_file = out_file,
                    envir = report_env)
}
