# Add melt generic, don't import reshape2 as it requires R >= 3.0.0.
melt <- function(data, ..., na.rm = FALSE, value.name = "value") {
  if (is.data.table(data))
    UseMethod("melt", data)
  else
    reshape2::melt(data, ..., na.rm=na.rm, value.name=value.name)
}

patterns <- function(..., cols=character(0L)) {
  # if ... has no names, names(list(...)) will be "";
  #   this assures they'll be NULL instead
  p = unlist(list(...), use.names = any(nzchar(names(...))))
  if (!is.character(p))
    stop("Input patterns must be of type character.")
  lapply(p, grep, cols)
}

melt.data.table <- function(data, id.vars, measure.vars, variable.name = "variable",
       value.name = "value", ..., na.rm = FALSE, variable.factor = TRUE, value.factor = FALSE,
       verbose = getOption("datatable.verbose")) {
  if (!is.data.table(data)) stop("'data' must be a data.table")
  if (missing(id.vars)) id.vars=NULL
  if (missing(measure.vars)) measure.vars = NULL
  measure.sub = substitute(measure.vars)
  if (is.call(measure.sub) && measure.sub[[1L]] == "patterns") {
    measure.sub = as.list(measure.sub)[-1L]
    idx = which(names(measure.sub) %in% "cols")
    if (length(idx)) {
      cols = eval(measure.sub[["cols"]], parent.frame())
      measure.sub = measure.sub[-idx]
    } else cols = names(data)
    pats = lapply(measure.sub, eval, parent.frame())
    measure.vars = patterns(pats, cols=cols)
  }
  if (is.list(measure.vars) && length(measure.vars) > 1L) {
    meas.nm = names(measure.vars)
    if (is.null(meas.nm)) {
      # user-provided or default stub
      if (length(value.name) == 1L) {
        value.name = paste0(value.name, seq_along(measure.vars))
      }
    } else {
      if (length(value.name) > 1L) {
        warning("'value.name' provided in both 'measure.vars'",
                "and 'value.name argument'; value provided in",
                "'measure.vars' is given precedence.")
      }
      if (anyNA(meas.nm) || !all(nzchar(meas.nm))) {
        stop("Please provide a name to each element of 'measure.vars'.")
      }
      value.name = meas.nm
    }
  }
  ans <- .Call(Cfmelt, data, id.vars, measure.vars,
      as.logical(variable.factor), as.logical(value.factor),
      variable.name, value.name, as.logical(na.rm),
      as.logical(verbose))
  setDT(ans)
  if (any(duplicated(names(ans)))) {
    cat("Duplicate column names found in molten data.table. Setting unique names using 'make.names'\n")
    setnames(ans, make.unique(names(ans)))
  }
  setattr(ans, 'sorted', NULL)
  ans
}
