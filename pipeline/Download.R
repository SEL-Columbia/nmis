source("CONFIG.R"); require(formhub)

### DOWNLOAD AND .RDS our data. TODO: formhubDownload incorporate a cache
surveys = list('mopup_questionnaire_education_final', 'mopup_questionnaire_health_final',
               'education_mopup_new', 'education_mopup', 'health_mopup', 'health_mopup_new')
l_ply(surveys, function(survey) {
    print(survey)
    saveRDS(formhubDownload(survey, 'ossap', authfile='authfile', keepGroupNames=F),
            sprintf("data/%s.RDS", survey))
})
