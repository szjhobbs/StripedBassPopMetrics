# ******************************************************************************
# Created: 27-Jun-2017
# Author:  J. DuBois
# Contact: jason.dubois@wildlife.ca.gov
# Purpose: This file contains development code for implementing a mark-recapture
#          model on 2017 striped bass within-season recapture data. Model will
#          (likely) be implemented using package RMark (a front-end to program
#          MARK). Program MARK is installed on my desktop, and RMark (appears)
#          to require such installation.
# ******************************************************************************

# Very rough coordinates for Sacramento River around Knights Landing
# 38.835390, -121.731286 (top)
# 38.801535, -121.698093 (bottom)

# libraries and source files ----------------------------------------------

library(RMark)
library(dplyr)

# help documentation
# http://www.phidot.org/software/mark/rmark/

source("source/source_sb_mark-recap.R")

# load data ---------------------------------------------------------------

StriperAll <- readRDS(file = "data/tagging/StriperAll.rds")
SBEffort <- readRDS(file = "data/tagging/SBEffort.rds")

# get only 2017 data
dat2017 <- subset(StriperAll, subset = RelYear %in% 2017)
effort2017 <- subset(SBEffort, subset = RelYear %in% 2017)

# get recaptured fish -----------------------------------------------------

# recapture fish from 2017 sorted by days at large (DAL)
recap2017 <- RecapSummary(StriperAll, year = 2017, datSort = "DAL")

# table tagged x recap with only tags from 2017 release
with(data = recap2017[!(recap2017$TagNum %in% 292095), ], expr = {
  tag <- format(Tagged, "%m-%d")
  rec <- format(Recap, "%m-%d")
  
  # table(tag, rec, useNA = "ifany", dnn = c("Tagged", "Recap"))
  table(tag, rec, dnn = c("Tagged", "Recap"))
})

# count by trap -----------------------------------------------------------

# fished 8 traps in 2017

# TagAction
# 1 = tagged
# 2 = recaptured
# 5 = over (no tag, no data)
# 6 = fish dead
# 7 = creeled (no tag, data collected)

with(data = dat2017, expr = {
  table(Trap = DriftTrap, TagAction)
})

# count by trap tagged trap recaptured ------------------------------------

# allow for viewing from where recapture fish were tagged

# removes 2016 tag & 2017 tag recaptured dead
bool_tags_remove <- recap2017$TagNum %in% c("292095", "295892")

tag_rec <- with(data = recap2017[!bool_tags_remove, ], expr = {
  
  tag <- factor(TrapTag, levels = 1:8)
  rec <- factor(TrapRec, levels = 1:8)
  
  table(tag, rec, dnn = list("TrapTag", "TrapRec"))
})

tag_rec
sum(diag(tag_rec))               # recaptured in same trap as tagged
sum(tag_rec[upper.tri(tag_rec)]) # recaptured downriver
sum(tag_rec[lower.tri(tag_rec)]) # recaptured upriver

# count by date -----------------------------------------------------------

tags_remove <- c("292095", "295892")

# lkp_tag_action <- c(
#   '1' = "NewMrk", '2' = "Recapt",
#   '5' = "UnMkrd", '6' = "UnMkrd",
#   '7' = "UnMkrd"
# )

lkp_tag_action <- c('1' = "Nm", '2' = "R", '5' = "U", '6' = "U", '7' = "U")

dat2017$TagAction <- lkp_tag_action[as.character(dat2017$TagAction)]

# where Nm = new marked (tagged)
#       R  = recaptured
#       U  = un-marked (not tagged)

count_date_action <- dat2017 %>% 
  filter(!is.na(DriftTrap) & !(TagNum %in% tags_remove)) %>% 
  group_by(RelDate, TagAction) %>% 
  count() %>% 
  reshape2::dcast(formula = RelDate ~ TagAction, value.var = "n", fill = 0)

n_records <- nrow(count_date_action)

count_date_action <- within(data = count_date_action, expr = {
  
  # recaptures
  # Ri <- cumsum(R)
  
  # marked fish in population just prior to sample
  Mi <- c(0, cumsum(Nm[1:(n_records - 1)]))
  
  # total caputured
  Ci <- Nm + R + U
  
  # CiMi <- Ci * Mi
  # 
  # CiMi2 <- Ci * Mi^2
  # 
  # MiR <- Mi * R
  
})

# now using count_date_action, we can get Pop Est N using Schnabel,
# Schumacher-Eschmeyer, & Petersen

with(data = count_date_action, expr = {
  
  CiMi <- Ci * Mi
  CiMi2 <- Ci * Mi^2
  MiR <- Mi * R
  
  N_schnbl <- sum(CiMi) / (sum(R) + 1)
  Ni_schnbl <- cumsum(CiMi) / (cumsum(R) + 1)
  
  N_schesh <- 1 / (sum(MiR) / sum(CiMi2))
  Ni_schesh <- 1 / (cumsum(MiR) / cumsum(CiMi2))
  
  list(
    Ni_schnbl = Ni_schnbl,
    Ni_schesh = Ni_schesh,
    N_schnbl = N_schnbl,
    # Var_schnbl = sum(R) / sum(CiMi)^2,
    Upp_schnbl = sum(CiMi) / (35.3),
    Low_schnbl = sum(CiMi) / (63.6),
    N_schesh = N_schesh
  )
  
  # from appendix II, Ricker to get upper & lower CI
  # 34.5, 62.5
  
})

# as confirmation
# with(data = count_date_action, expr = {
#   FSA::mrClosed(
#     M = Mi,
#     n = Ci,
#     m = R,
#     R = NULL,
#     method = "Schnabel",
#     chapman.mod = TRUE
#   )
# })

# development: matrix for MARK (capture history) --------------------------

# 17-Jul-2017: 

# for now will use only 2017 data but should consider applying this code to 
# other years or on an annual basis (i.e., recaps from previous seasons)

# trying xtab of TagNum ~ RelDate (need tagged & recapped only)

test <- xtabs(
  formula =  ~ TagNum + format(RelDate, format = "%m-%d"),
  data = dat2017,
  subset = TagAction %in% 1:2,
  # addNA = TRUE, 
  exclude = c("292095", "295892")
  # excludes 2016 TY recapture & 2017 tagged then found dead next day
)

# renaming dimnames() for convenience otherwise name remains long & cumbersome
# as example `format(RelDate, format = "%m-%d")`
dim(test)
names(dimnames(test)) <- c("TagNum", "Date")
dimnames(test)

# to ensure columns of xtab represent all dates sampled & dates of no sample
# (represented in matrix by '.'); formatting merely for convenience
date_range <- range(as.Date(dat2017$RelDate))

dates_sampled <- format(unique(dat2017$RelDate), format = "%m-%d")

dates_seq <- format(
  seq(from = date_range[1], to = date_range[2], by = 1),
  format = "%m-%d"
)

# # for adding additional columns to matrix; for now not needed ****************
# dates_seq %in% dimnames(test)[["Date"]]
# dates_sampled %in% dimnames(test)[["Date"]]
# # ****************************************************************************

# sets up new matrix with same number of rows but more columns to include days
# for which no sampling was performed
new_test <- matrix(
  data = NA,
  nrow = nrow(test),
  ncol = length(dates_seq),
  dimnames = list(TagNum = dimnames(test)[["TagNum"]], Date = dates_seq)
)

# fills new matrix with data from original xtabs() result
new_test[, dates_seq %in% dimnames(test)[["Date"]]] <- test

# ensures sampled date (but none tagged or none recaptured) is set to all 0s
new_test[, dates_sampled[!dates_sampled %in% dimnames(test)[["Date"]]]] <- 0

# . = did not sample
new_test[is.na(new_test)] <- '.'

# final 'output'
out <- apply(new_test, MARGIN = 1, FUN = function(x) paste0(x, collapse = ''))

index <- match(
  dat2017$TagNum[dat2017$TagAction %in% 1 & !is.na(dat2017$TagNum)],
  table = names(out)
)

# for use with co-variate
# out <- data.frame(
#   ch = out,
#   sex = dat2017$Sex[index], stringsAsFactors = FALSE
# )

out <- data.frame(ch = out, stringsAsFactors = FALSE)

mark(data = out, model = "POPAN")

# development: probability of movement within period ----------------------

# data.frame(
#   RelDate = effort2017$RelDate,
#   TimeEnd = strftime(effort2017$EndTime, format = "%H:%M"),
#   DriftTrap = effort2017$DriftTrap,
#   stringsAsFactors = FALSE
# )

# below still not ideal as we really don't know when (i.e., what time) the fish
# swam into (was recaptured) in the trap; all we know is (say for DAL = 1) the
# fish swam into the trap within 24 hours

# index_tag <- match(
#   paste(recap2017$Tagged, recap2017$TrapTag),
#   table = paste(effort2017$RelDate, effort2017$DriftTrap)
# )
# 
# index_rec <- match(
#   paste(recap2017$Recap, recap2017$TrapRec),
#   table = paste(effort2017$RelDate, effort2017$DriftTrap)
# )
# 
# recap2017$HAL <- as.numeric(
#   difftime(
#     effort2017[index_rec, "EndTime"],
#     effort2017[index_tag, "EndTime"],
#     units = "hours"
#   )
# )

# fraction moving upstream
mean(recap2017$TrapRec[2:48] < recap2017$TrapTag[2:48])


