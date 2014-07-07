require(dplyr)
require(RSQLite)
source('nmis_functions.R')
<<<<<<< HEAD

db_path = "./data/sqlite_db/facility_registry.db"
if( ! file.exists(db_path)){
    my_db <- dplyr::src_sqlite(db_path, create = TRUE)    
}
my_db_conn <- dbConnect(SQLite(), dbname=db_path)

# dbDisconnect(SQLite(), conn = db)

create_db <- function(db_connection) {
    dbSendQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS facility_tb(
                    facility_id VARCHAR(5) PRIMARY KEY);")
                
    dbSendQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS survey_tb(
=======
create_db <- function(db_connection) {
    dbGetQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS facility_tb(
                    facility_id VARCHAR(5) PRIMARY KEY);")
                
    dbGetQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS survey_tb(
>>>>>>> 0ca0c043f9dd315f54577d59ae34193d45fbc6fb
                            survey_id VARCHAR(36) UNIQUE NOT NULL,
                            survey_time INTEGER,
                            facility_id VARCHAR(5) NOT NULL,
                            FOREIGN KEY(facility_id) REFERENCES facility_tb(facility_id));")
}

<<<<<<< HEAD
create_db(my_db_conn)


#dbSendQuery(conn = my_db_conn,
#            "INSERT INTO survey_tb
#            VALUES ('d78a3185-5a01-429a-83fd-c6f16e23155a', 41234841, 'TLCP')")
#
# what do we want to do here
# insert UID into faciliti_tb and if it fails try agiain util
# it reaches limit of trial or it succeed
# for mopup, uid exists, we just need to insert it

## insert_facility_db
## if in scenario 1: uid = gen_uid()
## if in scenario 2: uid = survey$uid
insert_facility <- function(conn, survey=NULL){
    facility_id = ifelse(is.null(survey), gen_uid(), survey$uid)
    facility_query <- sprintf("INSERT INTO facility_tb
                        VALUES ('%s')", facility_id)
    dbSendQuery(conn = conn, facility_query)
=======
insert_facility <- function(conn, survey=NULL){
    facility_id = ifelse(is.null(survey), gen_facility_id(), survey['facility_id'])
    facility_query <- sprintf("INSERT INTO facility_tb
                        VALUES ('%s')", facility_id)
    dbGetQuery(conn = conn, facility_query)
>>>>>>> 0ca0c043f9dd315f54577d59ae34193d45fbc6fb
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
<<<<<<< HEAD
insert_survey <- function(conn, survey_entry){
    #survey_entry is c(uuid, t, uid)
    survey_query <- sprintf("INSERT INTO survey_tb
                        VALUES ('%s', %i, '%s')", survey_entry["uuid"],
                                                  survey_entry["survey_time"],
                                                  survey_entry["uid"])
    tryCatch(dbSendQuery(conn, survey_entry),
             error = function(e){print("error!", e)})
=======
insert_survey <- function(conn, survey_id, submission_time, facility_id){
    survey_query <- sprintf("INSERT INTO survey_tb
                        VALUES ('%s', %i, '%s')", survey_id,
                                                  get_epoch(submission_time),
                                                  facility_id)
    tryCatch(dbGetQuery(conn, survey_query),
             error = function(e){print(e)})
>>>>>>> 0ca0c043f9dd315f54577d59ae34193d45fbc6fb
}


## 
pull_survey_id <- function(conn) {
    df <- dbGetQuery(conn, "SELECT survey_id from survey_tb")
<<<<<<< HEAD
    return(df$survey_id)
}


check_exist_survey <- function(survey, survey_list) {
    return(survey$uuid %in% survey_list)
}

check_facility_id <- function(survey){
    return(!is.na(survey$uid) | !is.null(survey$uid))
=======
    return(df['survey_id'])
}


check_exist_survey <- function(conn, survey) {
    return(survey['survey_id'] %in% survey_list)
}

check_exist_survey_from_db <- function(conn, survey) {
    res <- dbGetQuery(conn, sprintf("SELECT survey_id from survey_tb WHERE survey_id = '%s'", survey['survey_id']))
    return(ifelse(nrow(res['survey_id'])==0, FALSE, TRUE))
}

check_facility_id <- function(survey){
    if (!is.null(survey['facility_id'])){
        if(!is.na(survey['facility_id'])){
            return(TRUE)
        }
    }
    return(FALSE)
>>>>>>> 0ca0c043f9dd315f54577d59ae34193d45fbc6fb
}

get_facility_id <- function(conn, facility_id) {
    res <- dbGetQuery(conn, sprintf("SELECT facility_id from facility_tb
                                         WHERE facility_id = '%s'", facility_id))
<<<<<<< HEAD
    return(ifelse(length(res$facility_id) == 0, FALSE, TRUE))
}


=======
    return(ifelse(nrow(res['facility_id']) == 0, FALSE, TRUE))
}

sync_row <- function(conn, survey){

    if (!check_exist_survey_from_db(conn, survey)){
        if (check_facility_id(survey)){
            #do something
            if(get_facility_id(conn, survey['facility_id'])){
                insert_survey(conn, 
                              survey['survey_id'], 
                              survey['submission_time'], 
                              survey['facility_id'])
            } else {
                # do something
                facility_id <- insert_facility(conn, survey=survey)
                insert_survey(conn,
                              survey['survey_id'], 
                              survey['submission_time'], 
                              facility_id)
            }
        }else {
            facility_id <- insert_facility_db(conn)
            insert_survey(conn,
                          survey['survey_id'], 
                          survey['submission_time'], 
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
        
    survey_df <- dplyr::src_sqlite(db_path, create = FALSE) %.%
                 dplyr::tbl('survey_tb') %.% collect()
    db_candidate <- dplyr::anti_join(df, survey_df, by='survey_id')
    rm(survey_df)
    if(nrow(db_candidate) != 0) {
        apply(db_candidate, 1, function(x){sync_row(database, x)})
    }
    dbDisconnect(database)
    #note this survey_df is the more complete data than above
    survey_df <- dplyr::src_sqlite(db_path, create = FALSE) %.%
                 dplyr::tbl('survey_tb') %.% collect()
    df <- df %.% dplyr::select(-facility_id, matches('.'))
    df <- dplyr::inner_join(df, survey_df, by="survey_id")
    
    return(df)
}
>>>>>>> 0ca0c043f9dd315f54577d59ae34193d45fbc6fb
