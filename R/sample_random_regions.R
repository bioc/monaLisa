#' @title Sample random regions of fixed length.
#'
#' @description Sample random regions from the mappable parts of the genome with
#'     a given fraction from CpG islands.
#'
#' @param allowedRegions An unstranded GRanges object of the "allowed" of the 
#'     genome, usually the mappable regions. 
#' @param N Number of regions to sample.
#' @param regWidth Region width.
#'
#'
#' @details In order to make the results deterministic, set the random
#'     number seed before calling \code{sampleRandomRegions} using 
#'     \code{set.seed}.
#'
#' @return A GRanges object with randomly sampled mappable regions of width 
#'     \code{regWidth} with \code{fractionCGI} coming from CpG islands.
#'
#' @examples 
#' regs <- GenomicRanges::GRanges(
#'   seqnames = rep(c("chr1", "chr2"), each = 2), 
#'   ranges = IRanges::IRanges(start = 1:4, end = 5:8))
#' set.seed(123)
#' sampleRandomRegions(regs, N = 2, regWidth = 3L)
#' 
#' @importFrom GenomeInfoDb seqlengths
#' @importFrom GenomicRanges width end end<- start seqnames GRanges sort
#' @importFrom IRanges IRanges
#'
#' @export
sampleRandomRegions <- function(allowedRegions = NULL, N = 100L,
                                  regWidth = 200L){

    .assertScalar(x = N, type = "numeric")
    .assertScalar(x = regWidth, type = "numeric")
    stopifnot(exprs = {
        is(allowedRegions, "GRanges")
        length(allowedRegions) > 0
        sum(width(allowedRegions) >= regWidth) > 0
        all(strand(allowedRegions) == "*")
    })

    #in case these parameters are not integers, round to integer
    N <- round(N)
    regWidth <- round(regWidth)

    #reduce to ranges that are larger than or equal to width and adjust
    #end position such that the object only contains
    #the start positions that when extended by width are
    #entirely within the mappable parts of the genome
    gr <- allowedRegions[width(allowedRegions) >= regWidth]
    end(gr) <- end(gr) - regWidth + 1

    #first sample regions according to the number of positions
    #then sample position uniformly within each region

    #probability of sampling each region
    widths <- width(gr)
    ps <- widths/sum(widths)

    #sample regions
    indx <- sample(seq_along(gr), size = N, prob = ps, replace = TRUE)

    #for each range, sample 1 position uniformly
    gr.sampled <- gr[indx]
    st.sampled <- start(gr.sampled)
    end.sampled <- end(gr.sampled)
    chr.sampled <- seqnames(gr.sampled)

    pos.sampled <- unlist(lapply(seq_along(gr.sampled), function(i){
        sample(st.sampled[i]:end.sampled[i], 1)
    }))
    gr.sampled <- GRanges(seqnames = chr.sampled,
                          ranges = IRanges(start = pos.sampled, 
                                           width = regWidth),
                          seqlengths = seqlengths(gr))
    sort(gr.sampled)
}
