#' Render diagnostic report for ClassificationCase object
#'
#' Wrapper around rmarkdown::render(). Clones the ClassificationCase object into
#' a new environment which is passed to rmarkdown::render().
#'
#' @param case Object of type ClassificationCase.
#' @param input Report template (.Rmd file) (passed to rmarkdown::render).
#' @param output_format Output directory (passed to rmarkdown::render).
#' @param output_file Name of output file (passed to rmarkdown::render).
#' @param output_dir Output directory of rendered file (passed to rmarkdown::render).
#' @return Returns path of rendered file.
#' @export

render_report <- function(case, ...){

  # store case object new environment (necessary to pass data to render())
  report_env <- new.env()
  assign(x = "case", value = case$clone(), envir = report_env)

  # render report
  out_file <- rmarkdown::render(envir = report_env, ...)

  # return path of output file
  return(out_file)
}
