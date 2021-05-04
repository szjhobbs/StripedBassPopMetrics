

test <- subset(
  Stripers,
  subset = CaptureMethod == 2 &
    !(RelAge %in% 0:1) & !is.na(RelAge) &
    RelFL >= 42
)

sv <- list(Linf = 150, K = 0.04, t0 = 2)


fit_vbgm <- FitVBGM(data = test, len = RelFL, age = RelAge, start = sv)


l <- split(test[c("RelFL", "RelAge")], f = test[["RelYear"]])


fit_l <- lapply(l, FUN = FitVBGM, len = RelFL, age = RelAge, start = sv)

t(vapply(fit_l, FUN = function(x) x[["m"]]$getAllPars(), FUN.VALUE = numeric(3L)))


# 
# more code below ---------------------------------------------------------

test$RelAge <- factor(test[["RelAge"]], levels = 2:20, exclude = c(0, 1, NA))


table(test[["RelAge"]], useNA = "ifany")
table(test[["RelFL"]], useNA = "ifany")


table(test[["RelFL"]], test[["RelAge"]], useNA = "ifany")[,3]

ChapmanRobson(ages = as.numeric(names(ages)), n = unname(ages), N0 = 2)


fn <- function(l, a) {
  Ni <- table(l, dnn = NULL)
  # sum(Ni)
  li <- prop.table(Ni)
  
  ni <- aggregate(a, by = list(l = l), FUN = length)
  
  
  # list(
  #   N_i = Ni,
  #   N = sum(Ni),
  #   l_i = li
  #   n_i = ni
  # )
  
  
  
  # qij <- table(l, a, dnn = NULL) / ni[["x"]]
  qij <- prop.table(table(l, a, dnn = NULL), margin = 1)
  # 
  # 
  colSums(as.data.frame(li)[["Freq"]] * qij, na.rm = T)
  # as.data.frame(li)[["Freq"]] * qij
  # list(vapply(Ni, FUN = sample.int, FUN.VALUE = numeric(1L), size = 1),
  # Ni)
  
  # now need to allow switching size to fixed, proportional, or random
  # size <- vapply(Ni, FUN = function(x, ...) {
  #   sample.int(n = x, size = 1)
  # }, FUN.VALUE = numeric(1L), size = 1)
  
  size <- Size(Ni = Ni, n = 1500)
  
  # split age on length then use vapply results to sample ages per each length
  # may need to set some minimum in the vapply as a length bin with say 90 could
  # potentially be sampled only 1 time, which doesn't seem to make sense with so
  # many fish.
  
  al <- split(a, f = l)
  
  # lapply(al, FUN = sample, size = 1)
  tt <- Map(function(x, s) {
    # if (all(is.na(x))) return(NA)
    x <- x[!is.na(x)]
    if (length(x) < s) s <- length(x)
    sample(x, size = s)
  }, al, size)
  
  # sample(which(l %in% 43), size = 10, replace = F)
  # qij
  # ceiling(li * 2119) proportional sampling where 2119 is number of aged fish
  
  t(vapply(tt, FUN = table, FUN.VALUE = numeric(19L)))
  
}


# test me (delete) --------------------------------------------------------

# added 16-Apr-2019

#' @keywords internal
#'
Size <- function(Nj, n = 1500, type = c("fixed", "prop", "random")) {
  
  # if N is too low may cause floor() to be 0, so fn written to correct this
  fn <- function(x) if (x < 1) 1 else floor(x)
  
  s <- NULL
  
  type <- match.arg(
    arg = type,
    choices = c("fixed", "prop", "random"),
    several.ok = FALSE
  )
  
  fv <- numeric(1L)
  L <- dim(Nj)
  
  switch (
    EXPR = type,
    fixed = s <- rep(fn(n / L), times = L),
    prop = s <- vapply(n * prop.table(Nj), FUN = fn, FUN.VALUE = fv),
    random = s <- vapply(Nj, FUN = sample.int, FUN.VALUE = fv, size = 1)
  )
  
  # s
  list(
    s = s,
    n = if (type == "random") NA else n,
    type = type
  )
}
# end Size

#' @keywords internal
#'
# SampleAges <- function(ages, size) {
#   
#   # boolean to check for NA values
#   b <- is.na(ages)
#   
#   # maybe if needed, but for now not needed
#   # if (all(b)) return(NA)
#   
#   # warning was too cumbersome when running in 'apply' loop
#   if (sum(b) != 0) {
#     ages <- ages[!b]
#     # warning("Removed ", sum(b), " ages as NA.", call. = FALSE)
#   }
#   
#   # needed here for return statement below
#   attr(ages, which = "na_rm") <- sum(b)
#   
#   # sample everything if age count <= sample size
#   if (length(ages) <= size) return(ages)
#   
#   # otherwise get random sample of ages; replace FALSE (default)
#   res <- sample(ages, size = size)
#   
#   # post sample() as sample() removes attributes
#   attr(res, which = "na_rm") <- sum(b)
#   
#   res
# }
# # end SampleAges

SampleAges <- function(ages, size, reps = 100) {
  
  # boolean to check for NA values
  b <- is.na(ages)
  
  # maybe if needed, but for now not needed
  # if (all(b)) return(NA)
  
  # warning was too cumbersome when running in 'apply' loop
  if (sum(b) != 0) ages <- ages[!b]
  

  
  # sample everything if age count <= sample size
  if (length(ages) <= size) size <- length(ages)
  
  res <- replicate(n = reps, expr = {
    sample(ages, size = size)
  }, simplify = FALSE)
  
  
  
  # need to figure out format for proper output res is a list and then passed to
  # Map in ALKPrecision (30-Apr-2019  @ 1715)
  
  # res <- do.call(cbind, res)
  # res <- do.call(what = rbind, args = res)
    
  # sample(ages, size = size)  
  
  # otherwise get random sample of ages; replace FALSE (default)
  
  
  # post sample() as sample() removes attributes
  attr(res, which = "na_rm") <- sum(b)
  # 
  res
  # A <- length(levels(ages))
  # nj <- vapply(res, FUN = length, FUN.VALUE = numeric(1L))
  # nij <- t(vapply(res, FUN = table, FUN.VALUE = numeric(A)))
  # # qij <- nij / nj
  
  # Map(f = `/`, nij, nj)
  # 
  # vapply(nij, FUN = function(x, y) x / y, FUN.VALUE = numeric(100L), y = nj)
  
  # nij / nj
  
  # list(
  #   nj = nj,
  #   nij = nij
  # )
}
# end SampleAges

#' @keywords internal
#'
VarPi <- function(lj, qij, nj, pi, N) {
  
  n1 <- lj^2 * (qij * (1 - qij))
  n2 <- lj * (qij - pi)^2
  
  res <- (n1 / nj) + (n2 / N)
  
  colSums(res, na.rm = TRUE)
}
# end VarPi

Replicate <- function(n, expr) {
  fn <- eval.parent(substitute(function(...) expr))
  vapply(1:n, FUN = fn, FUN.VALUE = as.list(1:90))
  # vapply(1:n, FUN = fn, FUN.VALUE = )
}

#' Assess Precison of Age-Length Key Using Different Sampling Methods.
#'
#' @description Coming soon.
#'
#' @param data Dataframe containing age & length variables.
#' @param age Field name in `data` containing age variable.
#' @param len Field name in `data` containing length variable.
#' @param ... Passed to internal \code{Size()} function. Supply `n` for fixed or
#'   proportional sampling type. `n` is total sample size of ages (default is
#'   1500). Supply `type` as "fixed", "prop" (proportional), or "random." See
#'   Notes section.
#'
#' @note Coming soon.
#'
#' @references Coming soon.
#'
#' @return A list of class \code{ALKPrecision}
#'
#' @section Values:
#'
#' \describe{
#'   \item{N}{}.
#'   \item{L}{}.
#'   \item{A}{}.
#'   \item{Nj}{}.
#'   \item{lj}{}.
#'   \item{nj}{}.
#'   \item{nij}{}.
#'   \item{qij}{}.
#'   \item{pi}{}.
#'   \item{VarPi}{}.
#'   \item{RemovedNA}{}.
#'   \item{SizeArgs}{list}.
#' }
#'
#' @export
#'
#' @examples
#' # coming soon.
ALKPrecision <- function(data, age, len, ...) {
  
  # make i = age & j = length stratum
  
  a <- as.character(substitute(age))
  l <- as.character(substitute(len))
  
  # type <- match.arg(
  #   arg = sampling,
  #   choices = c("fixed", "prop", "random"),
  #   several.ok = FALSE
  # )
  
  Nj <- table(data[[l]], dnn = NULL)
  
  N <- sum(Nj)
  
  lj <- prop.table(Nj)
  
  size <- Size(Nj = Nj, ...)
  
  # perhaps try replicate() on Map() below [25-Apr-2019 @ 1705]
  
  A <- dim(table(data[[a]]))
  Lj <- as.vector(lj)
  
  reps <- formals(SampleAges)[["reps"]]
  
  res <- Map(f = SampleAges, split(data[[a]], f = data[[l]]), size[["s"]])
  
  # all output within replicate might be less cluttered, would make for using
  # far fewer lapply's or vapply's
  
  # res <- replicate(n = 5, expr = {
  #   # r <- Map(f = SampleAges, split(data[[a]], f = data[[l]]), size[["s"]])
  #   # 
  #   # nj <- vapply(r, FUN = length, FUN.VALUE = numeric(1L))
  #   # nij <- t(vapply(r, FUN = table, FUN.VALUE = numeric(A)))
  #   # nas <- sum(vapply(r, FUN = attr, FUN.VALUE = numeric(1L), which = "na_rm"))
  #   # qij <- nij / nj
  #   # 
  #   # pi <- colSums(qij * Lj, na.rm = TRUE)
  #   # varpi <- VarPi(lj = Lj, qij = qij, nj = nj, pi = pi, N = N)
  #   # 
  #   # list(
  #   #   nj = nj,
  #   #   nij = nij,
  #   #   qij = qij,
  #   #   nas = nas,
  #   #   pi = pi,
  #   #   varpi = varpi
  #   # )
  #   
  #   Map(f = SampleAges, split(data[[a]], f = data[[l]]), size[["s"]])
  #   
  # }, simplify = T)

  # res <- Replicate(n = 5, expr = {
  #   Map(f = SampleAges, split(data[[a]], f = data[[l]]), size[["s"]])
  # })
  
  # nj <- vapply(res, FUN = length, FUN.VALUE = numeric(1L))
  # nj <- vapply(res, FUN = function(x) length(unlist(x)), FUN.VALUE = numeric(1L))
  # nj <- lapply(res, FUN = length)
  
  # nj <- vapply(1:100, FUN = function(i) {
  #   vapply(res[[i]], FUN = length, FUN.VALUE = numeric(1L))
  # }, FUN.VALUE = numeric(90L))
  # 
  # nj <- vapply(res[[1]], FUN = length, FUN.VALUE = numeric(1L))
  # 
  # A <- dim(table(data[[a]]))
  # 
  # nij <- lapply(1:5, FUN = function(i) {
  #   t(vapply(res[[i]], FUN = table, FUN.VALUE = numeric(A)))
  # })
  # 
  # vapply(res, FUN = length, FUN.VALUE = numeric(1L))
  
  # nj <- vapply(res, FUN = function(x) {
  #   vapply(x, FUN = length, FUN.VALUE = numeric(1L))
  # }, FUN.VALUE = numeric(2L))
  # 
  A <- dim(table(data[[a]]))
  Lj <- as.vector(lj)



  # nij <- lapply(res, FUN = function(x) {
  #   # t(vapply(x, FUN = table, FUN.VALUE = numeric(A)))
  #   lapply(x, FUN = table)
  # })#, FUN.VALUE = numeric(2*A))
  
  # nij <- lapply(res, function(x) x[[1]])
  # nij <- lapply(res, function(x) {
  #   t(vapply(x, FUN = table, FUN.VALUE = numeric(A)))
  # })
  # nas <- sum(vapply(res, FUN = attr, FUN.VALUE = numeric(1L), which = "na_rm"))
  
  # 01-May-2019 ****************************************************************
  
  # below works but need to figure out how to get number of samples (right now
  # hardcodeded, which is not ideal); need to figure out `nas`; need to update
  # code in `sportfish`; think about what to return from `test`
  
  # used formals() to get number of samples(reps) -- worked well
  # can't verify na count so for now will skip `nas` -- it's not imperative
  # test for now can return most everything then output of ALKPrecision() can
  # be selective -- may want to add pi to `out`
  
  # ****************************************************************************
  
  
  # test <- lapply(res, FUN = `[[`, 1)
  test <- lapply(seq_len(reps), FUN = function(i) {
    r <- lapply(res, FUN = `[[`, i)
    # nas <- sum(vapply(res[i], FUN = attr, FUN.VALUE = numeric(1L), which = "na_rm"))
    
    nj <- vapply(r, FUN = length, FUN.VALUE = numeric(1L))
    nij <- t(vapply(r, FUN = table, FUN.VALUE = numeric(A)))
    
    
    qij <- nij / nj
    pi <- colSums(qij * Lj, na.rm = TRUE)
    varpi <- VarPi(lj = Lj, qij = qij, nj = nj, pi = pi, N = N)
    
    list(nj = nj, nij = nij, qij = qij,
         pi = pi, varpi = varpi, vartot = sum(varpi))#, nas = nas)
  })
  
  # t(vapply(test, FUN = table, FUN.VALUE = numeric(A)))
  vt <- vapply(test, FUN = function(x) x[["vartot"]], FUN.VALUE = numeric(1L))
  
  out <- list(
    VarTot = vt,
    MeanVT = mean(vt),
    VarVT = var(vt),
    Reps = reps#,
    # NAsRemoved = nas
  )
  
  return(out)
  

  
  

  
  
  return(pi)
  
  
  
  # # nij <- t(vapply(res, FUN = function(x) table(unlist(x)), FUN.VALUE = numeric(A)))
  # nij <- lapply(1:5, FUN = function(i) {
  #   t(vapply(res[[i]], FUN = table, FUN.VALUE = numeric(A)))
  # })
  # 
  # return(res)
  # return(nij)
  # return(nij)
  # qij <- Map(`/`, nij, nj)
  # return(as.vector(lj))
  # return(Nj)
  # return(colSums(qij * Lj, na.rm = TRUE))
  # Lj <- as.vector(lj)
  
  # pi <- vapply(qij, FUN = function(x) colSums(x * Lj, na.rm = TRUE), FUN.VALUE = numeric(A))
  
  # return(VarPi(lj = Lj, qij = qij, nj = nj, pi = pi, N = N))
  
  # return(Map(VarPi, lj = Lj, qij = qij, nj = nj, pi = t(pi), N = N))
  # return(Map(function(x, y, z) 
  #   VarPi(lj = Lj, qij = x, nj = z, pi = y, N = N), qij, pi, nj)
  # )
  
  # return(pi)
  
  nj <- vapply(res, FUN = length, FUN.VALUE = numeric(1L))
  
  A <- dim(table(data[[a]]))
  
  nij <- t(vapply(res, FUN = table, FUN.VALUE = numeric(A)))
  
  qij <- nij / nj
  
  # for multiplication in pi & VarPi below
  Lj <- as.vector(lj)
  
  pi <- colSums(qij * Lj, na.rm = TRUE)
  varpi <- VarPi(lj = Lj, qij = qij, nj = nj, pi = pi, N = N)
  
  # to count age NA values removed
  nas <- sum(vapply(res, FUN = attr, FUN.VALUE = numeric(1L), which = "na_rm"))
  
  out <- list(
    N = N,
    L = dim(Nj),
    A = A,
    Nj = Nj,
    lj = lj,
    nj = nj,
    nij = nij,
    qij = qij,
    pi = pi,
    VarPi = varpi,
    RemovedNA = nas,
    SizeArgs = size[c("n", "type")]
    # SizeArgs = unlist(size[c("n", "type")])
  )
  
  class(out) <- "ALKPrecision"
  
  out
}
# end ALKPrecision



