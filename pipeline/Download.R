source("CONFIG.R"); require(formhub)

### DOWNLOAD AND .RDS our data. TODO: formhubDownload incorporate a cache
surveys = list('mopup_questionnaire_education_final', 'mopup_questionnaire_health_final',
               'education_mopup_new', 'education_mopup', 'health_mopup', 'health_mopup_new')
l_ply(surveys, function(survey) {
    print(survey)
    fData = formhubDownload(survey, 'ossap', authfile=CONFIG$AUTHFILE, 
                keepGroupNames=F, na.strings=c("999", "9999", "n/a"))
    saveRDS(fData, sprintf("%s/%s.RDS", CONFIG$MOPUP_DATA_DIR, survey))
})
