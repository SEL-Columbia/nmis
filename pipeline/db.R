require(dplyr)
require(RSQLite)
source('nmis_functions.R')

db_path = "./data/sqlite_db/facility_registry.db"
if( ! file.exists(db_path)){
    my_db <- dplyr::src_sqlite(db_path, create = TRUE)    
}
my_db_conn <- dbConnect(SQLite(), dbname=db_path)

# dbDisconnect(SQLite(), conn = db)

create_db <- function(db_connection) {
    dbSendQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS facility_tb(
                    uid VARCHAR(5) PRIMARY KEY);")
                
    dbSendQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS survey_tb(
                            uuid VARCHAR(36) UNIQUE NOT NULL,
                            survey_time INTEGER,
                            uid VARCHAR(5) NOT NULL,
                            FOREIGN KEY(uid) REFERENCES facility_tb(uid));")
}

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
insert_facility <- function(conn, gen_id=T){
    if(gen_id){
        facility_id <-gen_uid()
    }
    facility_query <- sprintf("INSERT INTO facility_tb
                        VALUES ('%s')", facility_id)
    dbSendQuery(conn = conn, facility_query)
    return(facility_id)
}

insert_facility_db = function(conn, max_try=10000, gen_id=T){
    if (max_try == 0){
        stop("Too many collisions, consider expanding to one extra digit")
    }
    tryCatch(return(insert_facility(conn, gen_id=gen_id)), 
             error = function(e){
                    max_try = max_try - 1;
                    insert_facility_db(conn, max_try);
                    })
}


## insert_survey
insert_survey <- function(conn, survey_entry){
    #survey_entry is c(uuid, t, uid)
    survey_query <- sprintf("INSERT INTO survey_tb
                        VALUES ('%s', %i, '%s')", survey_entry["uuid"],
                                                  survey_entry["survey_time"],
                                                  survey_entry["uid"])
    tryCatch(dbSendQuery(conn, survey_entry),
             error = function(e){print("error!", e)})
}


## 
pull_survey_id <- function(conn) {
    df <- dbGetQuery(conn, "SELECT survey_id from survey_tb")
    return(df$survey_id)
}


check_exist_survey <- function(survey, survey_list) {
    return(survey$uuid %in% survey_list)
}

check_facility_id <- function(survey){
    return(!is.na(survey$uid) | !is.null(survey$uid))
}

get_facility_id <- function(conn, facility_id) {
}
