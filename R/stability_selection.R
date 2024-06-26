#' @title Randomized Lasso
#'
#' @description This function performs randomized lasso using the \code{glmnet}
#'     package. The function present in the \code{stabs} package that runs the
#'     lasso version was adapted for the randomized lasso here. Randomized
#'     lasso stability selection uses this function repeatedly
#'     to select predictors.
#'
#' @param x the predictor matrix. Passed to \code{x}
#'     of \code{glmnet.lasso} from \code{stabs} package.
#' @param y the response vector. Passed to \code{y}
#'     of \code{glmnet.lasso} from \code{stabs} package.
#' @param q the number of variables that are selected on each subsample.
#'     Passed to \code{q} of \code{glmnet.lasso} from \code{stabs} package.
#' @param weakness weakness parameter used in randomized lasso (see details).
#' @param type parameter passed to \code{type} of \code{glmnet.lasso} from
#'     \code{stabs} package. It is a character vector specifying how much the
#'     PFER should be controlled. If type is "conservative" (default), then the
#'     number of selected variables per subsample is <= q. If type is
#'     "anticonservative" then the number of selected variables per subsample
#'     is >= q.
#' @param ... additional parameters for \code{glmnet}.
#'
#' @return the regression output which consists of a list of length 2. The
#'     list contains the following:
#'     \describe{
#'     \item{selected}{ - a logical vector of length equal to the total number
#'         of predictors. The predictors that were chosen have a value of TRUE.}
#'     \item{path}{ - a logical matrix containing the regularization steps as
#'         columns and the predictors as rows. An entry of TRUE indicates
#'         selection.}
#'     }
#'
#'
#' @details This function is identical to \code{glmnet.lasso} from the
#'     \code{stabs} package. The only addition/modification is the weakness
#'     parameter which has been added when calling the
#'     \code{glmnet} function by setting
#'     penalty.factor = 1/runif(ncol(x), weakness, 1),
#'     where ncol(x) is the number of predictors.
#'
#' @seealso \code{\link[stabs]{glmnet.lasso}} and \code{\link[glmnet]{glmnet}}
#'
#' @importFrom glmnet glmnet predict.glmnet
#' @importFrom stats model.matrix runif
#'
#' @keywords internal
.glmnetRandomizedLasso <- function(x, y, q, weakness=1,
                                   type = c("conservative",
                                            "anticonservative"),
                                   ...) {
  if (is.data.frame(x)) {
    message("Note: ", sQuote("x"),
            " is coerced to a model matrix without intercept")
    x <- stats::model.matrix(~. - 1, x)
  }
  if ("lambda" %in% names(list(...)))
    stop("It is not permitted to specify the penalty parameter ",
         sQuote("lambda"), " for lasso when used with stability selection.")
  type <- match.arg(type)

  # modify the function here to make it a randomized-lasso using the
  # weakness parameter
  if (type == "conservative")
    fit <- glmnet::glmnet(
      x, y, pmax = q,
      penalty.factor = 1/stats::runif(ncol(x), weakness,  1),  ...)
  if (type == "anticonservative")
    fit <- glmnet::glmnet(
      x, y, dfmax = q - 1,
      penalty.factor = 1/stats::runif(ncol(x), weakness,  1), ...)

  selected <- glmnet::predict.glmnet(fit, type = "nonzero")
  selected <- selected[[length(selected)]]
  ret <- logical(ncol(x))
  ret[selected] <- TRUE
  names(ret) <- colnames(x)
  cf <- fit$beta
  sequence <- as.matrix(cf != 0)
  return(list(selected = ret, path = sequence))
}



#' @title Randomized Lasso Stability Selection
#'
#' @description This function runs randomized lasso stability selection as
#'     presented by Meinshausen and Bühlmann (2010) and with the improved
#'     error bounds introduced by Shah and Samworth (2013). The function
#'     uses the \code{\link[stabs]{stabsel}} function from the \code{stabs}
#'     package, but implements the randomized lasso version.
#'
#' @param x the predictor matrix.
#' @param y the response vector.
#' @param weakness value between 0 and 1 (default = 0.8).
#'     It affects how strict the method will be in selecting predictors. The
#'     closer it is to 0, the more stringent the selection. A weakness value
#'     of 1 is identical to performing lasso stability selection (not the
#'     randomized version).
#' @param cutoff value between 0 and 1 (default = 0.8) which is the cutoff
#'     for the selection probability. Any variable with a selection probability
#'     that is higher than the set cutoff will be selected.
#' @param PFER integer (default = 2) representing the absolute number of
#'     false positives that we allow for in the final list of selected
#'     variables. For details see Meinshausen and Bühlmann (2010).
#' @param mc.cores integer (default = 1) specifying the number of cores to
#'     use in \code{\link[parallel]{mclapply}}, which is the default way
#'     \code{\link[stabs]{stabsel}} does parallelization.
#' @param ... additional parameters that can be passed on to
#'     \code{\link[stabs]{stabsel}}.
#'
#' @details Randomized lasso stability selection runs a randomized lasso
#'     regression several times on subsamples of the response variable and
#'     predictor matrix. N/2 elements from the response variable are randomly
#'     chosen in each regression, where N is the length of the vector. The
#'     corresponding section of the predictor matrix is also chosen, and the
#'     internal \code{.glmnetRandomizedLasso} function is applied.
#'     Stability selection results in selection probabilities for each
#'     predictor. The probability of a specific predictor is the number of
#'     times it was selected divided by the total number of subsamples that
#'     were done (total number of times the regression was performed).
#'
#'     We made use of the \code{stabs} package that implements lasso stability
#'     selection, and adapted it to run randomized lasso stability selection.
#'
#' @return  A \code{SummarizedExperiment} object where the rows are the
#'     observations and the columns the predictors (same dimnames as the
#'     predictor matrix \code{x}).
#'     It contains: \describe{
#'       \item{assays}{: \describe{
#'         \item{x}{: the predictor matrix.}
#'         }
#'       }
#'       \item{rowData}{: a DataFrame with columns: \describe{
#'         \item{y}{: the response vector.}
#'         }
#'       }
#'       \item{colData}{: a DataFrame with columns: \describe{
#'         \item{selProb}{: the final selection probabilities for the
#'           predictors (from the last regularization step).}
#'         \item{selected}{: logical indicating the predictors that made
#'           the selection with the specified cutoff.}
#'         \item{selAUC}{: the normalized area under the seletion curve
#'           (mean of selection probabilities over regulatization steps).}
#'         \item{reg'\code{i}'}{: columns containing the selection
#'           probabilities for regularization step i. }
#'         }
#'       }
#'       \item{metadata}{: a list of output returned from
#'         \code{\link[stabs]{stabsel}} and \code{randLassoStabSel}: \describe{
#'         \item{stabsel.params.cutoff}{: probability cutoff set for selection
#'           of predictors (see \code{\link[stabs]{stabsel}}).}
#'         \item{stabsel.params.selected}{: elements with maximal selection
#'           probability greater \code{cutoff}
#'           (see \code{\link[stabs]{stabsel}}). }
#'         \item{stabsel.params.max}{: maximum of selection probabilities
#'           (see \code{\link[stabs]{stabsel}}).}
#'         \item{stabsel.params.q}{: average number of selected variables
#'           used (see \code{\link[stabs]{stabsel}}).}
#'         \item{stabsel.params.PFER}{: (realized) upper bound for the
#'           per-family error rate (see \code{\link[stabs]{stabsel}}).}
#'         \item{stabsel.params.specifiedPFER}{: specified upper bound for
#'           the per-family error rate (see \code{\link[stabs]{stabsel}}).}
#'         \item{stabsel.params.p}{: the number of effects subject to
#'           selection (see \code{\link[stabs]{stabsel}}).}
#'         \item{stabsel.params.B}{: the number of subsamples (see
#'           \code{\link[stabs]{stabsel}}).}
#'         \item{stabsel.params.sampling.type}{: the sampling type used for
#'           stability selection (see \code{\link[stabs]{stabsel}}).}
#'         \item{stabsel.params.assumption}{: the assumptions made on the
#'           selection probabilities (see \code{\link[stabs]{stabsel}}).}
#'         \item{stabsel.params.call}{: \code{\link[stabs]{stabsel}} the call.}
#'         \item{randStabsel.params.weakness}{: the weakness parameter in the
#'           randomized lasso stability selection.}
#'         }
#'       }
#'
#'     }
#'
#' @examples
#' ## create data set
#' Y <- rnorm(n = 500, mean = 2, sd = 1)
#' X <- matrix(data = NA, nrow = length(Y), ncol = 50)
#' for (i in seq_len(ncol(X))) {
#'   X[ ,i] <- runif(n = 500, min = 0, max = 3)
#' }
#' s_cols <- sample(x = seq_len(ncol(X)), size = 10,
#'   replace = FALSE)
#' for (i in seq_along(s_cols)) {
#'   X[ ,s_cols[i]] <- X[ ,s_cols[i]] + Y
#' }
#'
#' ## reproducible randLassoStabSel() with 1 core
#' set.seed(123)
#' ss <- randLassoStabSel(x = X, y = Y)
#'
#' ## reproducible randLassoStabSel() in parallel mode
#' ## (only works on non-windows machines)
#' if (.Platform$OS.type == "unix") {
#'     RNGkind("L'Ecuyer-CMRG")
#'     set.seed(123)
#'     ss <- randLassoStabSel(x = X, y = Y, mc.preschedule = TRUE,
#'                            mc.set.seed = TRUE, mc.cores = 2L)
#' }
#'
#' @seealso \code{\link[stabs]{stabsel}}
#'
#' @references N. Meinshausen and P. Bühlmann (2010), Stability Selection,
#'     \emph{Journal of the Royal Statistical Society: Series B
#'     (Statistical Methodology)}, \strong{72}, 417–73. \cr
#'     R.D. Shah and R.J. Samworth (2013), Variable Selection with Error
#'    Control: Another Look at Stability Selection,
#'    \emph{Journal of the Royal Statistical Society: Series B
#'    (Statistical Methodology)}, \strong{75}, 55–80. \cr
#'     B. Hofner, L. Boccuto, and M. Göker (2015), Controlling False
#'     Discoveries in High-Dimensional Situations: Boosting with Stability
#'     Selection, \emph{BMC Bioinformatics}, \strong{16} 144.
#'
#' @importFrom stabs stabsel
#' @importFrom SummarizedExperiment SummarizedExperiment
#'
#'@export
randLassoStabSel <- function(x, y, weakness=0.8, cutoff=0.8, PFER=2,
                             mc.cores=1L, ...) {

    # checks
    if (!is(x, "matrix")) {
        stop("'x' must be a matrix")
    }
    .assertVector(y, type = "numeric")
    if (nrow(x) != length(y)) {
        stop("nrow of 'x' and length of 'y' are not equal. The rows of
             x must be the same length and order as the elements in 'y'.")
    }
    if (!is.null(names(y)) && !is.null(rownames(x)) &&
        !all(names(y) == rownames(x))) {
        stop("'x' and 'y' have different names. Make sure that the names are
             identical and that the orders match.")
    }
    if (is.null(rownames(x))) {
        rownames(x) <- paste0("obs", seq_len(nrow(x)))
    }
    if (is.null(colnames(x))) {
        colnames(x) <- paste0("pred", seq_len(ncol(x)))
    }


    # run randomized lasso stability selection
    ss <- stabs::stabsel(x = x, y = y, fitfun = .glmnetRandomizedLasso,
                         args.fitfun = list(weakness = weakness),
                         cutoff = cutoff, PFER = PFER, mc.cores = mc.cores, ...)


    # restructure as SummarizedExperiment object
    mdat <- list(stabsel.params.cutoff = ss$cutoff,
                 stabsel.params.selected = ss$selected,
                 stabsel.params.max = ss$max,
                 stabsel.params.q = ss$q,
                 stabsel.params.PFER = ss$PFER,
                 stabsel.params.specifiedPFER = ss$specifiedPFER,
                 stabsel.params.p = ss$p,
                 stabsel.params.B = ss$B,
                 stabsel.params.sampling.type = ss$sampling.type,
                 stabsel.params.assumption = ss$assumption,
                 stabsel.params.call = ss$call,
                 randStabsel.params.weakness = weakness
                 )

    probMat <- as(ss$phat, "DataFrame")
    colnames(probMat) <- paste0("regStep", seq_len(ncol(probMat)))
    cdat <- S4Vectors::DataFrame(selProb = probMat[, ncol(probMat)],
                                 selected = seq.int(ncol(x)) %in% ss$selected,
                                 selAUC = rowMeans(as.matrix(probMat)),
                                 probMat)
    rdat <- S4Vectors::DataFrame(y = y)

    se <- SummarizedExperiment::SummarizedExperiment(assays = list(x = x),
                                                     rowData = rdat,
                                                     colData = cdat,
                                                     metadata = mdat)

    # return
    return(se)
}



