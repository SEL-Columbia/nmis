######################################################################################################
#Mopup Integration: Merge#############################################################################
######################################################################################################

  #setting working directory (please set to backcheck folder on your machine)
  setwd("~/Code/mop_up/")

  #calling formhub library (installation instructions here: https://github.com/prabhasp/formhub.R)
  library(formhub)

  #reading in relevant data
  lgas <- read.csv("data/input_data/lgas.csv", stringsAsFactors=F)
  
  edu_mopup <- formhubRead("~/Downloads/mopup_questionnaire_education_final_2014_03_25_09_23_03.csv", 
                           "~/Downloads/mopup_questionnaire_education_final.json", 
                           keepGroupName=F, na.strings = c("999", "dk", "n/a"))
  
  health_mopup <- formhubRead("~/Downloads/mopup_questionnaire_health_final_2014_03_25_09_23_06.csv", 
                              "~/Downloads/mopup_questionnaire_health_final.json", 
                              keepGroupName=F, na.strings = c("999", "dk", "n/a"))
  
#   edu_mopup <- formhubDownload("mopup_questionnaire_education_final", uname="ossap", 
#                                pass="", keepGroupName=F, na.strings = c("999"))
   
#   health_mopup <- formhubDownload("mopup_questionnaire_health_final", uname="ossap", 
#                                   pass="", keepGroupName=F, na.strings = c("999"))

#cleaning 
  #adding lga_id and TA information
    edu_mopup <- merge(edu_mopup, lgas[,c("unique_lga", "lga_id", "TA_names")], 
                       by.x = "lga", by.y = "unique_lga")
    
    health_mopup <- merge(health_mopup, lgas[,c("unique_lga", "lga_id", "TA_names")], 
                          by.x = "lga", by.y = "unique_lga")

  #remove UUID, facility ID duplicates
    edu_mopup <- arrange(edu_mopup, desc(end))
    edu_mopup <- edu_mopup[!duplicated(edu_mopup$uuid),]
    edu_mopup$facility_ID <- tolower(edu_mopup$facility_ID)   
    edu_mopup <- edu_mopup[!duplicated(edu_mopup$facility_ID),]
  
    health_mopup <- arrange(health_mopup, desc(end))
    health_mopup <- health_mopup[!duplicated(health_mopup$uuid),]    
    health_mopup$facility_ID <- tolower(health_mopup$facility_ID)   
    health_mopup <- health_mopup[!duplicated(health_mopup$facility_ID),]    
  
  #remove facilities without GPS points at all
    edu_mopup <- edu_mopup[!is.na(edu_mopup$gps),]  
    health_mopup <- health_mopup[!is.na(health_mopup$gps),]

#MERGE!?!?!?!?!?

#writing out
  saveRDS(edu_mopup, "data/in_process_data/education_mopup_merged.RDS")
  saveRDS(health_mopup, "data/in_process_data/health_mopup_merged.RDS")
  
  remove(lgas)
  remove(edu_mopup)
  remove(health_mopup)
  
  
  
  
