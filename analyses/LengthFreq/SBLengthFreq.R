# ******************************************************************************
# Created: 08-Apr-2016
# Author:  J. DuBois
# Contact: jason.dubois@wildlife.ca.gov
# Purpose: This file creates all items associated with ??
# ******************************************************************************

# TODO (J. DuBois, 11-Apr-2016): add code to complete striped bass length 
# frequency distributions; intiially I used this file to get striped bass data
# for J. Smith (researcher out of Washington state)

# File Paths --------------------------------------------------------------

#data_import <- "C:/Data/jdubois/RDataConnections/Sturgeon"

# Libraries and Source Files ----------------------------------------------

library(ggplot2)
#library(reshape2)
#library()

source(file = "../../RDataConnections/StripedBass/TaggingData.R")
source(file = "../../RSourcedCode/methods_len_freq.R")
source(file = "source_sb_mark-recap.R")
#source(file = "Analysis-General/????.R")

# Workspace Clean Up ------------------------------------------------------

#rm()

# Variables ---------------------------------------------------------------

# testing saving data to csv

# large file ~ 18Mb
# write.csv(
#   StriperAll,
#   file = "C:/Users/jdubois/Desktop/ASB_JoeSmith/StriperAll.csv",
#   row.names = FALSE
# )
# 
# # much smaller @ ~1.3Mb
# saveRDS(
#   object = StriperAll,
#   file = "Analysis-LengthFreq/StriperAll.rds"
# )




