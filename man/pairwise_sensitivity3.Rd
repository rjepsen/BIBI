% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/metric_sensitivity.R
\name{pairwise_sensitivity3}
\alias{pairwise_sensitivity3}
\title{Pairwise Sensitivity 3}
\usage{
pairwise_sensitivity3(metrics.df, method)
}
\arguments{
\item{metrics.df}{= data frame of metric values for each station with site
a column of site classes defined by environmental variables.}

\item{method}{= the sensitivity function to be used during the assessment.}
}
\value{
Determines the threshold at which a metric best categorizes
two defined environmental conditions.
}
\description{
Pairwise Sensitivity 3
}
