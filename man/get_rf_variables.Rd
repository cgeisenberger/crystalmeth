% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/process_data.R
\name{get_rf_variables}
\alias{get_rf_variables}
\title{Extract variable names from randomForest classifier.}
\usage{
get_rf_variables(rf)
}
\arguments{
\item{rf}{Object of class randomForest}
}
\value{
Vector of variable names.
}
\description{
This function will return the names of the variables used to train a random forest classifier.
Internally, it extracts a matrix of variable importance scores and returns its rownames.
}
\keyword{internal}
