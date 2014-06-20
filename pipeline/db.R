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

insert_facility <- function(conn, survey=NULL){
    facility_id = ifelse(is.null(survey), gen_uid(), survey$uid)
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
    tryCatch(dbSendQuery(conn, survey_query),
             error = function(e){print(e)})
}


## 
pull_survey_id <- function(conn) {
    df <- dbGetQuery(conn, "SELECT survey_id from survey_tb")
    return(df$survey_id)
}


check_exist_survey <- function(conn, survey) {
    return(survey$uuid %in% survey_list)
}

check_exist_survey_from_db <- function(conn, survey) {
    res <- dbGetQuery(conn, sprintf("SELECT survey_id from survey_tb WHERE survey_id = '%s'", survey$uuid))
    return(ifelse(length(res$survey_id)==0, FALSE, TRUE))
}

check_facility_id <- function(survey){
    if (!is.null(survey$uid)){
        if(!is.na(survey$uid)){
            return(TRUE)
        }
    }
    return(FALSE)
}

get_facility_id <- function(conn, facility_id) {
    res <- dbGetQuery(conn, sprintf("SELECT facility_id from facility_tb
                                         WHERE facility_id = '%s'", facility_id))
    return(ifelse(length(res$facility_id) == 0, FALSE, TRUE))
}

sync_row <- function(conn, survey){
    if (!check_exist_survey_from_db(conn, survey)){
        if (check_facility_id(survey)){
            #do something
            if(get_facility_id(conn, survey$uid)){
                insert_survey(conn, 
                              survey$uuid, 
                              survey$submission_time, 
                              survey$uid)
            } else {
                # do something
                facility_id <- insert_facility(conn, survey=survey)
                insert_survey(conn,
                              survey$uuid, 
                              survey$submission_time, 
                              facility_id)
            }
        }else {
            facility_id <- insert_facility_db(conn)
            insert_survey(conn,
                          survey$uuid, 
                          survey$submission_time, 
                          facility_id)
        }
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
    for (i in 1:nrow(df)) {
        sync_row(database, df[i,])
    }
    id_df <- dbGetQuery(database, 
                        "SELECT facility_id, survey_id FROM survey_tb")
    df$uid <- NULL
    df <- merge(df, id_df, by.x="uuid", by.y="survey_id", all.x=TRUE)
    df <- rename(df, c("facility_id" = "uid"))
    dbDisconnect(database)
    return(df)
}
