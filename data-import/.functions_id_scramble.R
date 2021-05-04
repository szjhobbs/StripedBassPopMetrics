# ******************************************************************************
# Created: 22-Jun-2016
# Author:  J. DuBois
# Contact: jason.dubois@wildlife.ca.gov
# Purpose: This file contains functions that scramble and descramble sensitive
#          IDs for posting on-line in public view. (For example, scramble 
#          CustomerId in Sturgeon Report Card data)
# Revamped: 29-Jan-2019 for use in this project
# ******************************************************************************

# NOTE: ScrambleId() assumes for now id is integer data type. DescrambleId()
# assumes id is character data type (i.e., the result of ScrambleId()). May
# upgrade in future to scramble / descramble other data types, but for now this
# will suffice (23-Jun-2016)

ScrambleId <- function(id) {
  # function scrambles a sensitive id (like CustomerId) for posting online in
  # public display (like GitHub) and still allowing for grouping by unique
  # records
  
  # Args:
  #    id: the sensitive ID to be scrambled (assumed for now is integer type)
  
  # Returns:
  #    scrambled ID, now with letter as first character
  
  # convert to character for string spliting below
  if (!is.character(id)) {
    id <- as.character(id)
  }
  
  # split on each character
  lst_split_char <- strsplit(id, split = "")
  
  res <- vapply(lst_split_char, FUN = function(x) {
    
    # splitting on NA will return NA, check vector x for NA & return NA if all
    # are NA; essentially all will be NA when x is length = 1 & the 1 element is
    # NA, otherwise all elements of x should be numeric
    if (all(is.na(x))) return(NA_character_)
    
    # get length of the split id
    len_x <- length(x)
    
    # last value in id get alpha counter part
    let <- LETTERS[as.numeric(x[len_x]) + 1]
    
    # collapse all elements less first one into 1 element, covert to numeric,
    # and then add 111 (arbitrary)
    y <- paste0(x[-len_x], collapse = "")
    y <- as.numeric(y) + 111
    
    #  add let (LETTER) as first char in new (scrambled) id with dash as
    #  separator to further obfuscate
    paste(let, y, sep = "-")
    
  }, FUN.VALUE = character(1L), USE.NAMES = FALSE)
  
  # function output (a new, scrambled id)
  attr(res, which = "id") <- "scrambled"
  res
}
# end ScrambleId

DescrambleId <- function(id) {
  # function descrambles a scrambled id (i.e., result of ScrableId fun) for
  # purpose of relating back to specific angler and finding info about said
  # angler as needed
  
  # Args:
  #    id: the scrambled id to be descrambled
  
  # Returns:
  #    ID in original format (for now converts to INT assuming this is 
  #    original format - may automate this later)
  
  # remove '-' from scrambled id
  id <- sub(pattern = "\\-", replacement = "", x = id)
  
  # split on each character
  lst_split_char <- strsplit(id, split = "")
  
  res <- vapply(lst_split_char, FUN = function(x) {
    
    # splitting on NA will return NA, check vector x for NA & return NA if all
    # are NA; essentially all will be NA when x is length = 1 & the 1 element is
    # NA, otherwise all elements of x should be numeric
    if (all(is.na(x))) return(NA_integer_)
    
    # last value in id get alpha counter part
    num_last <- which(LETTERS %in% x[1]) - 1
    
    # add 1 to each of the other elements in x less the last element as it will
    # now be alpha instead of numeric
    # y <- as.numeric(x[-1]) - 1
    y <- paste0(x[-1], collapse = "")
    y <- as.numeric(y) - 111
    
    #  collapse numeric vector to single element & add let (LETTER) as first
    #  char in new (scrambled) id and convert to double
    as.integer(paste0(y, num_last))
    
  }, FUN.VALUE = numeric(1L), USE.NAMES = FALSE)
  
  # function output (descrambled id)
  attr(res, which = "id") <- "descrambled"
  res
}
# end DescrambleId

# Function testing - run as needed ----------------------------------------

# test_id <- as.integer(c(17896, 17900, 17896, NA))
# test_scramble_id <- ScrambleId(id = test_id)
# 
# DescrambleId(id = test_scramble_id)
# 
# identical(
#   DescrambleId(id = test_scramble_id),
#   test_id
# )
# 
# rm(test_id, test_scramble_id)
