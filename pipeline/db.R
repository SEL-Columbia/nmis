require(dplyr)
require(RSQLite)
source('nmis_functions.R')
create_db <- function(){
    db_path = "data/sqlite_db/facility_registry.db"
    db_connection <- dbConnect(SQLite(), dbname=db_path)
    
    
    dbSendQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS facility_tb(
                    facility_id VARCHAR(5) PRIMARY KEY);")
                
    dbSendQuery(conn = db_connection, "CREATE TABLE IF NOT EXISTS survey_tb(
                            survey_id VARCHAR(36) UNIQUE NOT NULL,
                            survey_time INTEGER,
                            facility_id VARCHAR(5) NOT NULL,
                            FOREIGN KEY(facility_id) REFERENCES facility_tb(facility_id));")
    
    # load all mopup todo survey_ids
    mopup_todo <- read.csv("data/mopup_do_ids.csv")
    sql <- "INSERT INTO facility_tb VALUES (@facility_id)"
    dbBeginTransaction(db_connection)
    dbGetPreparedQuery(db_connection, sql, bind.data = mopup_todo)
    dbCommit(db_connection)
    init_rec_count <- dbGetQuery(db_connection, "select count(*) from facility_tb")[[1]]
    
    print(paste(init_rec_count, "mopup facility was initialized", sep = " "))
    dbDisconnect(db_connection)
}

insert_facility <- function(conn, survey=NULL){
    facility_id = ifelse(is.null(survey), gen_facility_id(), survey['facility_id'])
    facility_query <- sprintf("INSERT INTO facility_tb
                        VALUES ('%s')", facility_id)
    dbGetQuery(conn = conn, facility_query)
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
    tryCatch(dbGetQuery(conn, survey_query),
             error = function(e){print(e)})
}


## 
pull_survey_id <- function(conn) {
    df <- dbGetQuery(conn, "SELECT survey_id from survey_tb")
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
}

get_facility_id <- function(conn, facility_id) {
    res <- dbGetQuery(conn, sprintf("SELECT facility_id from facility_tb
                                         WHERE facility_id = '%s'", facility_id))
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
    db_path = "data/sqlite_db/facility_registry.db"
    if( ! file.exists(db_path)){
        my_db <- dplyr::src_sqlite(db_path, create = TRUE)    
        rm(my_db)
        create_db()
    }

    database <- dbConnect(SQLite(), dbname=db_path)
            
    survey_df <- dplyr::src_sqlite(db_path, create = FALSE) %.%
                 dplyr::tbl('survey_tb') %.% collect()
    db_candidate <- dplyr::anti_join(df, survey_df, by='survey_id')
    rm(survey_df)
    if(nrow(db_candidate) != 0) {
        apply(db_candidate, 1, function(x){sync_row(database, x)})
    }
    dbDisconnect(database)
    #note this survey_df is the more complete data than above
    # pull all existing surveys from db
    survey_df <- dplyr::src_sqlite(db_path, create = FALSE) %.%
        dplyr::tbl('survey_tb') %.% collect()
    # get the latest survey date of each facility
    latest_survey <- survey_df %.% dplyr::group_by(facility_id) %.% 
        dplyr::summarise(survey_time = max(survey_time)) 
    # injoin back to the full survey and keep the latest
    survey_df <- inner_join(survey_df, latest_survey, 
                            by=c("facility_id", "survey_time")) %.% 
                            dplyr::filter(!duplicated(facility_id)) %.% 
                            dplyr::select(-survey_time)
    # join with nmis data 
    df <- df %.% dplyr::select(-facility_id, matches('.'))
    df <- dplyr::inner_join(df, survey_df, by="survey_id")
    
    return(df)
}
