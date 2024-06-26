% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/motif_enrichment_HOMER.R
\name{findHomer}
\alias{findHomer}
\title{Find HOMER script file.}
\usage{
findHomer(homerfile = "findMotifsGenome.pl", dirs = NULL)
}
\arguments{
\item{homerfile}{Name of the script file to search.}

\item{dirs}{Directory names to look for \code{homerfile}. If
\code{dirs=NULL}, all directories listed in the \code{PATH} environment
variable will be searched.}
}
\value{
Absolute path to \code{homerfile}, or \code{NA} if none or several
  were found.
}
\description{
Find absolute path to HOMER script file.
}
\details{
In addition to \code{dirs}, \code{findHomer} will also look in the
    directory provided in the environment variable \code{MONALISA_HOMER}.
}
\examples{
homer_path <- findHomer()

}
