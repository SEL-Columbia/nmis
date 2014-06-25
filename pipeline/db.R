require(dplyr)
require(RSQLite)
source('nmis_functions.R')
create_db <- function(db_connection) {
    dbSendQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS facility_tb(
                    facility_id VARCHAR(5) PRIMARY KEY);")
                
    dbSendQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS survey_tb(
                            survey_id VARCHAR(36) UNIQUE NOT NULL,
                            survey_time INTEGER,
                            facility_id VARCHAR(5) NOT NULL,
                            FOREIGN KEY(facility_id) REFERENCES facility_tb(facility_id));")
}

insert_facility <- function(conn, facility_id=NULL){
    facility_id = ifelse(is.null(facility_id), gen_facility_id(), facility_id)
    facility_query <- sprintf("INSERT INTO facility_tb
                        VALUES ('%s')", facility_id)
    dbSendQuery(conn = conn, facility_query)
    return(facility_id)
}

insert_facility_db = function(conn, max_try=10000){
    if (max_try == 0){
        stop("Too many collisions, consider expanding to one extra digit")
    }
    tryCatch(return(insert_facility(conn)), 
             error = function(e){
                    max_try = max_try - 1;
                    insert_facility_db(conn, max_try);
                    })
}

## insert_survey
insert_survey <- function(conn, survey_id, submission_time, facility_id){
    survey_query <- sprintf("INSERT INTO survey_tb
                        VALUES ('%s', %i, '%s')", survey_id,
                                                  get_epoch(submission_time),
                                                  facility_id)
    tryCatch({dbSendQuery(conn, survey_query)
                return(survey_id)
             },
             error = function(e){
                 message(paste("Error! ", e))
                 return(NA)
             })
}


## 
pull_survey_id <- function(conn) {
    df <- dbGetQuery(conn, "SELECT survey_id from survey_tb")
    return(df$survey_id)
}
get_facility_id_from_survey <- function(conn, survey_id) {
    res <- dbGetQuery(conn, sprintf("SELECT facility_id from survey_tb WHERE survey_id = '%s'", survey_id))
    return(res$facility_id[1])
}


check_exist_survey <- function(conn, survey_id) {
    return(survey_id %in% survey_list)
}

check_exist_survey_from_db <- function(conn, survey_id) {
    res <- dbGetQuery(conn, sprintf("SELECT survey_id from survey_tb WHERE survey_id = '%s'", survey_id))
    return(ifelse(length(res$survey_id)==0, FALSE, TRUE))
}

#check_facility_id <- function(facility_id){
#    if (!is.null(facility_id)){
#        if(!is.na(facility_id)){
#            return(TRUE)
#        }
#    }
#    return(FALSE)
#}
check_facility_id <- function(facility_id){

    return(ifelse(!lapply(facility_id, is.null),
                  ifelse(!is.na(facility_id), TRUE, FALSE),
                  FALSE))
}



get_facility_id <- function(conn, facility_id) {
    res <- dbGetQuery(conn, sprintf("SELECT facility_id from facility_tb
                                         WHERE facility_id = '%s'", facility_id))
    return(ifelse(length(res$facility_id) == 0, FALSE, TRUE))
}

sync_row <- function(conn, survey_id, facility_id, submission_time){
    if (!check_exist_survey_from_db(conn, survey_id)){
        if (check_facility_id(facility_id)){
            #do something
            if(get_facility_id(conn, facility_id)){
                insert_survey(conn, 
                              survey_id, 
                              submission_time, 
                              facility_id)
            } else {
                # do something
                facility_id <- insert_facility(conn, facility_id=facility_id)
                insert_survey(conn,
                              survey_id, 
                              submission_time, 
                              facility_id)
            }
        }else {
            facility_id <- insert_facility_db(conn)
            insert_survey(conn,
                          survey_id, 
                          submission_time, 
                          facility_id)
        }
        return(facility_id)
    
    }else{
        facility_id <- get_facility_id_from_survey(conn, survey_id)
        return(facility_id)
    }
}

sync_db <- function(df){
    db_path = "./data/sqlite_db/facility_registry.db"
    if( ! file.exists(db_path)){
        my_db <- dplyr::src_sqlite(db_path, create = TRUE)    
        rm(my_db)
    }
    database <- dbConnect(SQLite(), dbname=db_path)
    create_db(database)
    ### evil for loop
#    for (i in 1:nrow(df)) {
#        sync_row(database, df[i,])
#    }
    ###
    df <- df %.% mutate(facility_id = sync_row(database, 
                                               survey_id,
                                               facility_id,
                                               submission_time))

    dbDisconnect(database)
    return(df)
}
