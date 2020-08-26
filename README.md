# Introduction

### Installation 

To install `crystalmeth` from within R, copy and run the following code:

```{r}
install.packages("devtools")
devtools::install_github("cgeisenberger/crystalmeth")
```


### Motivation 

DNA methylation is increasingly being used as a diagnostic tool. This is 
facilitated by array-based platforms such as Illuminas *450k* array
and its successor, the *EPIC* platform. The research community has produced
a number of classifiers which are able to determine tissue of origin and / or 
tumor subclass solely based on DNA methylation data as input.  

[Capper et al.](https://www.nature.com/articles/nature26000)) provide compelling
evidence that array-based DNA methylation profiling of tumors can augment
(or arguably even replace) microscopy-based histopathology.
This has led to the recommendation by the WHO to perform methylation-based
profiling for a number of well-characterized brain tumor entities.

It seems highly likely that this approach which has been spearheaded by the
neuropathological community will soon be used in other tumor entities.
This has prompted us to develop a software package which allows users to
perform tasks related to methylation-based classification
in a coherent framework that is scalable and can be deployed as a web application. 


### Primer on DNA Methylation Data

Crystalmeth is designed to work with array-based methylation data. Obtainng raw data by measuring fluorescence on the physical slides in Illumina scanners produces **two output files**. These start with the same sample ID (referred to as **basename** hereafter) and end with either `_Red.idat` or `_Grn.idat`.

In addition to the biological signal, multiple technical sources can add noise to the measurements. After loading the raw data, **normalization** can mitigate some of these effects. After normalizing, data can be extracted. While methylation is a binary state on the single-CpG level, methylation arrays measure the average across all different cell populations present in the (bulk) input material. This average is referred to as **beta value** and ranges between 0 and 1, representing unmethylated and fully methylated loci, respectively. 

Since the details around the analysis of array-based DNA methylation data is beyond the scope of this vignette, we would like to point readers towards the [minfi R package](https://bioconductor.org/packages/release/bioc/html/minfi.html) developed by [Kasper Daniel Hansen](http://www.hansenlab.org). It provides more information about the fundamentals of DNA methylation data analysis and is also used as the backbone for sample preprocessing in this software package.



# How to use the package


## Example Data

All data to run the minimal example can be downloaded via this [Dropbox link](https://www.dropbox.com/s/tub92yz8gig7hdk/20200826_test_data_nen_id.zip?dl=0).


## Example Workflow

```{r}
# load necessary libraries
library(tidyverse)
library(crystalmeth)

# load data (see section 'Example Data' above)
rf_model <- readRDS(file = "./testing/test-data/rf_model.RDS")
ridge_model <- readRDS(file = "./testing/test-data/calibration_model.RDS")

# detect input data (IDAT files)
input_dir <- "./testing/test-data/"
idats <- scan_directory(dir = input_dir)
example <- idats %>% get_cases()

# process case
case <- ClassificationCase$new(basename = example,
                               path = input_dir,
                               verbose = TRUE)
case$run_full_workflow(rf_model = rf_model,
                       calibration_model = ridge_model)

# render report
render_report(case = case,
              input = "./testing/test-data/nen_id_template_html.Rmd",
              output_file = paste0(case$array_basename, ".html"),
              output_dir = "./testing/test-data/")
```

The report created for this sample can be viewed [here]("./readme/GSM2309170_200134080018_R03C01.html")


## More information

For a more thorough walkthrough, consult the [package vignette](./included/vignette.pdf).

