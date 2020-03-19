## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup, message = FALSE---------------------------------------------------
library(crystalmeth)
library(tidyverse)

## ----detect_files-------------------------------------------------------------
input_dir <- "../temp/input_data/"
files <- scan_directory(dir = input_dir)

# get_cases() will extract the basenames with matching _Red.idat and _Grn.idat files
basenames <- files %>% get_cases()
basenames

## ----create_objects, message = FALSE------------------------------------------
# Let's create a new Classification case object for one of the cases
case <- ClassificationCase$new(basename = basenames[1], path = input_dir)

# messages are suppressed in this code chunk

## ----run_workflow, message = FALSE, warning = FALSE---------------------------
load("../temp/NetID_v1.RData") # load net_id_v1 (randomForest classifier)

# this command will run the full workflow
case$run_workflow(rf_object = net_id_v1)

# messages are suppressed in this code chunk

## ----report, message = FALSE, warning = FALSE---------------------------------
output_directory = "../temp/reports/" 
template_path = "../temp/netid_report.Rmd"

# note that render_report() returns the location(s) of the output files
out_files <- render_report(case, template = template_path, out_dir = output_directory)

