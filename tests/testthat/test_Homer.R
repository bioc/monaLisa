context("Homer")

test_that("findHomer() works properly", {
    # store existing value
    orig <- Sys.getenv("MONALISA_HOMER", unset = NA)
    if (!is.na(orig))
        Sys.unsetenv("MONALISA_HOMER")

    # test non-existing
    res <- findHomer("I-do-not-exist")
    expect_true(is.na(res))

    Sys.setenv(MONALISA_HOMER = "/I/also/dont/exist")
    res <- findHomer(dirs = ".")
    expect_true(is.na(res))
    Sys.unsetenv("MONALISA_HOMER")

    # test existing
    res <- findHomer("results.binned_motif_enrichment_LMRs.rds", dirs = system.file("extdata", package = "monaLisa"))
    expect_true(file.exists(res))

    Sys.setenv(MONALISA_HOMER = system.file("extdata", package = "monaLisa"))
    res <- findHomer("results.binned_motif_enrichment_LMRs.rds")
    expect_true(file.exists(res))
    Sys.unsetenv("MONALISA_HOMER")

    # restore original value
    if (!is.na(orig))
        Sys.setenv(MONALISA_HOMER = orig)
})

test_that("dumpJaspar() works properly", {
    tmp1 <- tempfile()

    expect_error(dumpJaspar(filename = system.file("extdata",
                                                   "results.binned_motif_enrichment_LMRs.rds",
                                                   package = "monaLisa"),
                            pkg = "JASPAR2020"))
    expect_error(dumpJaspar(filename = tmp1,
                            pkg = "JASPAR2020",
                            opts = list(matrixtype = "PWM")))
    expect_error(dumpJaspar(filename = tmp1,
                            pkg = "JASPAR2020",
                            relScoreCutoff = "error"))
    expect_true(dumpJaspar(filename = tmp1,
                           pkg = "JASPAR2020",
                           opts = list(ID = c("MA0006.1", "MA0007.3", "MA0828.1")),
                           verbose = TRUE))
    unlink(tmp1)
    expect_true(dumpJaspar(filename = tmp1,
                           pkg = "JASPAR2024",
                           opts = list(ID = c("MA0006.1", "MA0007.3", "MA0828.1")),
                           verbose = TRUE))
    unlink(tmp1)
    expect_error(dumpJaspar(filename = tmp1,
                            pkg = "BSgenome",
                            opts = list(ID = c("MA0006.1", "MA0007.3", "MA0828.1")),
                            verbose = TRUE))
})

test_that("homerToPFMatrixList() works properly", {
    tmp1 <- tempfile()
    library(JASPAR2020)
    optsL <- list(ID = c("MA0006.1", "MA0007.3", "MA0019.1", "MA0025.1", "MA0029.1", "MA0030.1"))
    pfms <- TFBSTools::getMatrixSet(JASPAR2020, opts = optsL)
    expect_true(dumpJaspar(filename = tmp1, pkg = "JASPAR2020", opts = optsL))

    expect_error(homerToPFMatrixList("does_not_exist"))
    expect_error(homerToPFMatrixList(tmp1, "error"))

    res <- homerToPFMatrixList(tmp1, 1000L)
    expect_is(res, "PFMatrixList")
    expect_length(res, length(pfms))
    expect_true(all(abs(colSums(do.call(cbind, TFBSTools::Matrix(res))) - 1000) <= 2)) # 2/1000 rounding error
    expect_true(all(sapply(TFBSTools::Matrix(res), nrow) == 4L))
    expect_identical(sapply(TFBSTools::Matrix(res), ncol), c(6L, 17L, 12L, 11L, 14L, 14L))
    expect_identical(TFBSTools::name(res), paste0(TFBSTools::ID(pfms), ":::", TFBSTools::name(pfms)))

    unlink(tmp1)
})

test_that("prepareHomer() works properly", {
    gr <- GenomicRanges::GRanges(rep(c("chr1","chr2","chr3"), each = 10),
                                 IRanges::IRanges(start = rep(10 * 1:10, 3), width = 5L))
    b <- 1:30 %% 3 + 1
    bF <- factor(b)
    tmp1 <- tempfile()
    dir.create(tmp1)
    tmp2 <- tempfile()
    fname <- system.file("extdata", "results.binned_motif_enrichment_LMRs.rds", package = "monaLisa")

    expect_error(prepareHomer(gr = gr, b = b, genomedir = "genomedir", outdir = tmp1,
                              motifFile = fname, homerfile = fname, regionsize = "given", Ncpu = 2))
    expect_error(prepareHomer(gr = gr, b = b, genomedir = tmp1, outdir = tmp1,
                              motifFile = fname, homerfile = fname, regionsize = "given", Ncpu = 2))
    expect_error(prepareHomer(gr = as(gr, "data.frame"), b = bF[1:10], genomedir = "genomedir", outdir = tmp2,
                              motifFile = fname, homerfile = fname, regionsize = "given", Ncpu = 2))
    expect_error(prepareHomer(gr = gr, b = bF, genomedir = "genomedir", outdir = tmp2,
                              motifFile = "error", homerfile = fname, regionsize = "given", Ncpu = 2))

    expect_identical(prepareHomer(gr = gr, b = bF, genomedir = ".", outdir = tmp2,
                                  motifFile = fname, homerfile = fname, regionsize = "given", Ncpu = 2, verbose = TRUE),
                     file.path(tmp2, "run.sh"))

    unlink(c(tmp1, tmp2), recursive = TRUE, force = TRUE)
})

test_that("parseHomerOutput() works properly", {
    outfile <- system.file("extdata", "homer_output.txt.gz", package = "monaLisa")

    expect_error(parseHomerOutput("does-not-exist"))
    expect_error(parseHomerOutput(outfile, pseudocount.log2enr = "error"))
    expect_error(parseHomerOutput(outfile, pseudofreq.pearsonResid = "error"))
    expect_error(parseHomerOutput(outfile, p.adjust.method = "error"))

    res <- parseHomerOutput(structure(c(outfile, outfile), names = c("bin1", "bin2")))
    expect_length(res, 9L)
    expect_identical(names(res), c("negLog10P", "negLog10Padj",
                                   "pearsonResid", "expForegroundWgtWithHits", "log2enr",
                                   "sumForegroundWgtWithHits",
                                   "sumBackgroundWgtWithHits",
                                   "totalWgtForeground",
                                   "totalWgtBackground"))
    expect_identical(colnames(res[[1]]), c("bin1", "bin2"))
    expect_identical(res$p[,1], res$p[,2])
    expect_true(all(sapply(res[1:6], dim) == c(579L, 2L)))
    expect_length(res[[8]], 2L)
    expect_length(res[[9]], 2L)
    expect_equal(sum(res$pearsonResid), 5646.01883770411)
    expect_equal(sum(res$log2enr), 447.056685196643)
    expect_identical(res[[9]], c(bin1 = 43339, bin2 = 43339))
})

test_that("calcBinnedMotifEnrHomer() works properly (synthetic data)", {
    homerbin <- findHomer("findMotifsGenome.pl", dirs = "/Users/runner/work/monaLisa/monaLisa/homer/bin")
    if (is.na(homerbin)) {
        homerbin <- findHomer("findMotifsGenome.pl", dirs = "/work/gbioinfo/Appz/Homer/Homer-4.11/bin")
    }

    if (!is.na(homerbin) && require("JASPAR2020")) {
        # genome
        set.seed(42)
        genomedir <- tempfile()
        chrsstr <-
            unlist(lapply(1:3, function(i) paste(sample(x = c("A","C","G","T"),
                                                        size = 10000,
                                                        replace = TRUE,
                                                        prob = c(.3,.2,.2,.3)),
                                                 collapse = "")))
        names(chrsstr) <- paste0("chr", seq_along(chrsstr))

        # regions
        gr <- GenomicRanges::tileGenome(seqlengths = nchar(chrsstr),
                                        tilewidth = 200, cut.last.tile.in.chrom = TRUE)
        bins <- factor(GenomicRanges::seqnames(gr))

        # motifs
        selids <- c("MA0139.1", "MA1102.1", "MA0740.1", "MA0493.1", "MA0856.1")
        pfm <- TFBSTools::getMatrixSet(JASPAR2020, opts = list(ID = selids))
        cons <- unlist(lapply(Matrix(pfm), function(x) paste(rownames(x)[apply(x, 2, which.max)], collapse = "")))
        #              MA0139.1          MA1102.1          MA0740.1       MA0493.1          MA0856.1
        # "TGGCCACCAGGGGGCGCTA"  "CACCAGGGGGCACC"  "GGCCACGCCCCCTT"  "GGCCACACCCA"  "GGGGTCAAAGGTCA"
        # ... dump to file for Homer
        mfile <- tempfile(fileext = ".motifs")
        expect_true(dumpJaspar(filename = mfile, pkg = "JASPAR2020",
                               opts = list(ID = selids)))
        # ... plant motifs
        for (chr1 in names(chrsstr)) {
            i <- which(as.character(GenomeInfoDb::seqnames(gr)) == chr1)
            j <- sample(x = GenomicRanges::start(gr)[i], size = round(length(i) / 3))
            m <- match(chr1, names(chrsstr))
            for (j1 in j)
                substring(chrsstr[chr1], first = j1, last = j1 + nchar(cons[m]) - 1) <- cons[m]
        }
        chrs <- Biostrings::DNAStringSet(chrsstr)
        expect_true(dir.create(genomedir))
        genomefile <- file.path(genomedir, "genome.fa")
        Biostrings::writeXStringSet(x = chrs, filepath = genomefile, format = "fasta")

        outdir <- tempfile()

        expect_error(calcBinnedMotifEnrHomer(gr = gr, b = bins, motifFile = mfile,
                                             Ncpu = "error"))

        expect_message(res <- calcBinnedMotifEnrHomer(
            gr = as.character(gr), b = as.character(bins),
            motifFile = mfile, genomedir = genomedir,
            outdir = outdir, homerfile = homerbin, regionsize = "given",
            Ncpu = 2L, verbose = TRUE),
            "preparing input files")
        attr(bins, "breaks") <- seq(0.5, 3.5, by = 1)
        expect_message(res1 <- calcBinnedMotifEnrHomer(
            gr = as.character(gr), b = bins,
            motifFile = mfile, genomedir = genomedir,
            outdir = outdir, homerfile = homerbin, regionsize = "given",
            Ncpu = 2L, verbose = TRUE),
                       "HOMER output files already exist, using existing files")
        unlink(dir(path = outdir, pattern = "knownResults.txt", full.names = TRUE, recursive = TRUE, ignore.case = FALSE)[1])
        expect_error(calcBinnedMotifEnrHomer(
            gr = as.character(gr), b = as.character(bins),
            motifFile = mfile, genomedir = genomedir,
            outdir = outdir, homerfile = homerbin, regionsize = "given"),
            "missing 'knownResults.txt' files for some bins")

        expect_is(res, "SummarizedExperiment")
        expect_is(res1, "SummarizedExperiment")
        expect_identical(SummarizedExperiment::colData(res)[, -(2:3)],
                         SummarizedExperiment::colData(res1)[, -(2:3)])
        SummarizedExperiment::colData(res)[, 2:3] <- SummarizedExperiment::colData(res1)[, 2:3]
        expect_identical(S4Vectors::metadata(res)[-c(2,4)],
                         S4Vectors::metadata(res1)[-c(2,4)])
        S4Vectors::metadata(res)[c(2,4)] <- S4Vectors::metadata(res1)[c(2,4)]
        expect_identical(res, res1)
        expect_identical(rownames(res), selids)
        expect_length(SummarizedExperiment::assays(res), 7L)
        expect_identical(SummarizedExperiment::assayNames(res),
                         c("negLog10P", "negLog10Padj", "pearsonResid",
                           "expForegroundWgtWithHits", "log2enr",
                           "sumForegroundWgtWithHits", "sumBackgroundWgtWithHits"))
        expect_identical(dim(res), c(5L, 3L))
        expect_identical(rownames(res), SummarizedExperiment::rowData(res)[, "motif.id"])
        expect_identical(rownames(res), TFBSTools::ID(SummarizedExperiment::rowData(res)[, "motif.pfm"]))
        expect_identical(apply(SummarizedExperiment::assay(res, "negLog10P"), 2, which.max),
                         c(chr1 = 1L, chr2 = 2L, chr3 = 3L))
        expect_equal(sum(SummarizedExperiment::assay(res, "negLog10P")), 65.132971396505)
        expect_equal(sum(SummarizedExperiment::assay(res, "pearsonResid")), -0.23617661811598)

        unlink(c(mfile, outdir, genomedir), recursive = TRUE, force = TRUE)
    }
})
