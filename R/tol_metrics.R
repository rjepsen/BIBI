#==============================================================================
#Tolerance Metrics
#==============================================================================
#'Compute Tolerance Indices
#'
#'@param long = Taxonomic counts arrange in a long data format (i.e., each
#'row represents a unique sample and taxon).
#'@param master = A master taxa list including taxonomic ranks Phylum through
#'the specified taxonomic rank (Family or Genus) and the an
#'associated list of tolerance values. The default is set to the master taxa
#'list included in the BIBI package.  The master taxa list can be viewed with
#'the following script: master.df <- BIBI::master
#'@param tolerance.value = The name of the column in the master taxon list
#'(specified using the master variable) that contains tolerance values on
#'a scale of 0-10.
#'@param rank = The taxonomic rank used to perform the analysis. You must
#'sepecify either "FAMILY" or "GENUS" (Defualt = "FAMILY").
#'@param remove_na = If taxa are missing tolerance assigned tolerance values
#' (tolerance.value == NA) then the scores could be skewed downward. Setting this
#' parameter to TRUE will exclude these taxa and provide a better estimate of the
#' tolerance measure being calculated.
#'@return The average tolerance score per individual for each unique sampling event.
#'This metric is calculated at the family or genus level. If taxon does not
#'have an assigned tolerance value it will not contribute to the final score. The
#'count representing each taxon is multiplied by the taxon's tolerance value.
#'If the tolerance value is missing it would be treated effectively as a zero,
#'which would reduce the average tolerance score; to avoid this issue, it is
#'more effective to remove the taxa without any tolerance values. However, if a
#'large portion of the sample is composed of a taxon or taxa without
#'assigned tolerance values the final value may be a poor representation
#'of the sample. Every effort should be made to assign each taxon a tolerance value.
#'If you have tolerance values that you would like to contribute and share
#'through the BIBI package please email Zachary M. Smith (zsmith@icprb.org).
#'@export

tol_index <- function(long, master = BIBI::master, tolerance.value = "BIBI_TV", rank = "FAMILY", remove_na = TRUE) {
  long <- long[, c("EVENT_ID", "STATION_ID", "DATE", "AGENCY_CODE",
                   "SAMPLE_NUMBER", rank, "REPORTING_VALUE")]
  
  
  #test <- aggregate(REPORTING_VALUE ~ . , data = long, sum)
  master <- unique(master[, c("FINAL_ID", tolerance.value)])
  test.master <- master[!is.na(master[, tolerance.value]), ]
  test3 <- test.master[duplicated(test.master$FINAL_ID), ]
  if(nrow(test3) > 0) stop("FINAL_ID duplicated for tolerance.value")
  merged <- merge(long, master, by.x = rank, by.y = "FINAL_ID", all.x = TRUE)
  merged$MULT <- merged$REPORTING_VALUE * merged[, tolerance.value]
  merged$E2 <- apply(merged[, c("EVENT_ID", "SAMPLE_NUMBER")], 1, function(x) paste0(x, collapse = "_"))
  
  if(remove_na == TRUE){
    na.check <- by(merged[, tolerance.value], merged$E2, function(x){
      all(is.na(x))
    })
    long.unique <- unique(long[, c("EVENT_ID", "SAMPLE_NUMBER")])
    long.unique <- long.unique[order(long.unique$EVENT_ID, long.unique$SAMPLE_NUMBER),]
    
    all.na <- long.unique[na.check, ]
    
    if(nrow(long.unique[na.check, ]) > 0){

      
      all.na$E2 <- apply(all.na[, c("EVENT_ID", "SAMPLE_NUMBER")], 1, function(x) paste0(x, collapse = "_"))
      
      just.na <- merged[merged$E2 %in% all.na$E2, ]
      just.na <- just.na[, !names(just.na) %in% "E2"]
      just.na$FINAL <- NA
      just.na[, c("MULT", "REPORTING_VALUE")] <- NA
      final.just.na <- unique(just.na[, c("EVENT_ID", "STATION_ID", "DATE",
                                          "AGENCY_CODE","SAMPLE_NUMBER", "MULT", "REPORTING_VALUE", "FINAL")])
    }
    
    if(nrow(merged[!merged$E2 %in% all.na$E2, ]) > 0){
      non.na <- merged[!merged$E2 %in% all.na$E2, ]
      
      
      
      non.na <- non.na[!is.na(non.na$MULT), ]
      
      #non.na <- data.table::as.data.table(non.na)
      
      #agg.mult <- non.na[, sum(MULT), by = list(EVENT_ID, STATION_ID, DATE,
       #                                          AGENCY_CODE, SAMPLE_NUMBER)]
      
      #agg.total <- non.na[, sum(REPORTING_VALUE), by = list(EVENT_ID, STATION_ID, DATE,
      #                                           AGENCY_CODE, SAMPLE_NUMBER)]
      agg.mult <- aggregate(MULT ~ EVENT_ID + STATION_ID + DATE + AGENCY_CODE +
                              SAMPLE_NUMBER, data = non.na, FUN = sum,
                            na.rm = TRUE, na.action = NULL)
      agg.total <- aggregate(REPORTING_VALUE ~ EVENT_ID + STATION_ID + DATE +
                               AGENCY_CODE + SAMPLE_NUMBER, data = non.na, FUN = sum,
                             na.rm = TRUE, na.action = NULL)
      final.non.na <- merge(agg.mult, agg.total, by = c("EVENT_ID", "STATION_ID", "DATE",
                                                        "AGENCY_CODE","SAMPLE_NUMBER"))
      final.non.na <- as.data.frame(final.non.na)
      final.non.na$FINAL <- final.non.na$MULT / final.non.na$REPORTING_VALUE
    }
    
    if(nrow(long.unique[na.check, ]) > 0 & nrow(merged[!merged$E2 %in% all.na$E2, ]) > 0){
      final.df <- rbind(final.non.na, final.just.na)
    }
    if(nrow(long.unique[na.check, ]) > 0 & nrow(merged[!merged$E2 %in% all.na$E2, ]) == 0){
      final.df <- final.just.na
    }
    if(nrow(long.unique[na.check, ]) == 0 & nrow(merged[!merged$E2 %in% all.na$E2, ]) > 0){
      final.df <- final.non.na
    }
    
    
    final.vec <- final.df$FINAL
    
    
  }else{
    agg.mult <- merged[, sum(MULT), by = list(EVENT_ID, STATION_ID, DATE,
                                               AGENCY_CODE, SAMPLE_NUMBER)]
    
    agg.total <- merged[, sum(MULT), by = list(EVENT_ID, STATION_ID, DATE,
                                                 AGENCY_CODE, SAMPLE_NUMBER)]
    #agg.mult <- aggregate(MULT ~ EVENT_ID + STATION_ID + DATE + AGENCY_CODE +
    #                       SAMPLE_NUMBER, data = merged, FUN = sum,
     #                     na.rm = TRUE, na.action = NULL)
    #agg.total <- aggregate(REPORTING_VALUE ~ EVENT_ID + STATION_ID + DATE +
    #                         AGENCY_CODE + SAMPLE_NUMBER, data = merged, FUN = sum,
    #                       na.rm = TRUE, na.action = NULL)
    final.df <- merge(agg.mult, agg.total, by = c("EVENT_ID", "STATION_ID", "DATE",
                                                  "AGENCY_CODE","SAMPLE_NUMBER"))
    final.non.na <- as.data.frame(final.non.na)
    final.df$FINAL <- final.df$MULT / final.df$REPORTING_VALUE
    final.vec <- final.df$FINAL
  }
  
  
  
  return(final.vec)
}


#==============================================================================
#'Tolerance Index for Presence/Absence
#'
#'@param long = Taxonomic counts arrange in a long data format (i.e., each
#'row represents a unique sample and taxon).
#'@param master = A master taxa list including taxonomic ranks Phylum through
#'the specified taxonomic rank (Family or Genus) and the an
#'associated list of tolerance values. The default is set to the master taxa
#'list included in the BIBI package.  The master taxa list can be viewed with
#'the following script: master.df <- BIBI::master
#'@param tolerance.value = The name of the column in the master taxon list
#'(specified using the master variable) that contains tolerance values on
#'a scale of 0-10.
#'@param rank = The taxonomic rank used to perform the analysis. You must
#'sepecify either "FAMILY" or "GENUS" (Defualt = "FAMILY").
#'@return The average tolerance score using only presence/absence data for
#'each unique sampling event. This metric is calculated at the family or
#'genus level. If taxon does not have an assigned tolerance value it will
#'not contribute to the final score. The each taxon is represented by the
#'taxon's tolerance value.  If the tolerance value is
#'missing it would be treated effectively as a zero, which would reduce
#'the average tolerance score; to avoid this issue, it is more effective to remove
#'the taxa without any tolerance values. However, if a large portion of
#'the sample is composed of a taxon or taxa without assigned tolerance
#'values the final value may be a poor representation of the sample.
#'Every effort should be made to assign each taxon a tolerance value.
#'If you have tolerance values that you would like to contribute and share
#'through the BIBI package please email Zachary M. Smith (zsmith@icprb.org).
#'@export

tol_pres_abs <- function(long, rank = "FAMILY", master = BIBI::master, tolerance.value = "BIBI_TV") {
  
  tol_am <- aggregate(master[, tolerance.value] ~ master[, colnames(master) == rank],
                      FUN = mean, na.rm = TRUE)
  colnames(tol_am) <- c(rank, "TOL_VAL")
  
  merge_am1 <- merge(tol_am, long, by.x = rank, by.y = rank, all.y = TRUE)
  
  frame <- unique(merge_am1[, c("EVENT_ID", "STATION_ID")])
  merge_am2 <- merge(frame, merge_am1, by.x = "EVENT_ID",
                     by.y = "EVENT_ID", all.x = TRUE)
  
  merge_am3 <- with(merge_am2, merge_am2[order(EVENT_ID), ])
  merge_am3 <- merge_am3[,c("EVENT_ID", "STATION_ID.x", rank, "TolVal")]
  agg_am <- aggregate(merge_am3$TolVal ~ merge_am3$EVENT_ID +
                        merge_am3$STATION_ID.x + merge_am3[, rank], FUN = mean)
  colnames(agg_am) <- c("EVENT_ID", "STATION_ID", rank, "TOLVAL")
  
  sprd_am <- tidyr::spread(agg_am, rank, TOLVAL)
  sprd_am[, 3:ncol(sprd_am)] <- sprd_am[, 6:ncol(sprd_am)] + 1
  sprd_am[is.na(sprd_am)] <- 0
  
  sum_am <- rowSums(sprd_am[, 6:ncol(sprd_am)])
  rich_am <- rowSums(ifelse(sprd_am[, 6:ncol(sprd_am)] > 0, 1, 0))
  return((sum_am / rich_am) - 1)
}

#==============================================================================
#'Percentage of Intolerant Individuals
#'
#'@param taxa.wide = Taxonomic counts aggregated at the specific taxonomic
#' classification (e.g., Order, Family, or Genus) in a wide data format.
#'  Use the wide function to prepare the data.
#'@param master = A master taxa list including taxonomic ranks Phylum through
#'the specified taxonomic rank (Family or Genus) and the an
#'associated list of tolerance values. The default is set to the master taxa
#'list included in the BIBI package.  The master taxa list can be viewed with
#'the following script: master.df <- BIBI::master
#'@param tolerance.value = The name of the column in the master taxon list
#'(specified using the master variable) that contains tolerance values on
#'a scale of 0-10.
#'@param lower.value = the lower tolerance value bound.
#'@param upper.value = The upper tolerance value bound.
#'@return The percentage of individuals that  fall within the specified
#'tolerance value bounds. Recommendations: Intolerant taxa
#'(lower.value = 0, upper.value = 3), facultative taxa
#'(lower.value = 4, upper.value = 6), and tolerant taxa
#' (lower.value = 7, upper.value = 10).
#'@export

pct_tol_val <- function(taxa.wide, master = BIBI::master, tolerance.value = "BIBI_TV",
                        lower.value = 0, upper.value = 3) {
  master$TOLERANCE <- ifelse(master[, tolerance.value] >= lower.value &
                               master[, tolerance.value] <= upper.value,
                             "TOL_VAL", "EXCLUDE")
  tol <- split(master[, "FINAL_ID"], master$TOLERANCE)
  
  name.list <- list(unique(tol$TOL_VAL))
  group.taxa <- group_taxa(name.list, taxa.wide)
  return((group.taxa / rowSums(taxa.wide[, 6:ncol(taxa.wide)])) * 100)
}

#==============================================================================
#'Richness of Tolerance Group
#'
#'@param taxa.wide = Taxonomic counts aggregated at the specific taxonomic
#' classification (e.g., Order, Family, or Genus) in a wide data format.
#'  Use the wide function to prepare the data.
#'@param master = A master taxa list including taxonomic ranks Phylum through
#'the specified taxonomic rank (Family or Genus) and the an
#'associated list of tolerance values. The default is set to the master taxa
#'list included in the BIBI package.  The master taxa list can be viewed with
#'the following script: master.df <- BIBI::master
#'@param tolerance.value = The name of the column in the master taxon list
#'(specified using the master variable) that contains tolerance values on
#'a scale of 0-10.
#'@param lower.value = the lower tolerance value bound.
#'@param upper.value = The upper tolerance value bound.
#'@return The number of taxa that  fall within the specified
#'tolerance value bounds. Recommendations: Intolerant taxa
#'(lower.value = 0, upper.value = 3), facultative taxa
#'(lower.value = 4, upper.value = 6), and tolerant taxa
#' (lower.value = 7, upper.value = 10).
#'@export

rich_tolerance <- function(taxa.wide, master, tolerance.value = "BIBI_TV",
                           lower.value, upper.value) {
  master$TOLERANCE <- ifelse (master[, tolerance.value] >= lower.value &
                                master[, tolerance.value] <= upper.value,
                              1, 0)
  
  tol <- split(master[, "FINAL_ID"], master$TOLERANCE)
  
  name.list <- list(tol$`1`)
  
  ID <- c("EVENT_ID", "STATION_ID", "DATE", "AGENCY_CODE", "SAMPLE_NUMBER")
  taxa.list <- as.character(unlist(name.list))
  taxa_list.df <- data.frame(taxa.wide[, names(taxa.wide) %in% c(ID, taxa.list)])
  taxa_list.df[is.na(taxa_list.df)] <- 0 #NA = zero
  if(ncol(taxa_list.df) < 6) {
    final.vec <- 0
  } else {
    final.vec <- vegan::specnumber(taxa_list.df[, 6:ncol(taxa_list.df)])
  }
  
  return(final.vec)
}

#==============================================================================
#'***Percentage of Urban Intolerant Individuals***
#'
#'@param long = Taxonomic counts arrange in a long data format (i.e., each
#'row represents a unique sample and taxon).
#'@param master = A master taxa list including taxonomic ranks Phylum through
#'the specified taxonomic rank (Family or Genus) and the an
#'associated list of tolerance values. The default is set to the master taxa
#'list included in the BIBI package.  The master taxa list can be viewed with
#'the following script: master.df <- BIBI::master
#'@return The percentage of indviduals that are classified as urban intolerant
#'by... (Where did this come from? Was in the 2011 BIBI.).  Only available
#'at the family level.
#'@export

pct_urban_intol <- function(long, master) {
  fam.wide <- wide(long, "FAMILY")
  urban <- split(master$FAMILY, master$INTOLERANT_URBAN)
  
  name.list <- list(urban$'1')
  group.taxa <- group_taxa(name.list, fam.wide)
  return((group.taxa / rowSums(fam.wide[, 6:ncol(fam.wide)])) * 100)
}

#==============================================================================
#'Beck's Index
#'
#'@param taxa.wide = Taxonomic counts aggregated at the specific taxonomic
#' classification (e.g., Order, Family, or Genus) in a wide data format.
#'  Use the wide function to prepare the data.
#'@param rank = The taxonomic rank used to perform the analysis. You must
#'sepecify either "FAMILY" or "GENUS" (Defualt = "FAMILY").
#'@param master = A master taxa list including taxonomic ranks Phylum through
#'the specified taxonomic rank (Family or Genus) and the an
#'associated list of tolerance values. The default is set to the master taxa
#'list included in the BIBI package.  The master taxa list can be viewed with
#'the following script: master.df <- BIBI::master
#'@param beck.version = The version of Beck's Index specified as 1 or 3.  The
#'defualt is 1, the orginal Beck's Index:
#'2(S1) + 1(S2) + 3(S3)
#'where:
#'S# = Taxa richness at each level of Beck's classifications (0-3).
#'Beck's Index version 3 is calculated
#'as specified by PADNR:
#'3(S0) + 2(S1) + 1(S2) + 3(S3)
#'where:
#'S# = Taxa richness at each level of Beck's classifications (0-3).
#'@return Beck's Biotic Index produces weighted richness values, which favors
#'organisms sensitive to degradation (Beck Classes 0 and 1).
#'@export

becks <- function(taxa.wide, rank,  master = BIBI::master, beck.version = 1) {
  
  split.beck <- split(master[, rank], master$BECK_CLASS)
  name.list.1 <- list(split.beck$`1`)
  vec.1 <- unlist(unique(name.list.1))
  beck.1 <- taxa.wide[, c(1:5, which(names(taxa.wide) %in% vec.1))]
  if (ncol(beck.1) > 6) {
    rich.beck.1 <- vegan::specnumber(beck.1[, 6:ncol(beck.1)])
  } else {
    if (ncol(beck.1) == 6) {
    rich.beck.1 <- beck.1[, 6]
    } else {
      rich.beck.1 <- rep(0, nrow(beck.1))
    }
  }
  
  
  name.list.2 <- list(split.beck$`2`)
  vec.2 <- unlist(unique(name.list.2))
  beck.2 <- taxa.wide[, c(1:5, which(names(taxa.wide) %in% vec.2))]
  if (ncol(beck.2) > 6) {
    rich.beck.2 <- vegan::specnumber(beck.2[, 6:ncol(beck.2)])
  } else {
    if (ncol(beck.2) == 6) {
      rich.beck.2 <- beck.2[, 6]
    } else {
      rich.beck.2 <- rep(0, nrow(beck.2))
    }
  }
  
  
  if(beck.version == 3){
    name.list.0 <- list(split.beck$`0`)
    vec.0 <- unlist(unique(name.list.0))
    beck.0 <- taxa.wide[, c(1:5, which(names(taxa.wide) %in% vec.0))]
    if(ncol(beck.0) < 6){
      rich.beck.0 <- 0
    }else{
      rich.beck.0 <- vegan::specnumber(beck.0[, 6:ncol(beck.0)])
    }
    
    final.beck <- (3 * rich.beck.0) + (2 * rich.beck.1) + rich.beck.2
  }
  
  if(beck.version == 1) final.beck <- (2 * rich.beck.1) + rich.beck.2
  
  return(final.beck)
}