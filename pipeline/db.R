require(dplyr)

db_path = "./data/sqlite_db/facility_registry.db"
if( ! file.exists(db_path)){
    my_db <- dplyr::src_sqlite(db_path, create = TRUE)    
}


my_db_conn <- dbConnect(SQLite(), dbname=dbpath)

# dbDisconnect(SQLite(), conn = db)

dbSendQuery(conn = my_db_conn, "CREATE TABLE IF NOT EXISTS facility_tb(
                uid VARCHAR(5) PRIMARY KEY);")
            
dbSendQuery(conn = my_db_conn, "CREATE TABLE IF NOT EXISTS survey_tb(
                        uuid VARCHAR(36) UNIQUE NOT NULL,
                        survey_time INTEGER,
                        uid VARCHAR(5) NOT NULL,
                        FOREIGN KEY(uid) REFERENCES facility_tb(uid));")
dbListFields(my_db_conn, "survey_tb")

dbSendQuery(conn = my_db_conn,
            "INSERT INTO survey_tb
            VALUES ('d78a3185-5a01-429a-83fd-c6f16e23155a', 41234841, 'TLCP')")

uuid <- "c4c3bfee-fe7d-4d79-8160-731ce5b17189"
survey_time <- 41234124
uid <-gen_uid()

insert_uid <- function(){
    uid <-gen_uid()
    facility_query <- sprintf("INSERT INTO facility_tb
                        VALUES ('%s')", uid)
    dbSendQuery(conn = my_db_conn, facility_query)
    return(uid)
}

insert_new_uid <- function(){
    uid <-gen_uid()
    facility_query <- sprintf("INSERT INTO facility_tb
                        VALUES ('%s')", uid)
    tryCatch(dbSendQuery(conn = my_db_conn, facility_query),
             error = insert_new_uid())
}

db_attempt = function(some_func, max_try){
    if (max_try == 0){
        stop()
    }
    tryCatch(some_func, 
             error = function(e){
                    max_try = max_try - 1;
                    db_attempt(max_try);
                    })
}

db_attempt(insert_uid, max_try = 1000)()
dbReadTable(my_db_conn, "facility_tb")



survey_query <- sprintf("INSERT INTO survey_tb
                        VALUES ('%s', %i, '%s')", uuid, survey_time, uid)

dbSendQuery(conn = my_db_conn, survey_query)

dbReadTable(my_db_conn, "survey_tb")


edu_mopup_all[2,"uuid"]
