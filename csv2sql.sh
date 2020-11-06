#!/bin/bash
# bash v4


# TODO : parametrize (output as sqlscript ...)
# TODO : argument to open mysql cli after import

# https://stackoverflow.com/questions/1101957/are-there-any-standard-exit-status-codes-in-linux

#define EX_OK           0       /* successful termination */
#define EX__BASE        64      /* base value for error messages */
#define EX_USAGE        64      /* command line usage error */
#define EX_DATAERR      65      /* data format error */
#define EX_NOINPUT      66      /* cannot open input */    
#define EX_NOUSER       67      /* addressee unknown */   
#define EX_NOHOST       68      /* host name unknown */
#define EX_UNAVAILABLE  69      /* service unavailable */
#define EX_SOFTWARE     70      /* internal software error */
#define EX_OSERR        71      /* system error (e.g., can't fork) */
#define EX_OSFILE       72      /* critical OS file missing */
#define EX_CANTCREAT    73      /* can't create (user) output file */
#define EX_IOERR        74      /* input/output error */
#define EX_TEMPFAIL     75      /* temp failure; user is invited to retry */
#define EX_PROTOCOL     76      /* remote error in protocol */
#define EX_NOPERM       77      /* permission denied */
#define EX_CONFIG       78      /* configuration error */

MYSQL_VERSION=8.0.22
EXTERNAL_CONTAINER_PORT=3338
INTERNAL_CONTAINER_PORT=3306
CONTAINER_NAME=csv2sql
# get password from conf file (./conf/connection.cnf) & trim space
ROOT_PASSWORD=$(awk -F "=" '/password/ {print $2}' ./conf/connection.cnf | tr -d ' ')

INPUT_FILENAME=$1
# delemiter must be between quotes "" or ''
DELIMITER=$2
CURRENT_DIR=$(pwd)

ABSOLUTE_FILE_PATH=$INPUT_FILENAME
FILENAME=${1##*/}
DB_NAME="data_csv"
TABLE_NAME=${FILENAME%.*}

# Check if file exists, else exit
if test -f "$ABSOLUTE_FILE_PATH"; then
    echo "FILE $FILE ok"
else
    echo "FILE $ABSOLUTE_FILE_PATH not found : Be sure to use absolute path"
    exit 74
fi


create_table_statement="CREATE TABLE IF NOT EXISTS $DB_NAME.$TABLE_NAME (id INT NOT NULL AUTO_INCREMENT,"

# get first line of csv
keys=$(head -n 1 $ABSOLUTE_FILE_PATH)

# replace commas with spaces to iterate on bash array
keys=$(echo $keys | sed "s/$DELIMITER/ /g")

# create_table_statement to create table in db
for key in $keys
do
    create_table_statement="${create_table_statement} $key VARCHAR(200),"
    
done
create_table_statement="${create_table_statement} PRIMARY KEY (id))"



# prepare import csv statement from csv keys
import_csv_statement="load data local infile '/$FILENAME' into table $DB_NAME.$TABLE_NAME fields terminated by '$DELIMITER' enclosed by '\\\"' lines terminated by '\n' IGNORE 1 LINES ("

for key in $keys
do
    import_csv_statement="${import_csv_statement} $key,"
    
done
# ${var%?} remove last character
import_csv_statement="${import_csv_statement%?} );"


#create stack
docker run -d --name $CONTAINER_NAME -e MYSQL_ROOT_PASSWORD=$ROOT_PASSWORD -p $EXTERNAL_CONTAINER_PORT:$INTERNAL_CONTAINER_PORT -v $ABSOLUTE_FILE_PATH:/$FILENAME -v "$CURRENT_DIR/conf":/conf mysql:$MYSQL_VERSION --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

echo "Waiting for mysql start up ..."
# wait for mysql start up
OUTPUT="Can't connect"
while [[ $OUTPUT != *"database exists"* ]]
do
    OUTPUT=$(docker exec $CONTAINER_NAME bash -c "mysql --defaults-extra-file=/conf/connection.cnf <<< \"create database $DB_NAME\"" 2>&1)
    sleep 1
done


echo "mysql container started"
# create db and table

docker exec $CONTAINER_NAME bash -c "mysql --defaults-extra-file=/conf/connection.cnf <<< \"${create_table_statement}\""
# populate table
docker exec $CONTAINER_NAME bash -c "mysql --defaults-extra-file=/conf/connection.cnf <<< \"SET GLOBAL local_infile = 1;\""
docker exec $CONTAINER_NAME bash -c "mysql --defaults-extra-file=/conf/connection.cnf --local-infile  <<< \"${import_csv_statement}\""
# run interactive cli
docker exec -it $CONTAINER_NAME mysql --defaults-extra-file=/conf/connection.cnf --default-character-set=utf8 -A "$DB_NAME" 
echo removing container $(docker rm -f $CONTAINER_NAME)
