######################################################################################################
#Mopup Integration: Outlier Cleaning##################################################################
######################################################################################################
require(dplyr)
education_outlier <- function(education_data) {
    return(education_data %.% mutate(
        replace(num_tchrs_male, num_tchrs_male > num_tchrs_total, NA),
        replace(num_tchrs_female, num_tchrs_female > num_tchrs_total, NA),
        replace(num_tchrs_with_nce, num_tchrs_with_nce > num_tchrs_total, NA),
        replace(num_classrms_repair, num_classrms_repair > num_classrms_total, NA),
        replace(num_tchrs_total, num_tchrs_total > (num_tchrs_male + num_tchrs_female), NA)
    ) %.% mutate(
        replace(num_tchrs_male, num_tchrs_male > 100, NA),
        replace(num_tchrs_female, num_tchrs_female > 100, NA),
        replace(num_tchrs_with_nce, num_tchrs_with_nce > 100, NA),
        replace(num_classrms_repair, num_classrms_repair > 50, NA),
        replace(num_students_total, num_students_total > 2355, NA)
    ))
}

health_outlier <- function(health_data) {
    return(health_outlier %.% mutate(


# #health###############################################################################################
# 
# #outliers
# #   health_merged <-outlierreplace(health_merged, 'num_doctors_fulltime',
# #                                      (health_merged$num_doctors_fulltime > 12 & 
# #                                         (health_merged$facility_type != "teaching_hospital" & 
# #                                            health_merged$facility_type != "district_hospital")))
        replace(num_doctors_fulltime, num_doctors_fulltime > 12 & 
            facility_type != ("teaching_hospital" | "district_hospital"), 
            NA)
# 
# #   health_merged <- outlierreplace(health_merged, 'num_doctors_fulltime',
# #                                       (health_merged$num_doctors_fulltime > 20 & 
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
# 
        replace(num_doctors_fulltime, num_doctors_fulltime > 20 &
            facility_type == ("teaching_hospital" | "district_hospital"),
            NA)
# #   health_merged <- outlierreplace(health_merged, 'num_nurses_fulltime',
# #                                       (health_merged$num_nurses_fulltime > 16 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))
# 
        replace(num_nurses_fulltime, num_nurses_fulltime > 16 &
            facility_type != ("teaching_hospital" | "district_hospital"),
            NA)
# #   health_merged <- outlierreplace(health_merged, 'num_nurses_fulltime',
# #                                       (health_merged$num_nurses_fulltime > 24 & 
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "federalmedicalcentre")))
# 
        replace(num_nurses_fulltime, num_nurses_fulltime > 24 &
            facility_type == ("teaching_hospital" | "federalmedicalcentre"),
            NA)
#   health_merged <- outlierreplace(health_merged, 'num_midwives_fulltime',
#                                       (health_merged$num_midwives_fulltime > 24 & 
#                                          (health_merged$facility_type == "teaching_hospital" | 
#                                             health_merged$facility_type == "district_hospital")))
        replace(num_midwives_fulltime, num_midwives_fulltime > 24 &
            facility_type == ("teaching_hospital" | "district_hospital"),
            NA)
# 
# #   health_merged <- outlierreplace(health_merged, 'num_midwives_fulltime',
# #                                       (health_merged$num_midwives_fulltime > 16 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))
        replace(num_midwives_fulltime, num_midwives_fulltime > 16 &
                facility_type != ("teaching_hospital" | "district_hospital"),
                NA)
# 
# #   health_merged <- outlierreplace(health_merged, 'facility_type',
# #                                       (((health_merged$num_doctors_fulltime < 30 & 
# #                                            health_merged$num_doctors_fulltime != 0) & 
# #                                           (health_merged$num_midwives_fulltime < 30 & 
# #                                              health_merged$num_midwives_fulltime != 0) &
# #                                           (health_merged$num_nurses_fulltime < 30 & 
# #                                              health_merged$num_nurses_fulltime != 0)) &
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_doctors_fulltime',
# #                                       ((health_merged$num_doctors_fulltime > 500 | 
# #                                           health_merged$num_doctors_fulltime < 100) & 
# #                                          (health_merged$facility_type == "teaching_hospital"  |
# #                                             health_merged$facility_type == "district_hospital")
# #                                       ))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_nurses_fulltime',
# #                                       (health_merged$num_nurses_fulltime < 100 &
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_nurses_fulltime',
# #                                       (health_merged$num_nurses_fulltime > 16 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))            
# 
# #   health_merged <- outlierreplace(health_merged, 'num_midwives_fulltime',
# #                                       (health_merged$num_midwives_fulltime < 100 & 
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
# 
#   
# #   health_merged <- outlierreplace(health_merged, 'num_midwives_fulltime',
# #                                       (health_merged$num_midwives_fulltime > 16 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_chews_fulltime',
# #                                       (health_merged$num_chews_fulltime > 50 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_chews_fulltime',
# #                                       (health_merged$num_chews_fulltime > 50 &
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
    ))
}

# #calling source script
#   source('nmis_functions.R')
#   library(stats)
#   source('CONFIG.R')
# 
# #reading in data
#   edu_merged <- readRDS("data/in_process_data/education_mopup_merged.RDS")
#   health_merged <- readRDS("data/in_process_data/health_mopup_merged.RDS")
# 
# #education############################################################################################
# 
# #logic checks
#   edu_merged <- outlierreplace(edu_merged, 'num_tchrs_male', 
#                                    (edu_merged$num_tchrs_male > edu_merged$num_tchrs_total))
# 
#   edu_merged <- outlierreplace(edu_merged, 'num_tchrs_female', 
#                                    (edu_merged$num_tchrs_female > edu_merged$num_tchrs_total))
# 
#   edu_merged <- outlierreplace(edu_merged, 'num_tchrs_with_nce',
#                                    (edu_merged$num_tchrs_with_nce > edu_merged$num_tchrs_total))
# 
#   edu_merged <- outlierreplace(edu_merged, 'num_classrms_repair', 
#                                    edu_merged$num_classrms_repair > edu_merged$num_classrms_total) 
# 
#   edu_merged <- outlierreplace(edu_merged, 'num_tchrs_total',
#                                    (edu_merged$num_tchrs_total > edu_merged$num_tchrs_male + 
#                                       edu_merged$num_tchrs_female))
# #outliers
#   edu_merged <- outlierreplace(edu_merged, 'num_students_total', 
#                                    edu_merged$num_students_total == 0)    
# 
#   edu_merged <- outlierreplace(edu_merged, 'num_tchrs_total',
#                                    (edu_merged$num_tchrs_total > 20 & 
#                                       edu_merged$num_students_total == 0))
# 
#   edu_merged <- outlierreplace(edu_merged, 'num_students_female',
#                                    (edu_merged$num_students_female > 3000))
# 
#   edu_merged <- outlierreplace(edu_merged, 'num_students_male',
#                                    (edu_merged$num_students_male > 2500 &
#                                       edu_merged$num_classrms_total < 25))
# 
#   edu_merged <- outlierreplace(edu_merged, 'num_students_total',
#                                    (edu_merged$num_students_total > 2000 & 
#                                       edu_merged$num_classrms_total < 25 &
#                                       edu_merged$num_tchrs_total < 10))
# 
#   edu_merged <- outlierreplace(edu_merged, 'num_classrms_total',
#                                    (edu_merged$num_classrms_total == 0))
# 
# #further inspection/determining of cut off
# 
# #   edu_merged <- outlierreplace(edu_merged, 'num_tchrs_male',
# #                                    (edu_merged$num_tchrs_male > 100))
# 
# #   edu_merged <- outlierreplace(edu_merged, 'num_tchrs_female',
# #                                    (edu_merged$num_tchrs_female > 100))
# 
# #   edu_merged <- outlierreplace(edu_merged, 'num_tchrs_with_nce',
# #                                    (edu_merged$num_tchrs_with_nce > 100))
# 
# #   edu_merged <- outlierreplace(edu_merged, 'num_classrms_repair',
# #                                    (edu_merged$num_classrms_repair > 50))
# 
# #   edu_merged <- outlierreplace(edu_merged, 'num_students_total',
# #                                    edu_merged$num_students_total > 2355)
# 
# #   edu_merged <- outlierreplace(edu_merged, 'num_toilets_total',
# #
# #   edu_merged <- outlierreplace(edu_merged, 'num_classrms_total',
# #
# #   edu_merged <- outlierreplace(edu_merged, 'num_classrm_w_chalkboard',
# #
# #   edu_merged <- outlierreplace(edu_merged, 'num_classrms_repair',
# 
# #ratios
#   edu_merged$ratio_students_to_toilet <- replace(edu_merged$num_students_total, 
#                                                      is.na(edu_merged$num_students_total), 0) /
#                                               replace(edu_merged$num_toilets_total, 
#                                                       is.na(edu_merged$num_toilets_total), 0) 
# 
#   edu_merged$ratio_students_to_toilet <- ifelse(edu_merged$ratio_students_to_toilet == 0, NA, 
#                                                     edu_merged$ratio_students_to_toilet)
# 
#   edu_merged$pupil_class_ratio <- edu_merged$num_students_total/
#                                       edu_merged$num_classrms_total
# 
# #   edu_merged <- outlierreplace(edu_merged, 'num_students_total', 
# #                    (edu_merged$pupil_class_ratio < 5 | edu_merged$pupil_class_ratio > 150))
# # 
# #   edu_merged <- outlierreplace(edu_merged, 'num_classrms_total', 
# #                   (edu_merged$pupil_class_ratio < 5 | edu_merged$pupil_class_ratio > 150))
# 
#   edu_merged <- outlierreplace(edu_merged, 'ratio_students_to_toilet',
#                                    between(edu_merged$ratio_students_to_toilet, 1000, Inf))   
# 
# #writing out
#   saveRDS(edu_merged, "data/in_process_data/education_mopup_outliercleaned.rds")
# 
# #health###############################################################################################
# 
# #outliers
# #   health_merged <-outlierreplace(health_merged, 'num_doctors_fulltime',
# #                                      (health_merged$num_doctors_fulltime > 12 & 
# #                                         (health_merged$facility_type != "teaching_hospital" & 
# #                                            health_merged$facility_type != "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_doctors_fulltime',
# #                                       (health_merged$num_doctors_fulltime > 20 & 
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_nurses_fulltime',
# #                                       (health_merged$num_nurses_fulltime > 16 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_nurses_fulltime',
# #                                       (health_merged$num_nurses_fulltime > 24 & 
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "federalmedicalcentre")))
# 
#   health_merged <- outlierreplace(health_merged, 'num_midwives_fulltime',
#                                       (health_merged$num_midwives_fulltime > 24 & 
#                                          (health_merged$facility_type == "teaching_hospital" | 
#                                             health_merged$facility_type == "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_midwives_fulltime',
# #                                       (health_merged$num_midwives_fulltime > 16 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'facility_type',
# #                                       (((health_merged$num_doctors_fulltime < 30 & 
# #                                            health_merged$num_doctors_fulltime != 0) & 
# #                                           (health_merged$num_midwives_fulltime < 30 & 
# #                                              health_merged$num_midwives_fulltime != 0) &
# #                                           (health_merged$num_nurses_fulltime < 30 & 
# #                                              health_merged$num_nurses_fulltime != 0)) &
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_doctors_fulltime',
# #                                       ((health_merged$num_doctors_fulltime > 500 | 
# #                                           health_merged$num_doctors_fulltime < 100) & 
# #                                          (health_merged$facility_type == "teaching_hospital"  |
# #                                             health_merged$facility_type == "district_hospital")
# #                                       ))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_nurses_fulltime',
# #                                       (health_merged$num_nurses_fulltime < 100 &
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_nurses_fulltime',
# #                                       (health_merged$num_nurses_fulltime > 16 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))            
# 
# #   health_merged <- outlierreplace(health_merged, 'num_midwives_fulltime',
# #                                       (health_merged$num_midwives_fulltime < 100 & 
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
# 
#   
# #   health_merged <- outlierreplace(health_merged, 'num_midwives_fulltime',
# #                                       (health_merged$num_midwives_fulltime > 16 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_chews_fulltime',
# #                                       (health_merged$num_chews_fulltime > 50 & 
# #                                          (health_merged$facility_type != "teaching_hospital" & 
# #                                             health_merged$facility_type != "district_hospital")))
# 
# #   health_merged <- outlierreplace(health_merged, 'num_chews_fulltime',
# #                                       (health_merged$num_chews_fulltime > 50 &
# #                                          (health_merged$facility_type == "teaching_hospital" | 
# #                                             health_merged$facility_type == "district_hospital")))
# 
# #further inspection/determining of cut off
# #   health_merged <- outlierreplace(health_merged, 'num_toilets_total',
#                                   
# 
# #writing out
#   saveRDS(health_merged, "data/in_process_data/health_mopup_outliercleaned.rds")
# 
# # library(ggplot2)
# # cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
# # ggplot(edu_merged, aes(x=zone, y=num_tchrs_male, fill=zone)) +
# #   coord_flip() + geom_boxplot() + ylab('Number of Male Teachers') + xlab('Zone') + 
# #   scale_fill_manual(values=cbPalette) #+ scale_y_continuous(limits=c(0,3000))
# #
# # quantile(health_merged$num_chews_fulltime, na.rm=T, 0.999)
# 
# 
#   remove(between)
#   remove(outlierreplace)
#   remove(edu_merged)
#   remove(health_merged)
# 
# 
