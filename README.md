# Introduction

### Installation 

To install `crystalmeth` from within R, copy and run the following code:

```{r}
install.packages("devtools")
devtools::install_github("cgeisenberger/crystalmeth")
```



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
