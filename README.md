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

In addition to the biological signal, multiple technical sources can add noise to the measurements. After loading the data, **preprocessing** can mitigate some of these effects. After this step, data can be extracted. The most common representation for DNA methylation data are so-called **beta values** which take values between 0 and 1 and correspond to absent (0) or full (100%) methylation at a specific locus. These data are used as input for classification. 

Since the details around the analysis of array-based DNA methylation data is beyond the scope of this vignette, we would like to point readers towards the [minfi R package](https://bioconductor.org/packages/release/bioc/html/minfi.html) developed by [Kasper Daniel Hansen](http://www.hansenlab.org). It provides more information about the fundamentals of DNA methylation data analysis and is also used as the backbone for sample preprocessing in this software package.



# How to use the package


## Minimal Examples

```{r}
library(tidyverse)

# running the workflow requires a randomForest object
# and a .rmd template to generate the report
# both are not included with the package
load("./temp/NetID_v1.RData")

# scan directory for IDAT files
input_dir <- "./temp/problem_files/"
files <- scan_directory(dir = input_dir)
basenames <- files %>% get_cases()
example <- basenames[1]

# process one example case
case <- ClassificationCase$new(basename = example, path = input_dir)
case$run_workflow(rf_object = net_id_v1, verbose = TRUE)

# generate diagnostic report
test_out <- render_report(case,
                          template = "./temp/netid_report.Rmd",
                          out_dir = "./temp/reports/",
                          out_type = "pdf")
```

## Tutorial

For a more thorough walkthrough, consult the [package vignette](./included/vignette.pdf).

