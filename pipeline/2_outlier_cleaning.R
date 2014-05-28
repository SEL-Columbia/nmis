######################################################################################################
#Mopup Integration: Outlier Cleaning##################################################################
######################################################################################################
require(dplyr)
source('nmis_functions.R')

education_outlier <- function(education_data) {
    return(education_data %.% 
        dplyr::mutate(
            num_tchrs_male = replace(num_tchrs_male, num_tchrs_male > num_tchrs_total, NA),
            num_tchrs_female = replace(num_tchrs_female, num_tchrs_female > num_tchrs_total, NA),
            num_tchrs_with_nce = replace(num_tchrs_with_nce, num_tchrs_with_nce > num_tchrs_total, NA),
            num_classrms_repair = replace(num_classrms_repair, num_classrms_repair > num_classrms_total, NA),
            num_tchrs_total = replace(num_tchrs_total, num_tchrs_total > (num_tchrs_male + num_tchrs_female), NA)
        ) %.% 
        dplyr::mutate(
            num_tchrs_male = replace(num_tchrs_male, num_tchrs_male > 100, NA),
            num_tchrs_female = replace(num_tchrs_female, num_tchrs_female > 100, NA),
            num_tchrs_with_nce = replace(num_tchrs_with_nce, num_tchrs_with_nce > 100, NA),
            num_classrms_repair = replace(num_classrms_repair, num_classrms_repair > 50, NA),
            num_students_total = replace(num_students_total, num_students_total > 2355, NA)
        )
    )
}

health_outlier <- function(health_data) {
    hospital_outlier_replaced <- health_data %.%
        dplyr::filter(
            facility_type %in% c("teaching_hospital", "district_hospital")
        ) %.% 
        dplyr::mutate(
            num_doctors_fulltime = replace(num_doctors_fulltime, num_doctors_fulltime > 12, NA), 
            num_nurses_fulltime = replace(num_nurses_fulltime, num_nurses_fulltime > 24, NA),
            num_midwives_fulltime = replace(num_midwives_fulltime, num_midwives_fulltime > 24, NA),
            facility_type = replace(facility_type,
                between(num_doctors_fulltime, 0, 30) & 
                between(num_nurses_fulltime, 0, 30) &
                between(num_midwives_fulltime, 0, 30), NA),
            num_doctors_fulltime = replace(num_doctors_fulltime,
                outside(num_doctors_fulltime, 100, 500), NA),
            num_nurses_fulltime = replace(num_nurses_fulltime,
                num_nurses_fulltime < 100, NA),
            num_midwives_fulltime = replace(num_midwives_fulltime,
                num_midwives_fulltime < 100, NA),
            num_chews_fulltime = replace(num_chews_fulltime,
                num_chews_fulltime > 50, NA)
        )
    non_hospital_outlier_replaced = health_data %.% 
        dplyr::filter(
            !(facility_type %in% c("teaching_hospital", "district_hospital"))
        ) %.% 
        dplyr::mutate(
            num_doctors_fulltime = replace(num_doctors_fulltime, num_doctors_fulltime > 20, NA),
            num_nurses_fulltime = replace(num_nurses_fulltime, num_nurses_fulltime > 16, NA),
            num_midwives_fulltime = replace(num_midwives_fulltime, num_midwives_fulltime > 16, NA),
            num_nurses_fulltime = replace(num_nurses_fulltime, num_nurses_fulltime >16, NA),
            num_midwives_fulltime = replace(num_midwives_fulltime, num_midwives_fulltime >16, NA),
            num_chews_fulltime = replace(num_chews_fulltime, num_chews_fulltime > 50, NA)
        )
    return(rbind(hospital_outlier_replaced, non_hospital_outlier_replaced))
}

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
