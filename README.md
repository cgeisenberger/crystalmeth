# Introduction

### Installation 

To install `crystalmeth` from within R, copy and run the following code:

```{r}
install.packages("devtools")
devtools::install_github("cgeisenberger/crystalmeth")
```


### Motivation 

The recent explosion in development of high-throughput techniques in biology has created
many opportunities to apply these techniques in a clinical setting. Among these, DNA methylation
profiling has shown great promise, especially in the field of molecular pathology. This is primarily
facilitated by the availability of array-based platforms, which have technical characteristics 
and a low pricepoint which make them especially suited for this purpose. There are now multiple 
publications (such as [Capper et al., 2018](https://www.nature.com/articles/nature26000)), which 
provide compelling evidence that array-based DNA methylation profiling of tumors can augment
(or arguably even replace) microscopy-based histopathology. This has led to the recommendation
by the WHO to perform methylation-based profiling for a number of well-characterized brain tumor 
entities. It seems highly likely that this approach which has been spearheaded by the neuropathological
community will soon be used in many other tumor entities aswell. This has prompted us to develop 
a software package which allows users to perform tasks related to methylation-based classification
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



# Technical information

### List of error codes


| Code          | Error                                   | Possible reason                      |
|:-------------:|:---------------------------------------:|:------------------------------------:|
| 100           | Input file error                        |                                      |
| 101           | Invalid basename                        | Trying to pass multiple basenames?   |
| 102           | Input directory does not exist          |                                      |
| 103           | Green IDAT file missing                 |                                      |
| 104           | Red IDAT file missing                   |                                      |
| 105           | Unable to read _Grn.idat                | File corrupt? Test with `minfi`      |
| 106           | Unable to read _Red.idat                | File corrupt? Test with `minfi`      |
| 107           | Different no. of probes in input files  | Non-matching files? Contact author   |
| 108           | Array type not supported                | Workflow only supports 450K and EPIC |
