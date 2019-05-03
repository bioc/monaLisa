context("plotting")

# create data

# ... binning
set.seed(1)
x <- rnorm(1000)
b1 <- bin(x, binmode = "equalN", nElements = 100)
b2 <- bin(x, binmode = "equalN", nElements = 50, minAbsX = 0.6)
resL <- lapply(readRDS(system.file("extdata", "resL.rds", package = "lisa")), "[", 1:10, 1:8)
resB <- factor(rep(1:8, 100)); levels(resB) <- colnames(resL[[1]]); attr(resB, "bin0") <- NA

# ... stability selection
Y <- rnorm(n = 100, mean = 2, sd = 1)
X <- matrix(data = runif(n = 20 * 100, min = 0, max = 3), nrow = length(Y), ncol = 20)
for (i in sample(x = 1:ncol(X), size = 10, replace = FALSE))
    X[ ,i] <- X[ ,i] + Y
ss <- lisa::randomized_stabsel(x = X, y = Y)


test_that("getColsByBin() works properly", {
    c1 <- getColsByBin(as.numeric(b1))
    c2 <- getColsByBin(b2)

    expect_length(c1, 1000L)
    expect_identical(as.vector(c1), as.vector(getColsByBin(c1)))
    expect_equal(sort(unname(table(c2))), sort(unname(table(b2))))
})


test_that("plotBinHist() runs", {
    tf <- tempfile(fileext = ".pdf")
    pdf(file = tf)

    expect_is(plotBinHist(x = x, b = b1), "histogram")

    dev.off()
    unlink(tf)
})


test_that("plotBinDensity() runs", {
    tf <- tempfile(fileext = ".pdf")
    pdf(file = tf)

    expect_is(plotBinDensity(x = x, b = b1), "density")

    dev.off()
    unlink(tf)
})


test_that("plotBinScatter() runs", {
    tf <- tempfile(fileext = ".pdf")
    pdf(file = tf)

    expect_null(plotBinScatter(x = x, y = x, b = b1))
    expect_error(plotBinScatter(x = x, y = x, b = b1, cols = "gray"))
    expect_null(plotBinScatter(x = x, y = x, b = b1, cols = "gray", legend = FALSE))

    dev.off()
    unlink(tf)
})


test_that("plotMotifHeatmaps() runs", {
    tf <- tempfile(fileext = ".pdf")
    pdf(file = tf)

    expect_is(plotMotifHeatmaps(x = resL, b = resB, which.plots = "enr", cluster = FALSE), "list")
    expect_is(plotMotifHeatmaps(x = resL, b = resB, which.plots = "FDR", cluster = TRUE), "list")

    dev.off()
    unlink(tf)
})


test_that("plotStabilityPaths() runs", {
    tf <- tempfile(fileext = ".pdf")
    pdf(file = tf)

    expect_error(plotStabilityPaths("error"))
    expect_true(plotStabilityPaths(ss))

    dev.off()
    unlink(tf)
})


test_that("plotSelectionProb() runs", {
    tf <- tempfile(fileext = ".pdf")

    ss2 <- ss
    ss2$selected <- integer(0)

    pdf(file = tf)

    expect_error(plotSelectionProb("error"))
    expect_error(plotSelectionProb(ss2, onlySelected = TRUE))
    expect_true(plotSelectionProb(ss, onlySelected = FALSE))

    dev.off()
    unlink(tf)
})
