# ******************************************************************************
# Created: 22-May-2017
# Author:  J. DuBois
# Contact: jason.dubois@wildlife.ca.gov
# Purpose: This file contains development code (possibly) functions or methods
#          used to model life tables on striped bass data
# ******************************************************************************

# libraries and source files ----------------------------------------------

library(ggplot2)
source(file = "source/functions_life-table.R")

# load data ---------------------------------------------------------------

StriperAll <- readRDS(file = "data/tagging/StriperAll.rds")
SBAnglerReturns <- readRDS(file = "data/tagging/SBAnglerReturns.rds")

# data summary - a first step ---------------------------------------------

do.call(rbind, Map(function(x) sum(is.na(x)), StriperAll))
do.call(rbind, Map(function(x) sum(is.na(x)), SBAnglerReturns))

with(data = StriperAll, expr = {
  # print(table(RelYear, Age, useNA = "ifany"))
  # print(table(RelYear, AgeCat, useNA = "ifany"))
  # print(table(FL, Age, useNA = "ifany"))
  print(length(FL[FL < 10 & !is.na(FL)]))
  table(RelYear[FL < 10 & !is.na(FL)], useNA = "ifany")
})

# remove ages 0 & 1 as these denote no age or no sample
bool_age_01 <- StriperAll$Age %in% 0:1

# obvious entry errors with lengths < 10 cm FL
ggplot(data = StriperAll[!bool_age_01, ], mapping = aes(x = Age, y = FL)) +
  geom_point(alpha = 1/10)

# data summary - ages -----------------------------------------------------

with(data = StriperAll[StriperAll$Method %in% "FT", ], expr = {
  # table(Age, useNA = "ifany")
  table(RelYear, Age, useNA = "ifany")
  # table(RelYear, AgeCat, useNA = "ifany")
  # table(RelYear, Age, Sex, useNA = "ifany")
  # table(RelYear, AgeCat, Sex, useNA = "ifany")
})

ggplot(data = StriperAll[!bool_age_01, ], mapping = aes(x = Age)) +
  stat_count(geom = "point")

# section clean-up
rm(bool_age_01)

# catch curve analytics ---------------------------------------------------

# a catch curve will give us mortality (or survival) from one age group to
# another

# TODO: perhaps run catch curve per year where by mortality is calculated
# between ages (e.g., 3-4, 4-5, 5-6)

# life table function development -----------------------------------------

# ********************************************************************
# using data from table in link below to test LifeTable() function
# http://www.tiem.utk.edu/~gross/bioed/bealsmodules/lifetables.html

# for now will focus on ax, lx, dx variables in table

# data from table
ax <- c(996, 668, 295, 190, 176, 172, 167, 159, 154, 147, 105, 22, 0)

lx <- round(ax / ax[1], digits = 3)

dx <- NULL

for (i in seq_along(lx)) {
  dx[i] <- lx[i] - lx[i+1]
}

qx <- dx / lx

LifeTable(ax)

# section clean-up
rm(ax, dx, i, lx, qx)

# ********************************************************************

# more testing: using data from Elements of Ecology p. 219, table 11.3

ax <- c(
  1000, 863, 778, 694, 610, 526, 442,
  357, 181, 59, 51, 42, 34, 25, 17, 9
)

LifeTable(ax)


# ********************************************************************

# testing StaticFrequency() on striper data
StaticFrequency(StriperAll, x = Age, Age > 2 & Age < 10)

lst_striper_all <- split(
  StriperAll,
  f = StriperAll[, c("RelYear", "Sex")]
)

# testing LifeTable() on all striper data
nx <- lapply(lst_striper_all, FUN = function(d) {
  StaticFrequency(d, x = Age, Age > 3)
})

Map(LifeTable, nx)

# ********************************************************************

# default year 1969, ages 3-20
LifeTable(CohortFrequency(Method %in% "FT")$Freq)

years <- unique(
  StriperAll$RelYear[StriperAll$Method %in% "FT"]
)
years <- setNames(years, nm = years)

# multiple years
lapply(1969:1970, FUN = function(y) {
  cf <- CohortFrequency(ageBegin = 4, ageEnd = 10, year = y)
  LifeTable(cf[["Freq"]])
})

lapply(years, FUN = function(y) {
  cf <- CohortFrequency(Method %in% "FT", ageBegin = 4, ageEnd = 10, year = y)
  LifeTable(cf[["Freq"]])
})

