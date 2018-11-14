#' show object
#' @param x TreeSE object
#' @export
setMethod("show", signature("TreeSE"),
          function(object) {
            cat("class: TreeSE \n", sep = " ")
            cat("dim:", nrow(object), ncol(object), "\n", sep = " ")
            cat("metadata:\n")
            cat(show(metadata(object)))
            cat("rowData:\n")
            cat(show(rowData(object)), "\n")
            cat("colData:\n")
            cat(show(colData(object)))
          })

#' Generic method to aggregateTree
#' @param x object
#' @param ... other parameters
#' @export
setGeneric("aggregateTree", signature = "x",
           function(x, ...)
             standardGeneric("aggregateTree"))

#' Method to aggregate a TreeSE object
#' @param x TreeSE object
#' @param selectedLevel level to select nodes from
#' @param selectedNodes used to set states on individual nodes to define a cut on the tree
#' @param start,end indices to filter nodes
#' @param by "row" to aggregate the TreeIndex on rowData, "col" to aggregate TreeIndex on colData
#' @param aggFun aggregate function to use, by default colSums if by="row", rowSums if by="col"
#' @param format return format can be one of "counts" or "TreeSE"
#' @import matrixStats
#' @export
setMethod("aggregateTree", "TreeSE",
          function(x,
                   selectedLevel = 3,
                   selectedNodes = NULL,
                   aggFun = colSums,
                   start = 1,
                   end = NULL,
                   by = "row",
                   format = "TreeSE") {

            if (is.null(end) || missing(end)) {
              end <- nrow(x)
            }

            if (by == "row") {
              aggfun <- colSums
              groups <-
                splitAt(
                  rowData(x),
                  selectedLevel = selectedLevel,
                  selectedNodes = selectedNodes,
                  start = start,
                  end = end,
                  format = "list"
                )
              counts <-  assays(x)$counts

              newMat <- array(NA, dim = c(length(groups), ncol(x)))
              for (i in seq_along(groups)) {
                indices <- groups[[i]]
                if(length(indices) == 1) {
                  newMat[i,] = counts[indices,]
                }
                else {
                  newMat[i,] = aggFun(counts[indices,])
                }
              }

              rownames(newMat) <- names(groups)
              colnames(newMat) <- colnames(x)

            }
            else if (by == "col") {
              aggfun <- rowSums
              groups <-
                splitAt(
                  colData(x),
                  selectedLevel = selectedLevel,
                  selectedNodes = selectedNodes,
                  start = start,
                  end = end,
                  format = "list"
                )
              counts <-  assays(x)$counts

              newMat <- array(NA, dim = c(nrow(x), length(groups)))
              for (i in seq_along(groups)) {
                indices <- groups[[i]]
                if(length(indices) == 1) {
                  newMat[, i] = counts[, indices]
                }
                else {
                  newMat[, i] = aggFun(counts[, indices])
                }
              }

              colnames(newMat) <- names(groups)
              rownames(newMat) <- rownames(x)
            }

            if (format == "TreeSE") {
              if (by == "row") {
                newRowData <-
                  splitAt(
                    rowData(x),
                    selectedLevel = selectedLevel,
                    selectedNodes = selectedNodes,
                    start = start,
                    end = end,
                    format = "TreeIndex"
                  )

                newColData <- colData(x)
              }
              else if (by == "col") {
                newRowData <- rowData(x)
                newColData <-
                  splitAt(
                    colData(x),
                    selectedLevel = selectedLevel,
                    selectedNodes = selectedNodes,
                    start = start,
                    end = end,
                    format = "TreeIndex"
                  )
              }

              newSumExp <- SummarizedExperiment(SimpleList(counts = newMat))
              rowData(newSumExp) <- newRowData
              colData(newSumExp) <- newColData

              newTreeSE <- new("TreeSE", newSumExp)

              return(newTreeSE)
            }
            else if (format == "counts") {
              return(newMat)
            }
          })