% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_enrichment.R
\name{.checkDfValidity}
\alias{.checkDfValidity}
\title{Check if seqinfo DataFrame is valid}
\usage{
.checkDfValidity(df)
}
\arguments{
\item{df}{Input object to be checked. It should have an attribute \code{err}
and columns:
\describe{
  \item{\code{seqs}}{: a \code{DNAStringSet} object.}
  \item{\code{isForeground}}{ that indicates if a sequence is in the
                              foreground group.}
  \item{\code{GCfrac}}{: the fraction of G+C bases per sequence.}
  \item{\code{GCbin}}{: the GC bin for each sequence.}
  \item{\code{GCwgt}}{: the sequence weight to adjust for GC
    differences between foreground and background sequences.}
  \item{\code{seqWgt}}{: the sequence weight to adjust for k-mer
    differences between foreground and background sequences.}
}}
}
\value{
\code{TRUE} (invisibly) if \code{df} is valid, otherwise it
  raises an exception using \code{stop()}
}
\description{
Check if the DataFrame with sequence information is valid,
  i.e. is of the correct object type (DataFrame) and has all expected
  columns and attributes.
}
\keyword{internal}
