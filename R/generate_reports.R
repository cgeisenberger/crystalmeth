#' Render diagnostic report for ClassificationCase object
#'
#' \strong{Note}: Will report basenames, not filenames for IDAT files
#'
#' Use this function to render a diagnostic report as PDF after running the full
#' workflow for a \emph{ClassificationCase} object. Internally, render_report generates
#' a new environment and and passes the parameters to rmarkdown::render(). Output reports can be
#' rendered as HTML or PDF files. Please note: if out_file extension does not match out_type,
#' out_type takes precedence and will change the extension.
#'
#' @param case Object of type ClassificationCase.
#' @param template Template (.Rmd file) to generate report.
#' @param out_dir Output directory of report.
#' @param out_file Name of output file, objects basename if unspecified (Default: NULL).
#' @param out_type Output file type (html or pdf, Default: pdf)
#' @return Full path of report file.
#' @export

render_report <- function(case, template, out_dir, out_file = NULL, out_type = "pdf"){

  # store case object new environment (necessary to pass data to render())
  report_env <- new.env()
  assign(x = "case", value = case$clone(), envir = report_env)

  # choose file suffix based on output file type
  if (out_type == "pdf") {
    format <- "pdf_document"
  } else if (out_type == "html") {
    format <- "html_document"
  } else {
    stop("Invalid output file format, has to be 'pdf' or 'html'")
  }

  # use basename as output file name if unspecified, otherwise extract file extension
  if (is.null(out_file)) {
    out_file <- paste0(case$basename, ".", out_type)
  } else {
    # check if extensions of output filename and output format match
    # if not, raise warning and change extension to match output format
    file_suffix <- get_filename_extension(out_file)
    if (file_suffix != out_type) {
      warning("File extension of 'out_file' and 'out_type' do not match, 'out_type' takes precedence")
      out_file <- str_replace(string = out_file, pattern = file_suffix, replacement = out_type)
    }
  }

  # render report
  rmarkdown::render(input = template,
                    output_format = format,
                    output_dir = out_dir,
                    output_file = out_file,
                    envir = report_env)
}



#' Extract file name extension
#'
#' Extracts file name extension ("." followed by alphanumerical characters at the end of a string)
#'
#' @param filename Single filename of class character.
#' @return File name extension.

get_filename_extension <- function(filename){
  pos <- regexpr("\\.([[:alnum:]]+)$", filename)
  ext <- ifelse(pos > -1L, substring(filename, pos + 1L), "")
  return(ext)
}


