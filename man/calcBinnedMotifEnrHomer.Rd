% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/motif_enrichment_HOMER.R
\name{calcBinnedMotifEnrHomer}
\alias{calcBinnedMotifEnrHomer}
\title{Prepare and run HOMER motif enrichment analysis.}
\usage{
calcBinnedMotifEnrHomer(
  gr,
  b,
  genomedir,
  outdir,
  motifFile,
  homerfile = findHomer(),
  regionsize = "given",
  pseudocount.log2enr = 8,
  p.adjust.method = "BH",
  Ncpu = 2L,
  verbose = FALSE,
  verbose.Homer = FALSE
)
}
\arguments{
\item{gr}{A \code{GRanges} object (or an object that can be coerced to one)
with the genomic regions to analyze.}

\item{b}{A vector of the same length as \code{gr} that groups its elements
into bins (typically a factor, such as the one returned by
\code{\link{bin}}).}

\item{genomedir}{Directory containing sequence files in Fasta format
(one per chromosome).}

\item{outdir}{A path specifying the folder into which the output files will
be written.}

\item{motifFile}{A file with HOMER formatted PWMs to be used in the
enrichment analysis.}

\item{homerfile}{Path and file name of the \code{findMotifsGenome.pl}
HOMER script.}

\item{regionsize}{The peak size to use in HOMER (\code{"given"} keeps the
coordinate region, an integer value will keep only that many bases in
the region center).}

\item{pseudocount.log2enr}{A numerical scalar with the pseudocount to add to
foreground and background counts when calculating log2 motif enrichments}

\item{p.adjust.method}{A character scalar selecting the p value adjustment
method (used in \code{\link[stats]{p.adjust}}).}

\item{Ncpu}{Number of parallel threads that HOMER can use.}

\item{verbose}{A logical scalar. If \code{TRUE}, print progress messages.}

\item{verbose.Homer}{A logical scalar. If \code{TRUE}, print the console
output when running Homer.}
}
\value{
A \code{SummarizedExperiment} object with motifs in rows and bins
  in columns, containing seven assays: \describe{
  \item{negLog10P}{: -log10 P values}
  \item{negLog10Padj}{: -log10 adjusted P values}
  \item{pearsonResid}{: motif enrichments as Pearson residuals}
  \item{expForegroundWgtWithHits}{: expected number of foreground
    sequences with motif hits}
  \item{log2enr}{: motif enrichments as log2 ratios}
  \item{sumForegroundWgtWithHits}{: Sum of foreground sequence weights
    in a bin that have motif hits}
  \item{sumBackgroundWgtWithHits}{: Sum of background sequence weights
    in a bin that have motif hits}
}
The \code{rowData} of the object contains annotations (name, PFMs, PWMs
and GC fraction) for the motifs, while the \code{colData} slot contains
summary information about the bins.
}
\description{
Run complete HOMER motif enrichment analysis, consisting of
    calls to \code{\link{prepareHomer}}, \code{\link[base]{system2}} and
    \code{\link{parseHomerOutput}}. This function requires \code{HOMER}
    to be installed (see \url{http://homer.ucsd.edu/homer/index.html})
    and the path to the tool to be provided (\code{homerfile} argument).
}
\examples{
if (!is.na(findHomer())){

  # genome
  genome <-  system.file("extdata", "exampleGenome.fa", package = "monaLisa")

  # create motif file for Homer
  motiffile <- tempfile()
  motifIDs <- c("MA0139.1", "MA1102.1", "MA0740.1")
  dumpJaspar(filename = motiffile, pkg = "JASPAR2020",
             opts = list(ID = motifIDs))

  # GRanges of regions used in binned motif enrichment analysis
  gr <- GenomicRanges::tileGenome(
      seqlengths = c(chr1 = 10000L, chr2 = 10000L, chr3 = 10000L),
      tilewidth = 200, cut.last.tile.in.chrom = TRUE)

  # create bins (motif enrichment analysis will be per bin)
  bins <- factor(GenomicRanges::seqnames(gr))
  table(bins)

  # run calcBinnedMotifEnrHomer
  outdir <- tempfile()
  se <- calcBinnedMotifEnrHomer(gr = gr, b = bins, genomedir = genome,
      outdir = outdir, motifFile = motiffile)
  list.files(outdir)

  }

}
\seealso{
The functions that are wrapped: \code{\link{prepareHomer}},
    \code{\link[base]{system2}} and \code{\link{parseHomerOutput}},
    \code{\link{bin}} for binning of regions
}
