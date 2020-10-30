#!/bin/bash
# bash v4


# TODO : parametrize (output as sqlscript ...)
# TODO : Last row in table is NULL
# TODO : argument to open mysql cli after import
# TODO : handle UTF-8 encoding
# wait for container startup and not for time
# fix insecure command line password

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


INPUT_FILENAME=$1
# delemiter must be between quotes "" or ''
DELIMITER=$2
ABSOLUTE_PATH=$INPUT_FILENAME
FILENAME=${1##*/}
DB_NAME="data_csv"
TABLE_NAME=${FILENAME%.*}

# Check if file exists, else exit
if test -f "$FILENAME"; then
    echo "FILE $FILE ok"
else
    echo "FILE $ABSOLUTE_PATH not found : Be sure to use absolute path"
    exit 74
fi


docker rm -f $TABLE_NAME-mysql
docker network rm $TABLE_NAME-mysql-network


create_table_statement="CREATE TABLE IF NOT EXISTS $DB_NAME.$TABLE_NAME (id INT NOT NULL AUTO_INCREMENT,"

# get first line of csv
keys=$(head -n 1 $ABSOLUTE_PATH)

# replace commas with spaces to iterate on bash array
keys=$(echo $keys | sed "s/$DELIMITER/ /g")

# create_table_statement to create table in db
for key in $keys
do
    create_table_statement="${create_table_statement} $key VARCHAR(200),"
    
done
create_table_statement="${create_table_statement} PRIMARY KEY (id))"

echo $create_table_statement

# prepare import csv statement from csv keys
import_csv_statement="load data local infile '/$FILENAME' into table $DB_NAME.$TABLE_NAME fields terminated by '$DELIMITER' enclosed by '\\\"' lines terminated by '\n' IGNORE 1 LINES ("

for key in $keys
do
    import_csv_statement="${import_csv_statement} $key,"
    
done
# ${var%?} remove last character
import_csv_statement="${import_csv_statement%?} );"


# create network
docker network create $TABLE_NAME-mysql-network

#create stack
docker run -d --name $TABLE_NAME-mysql --network $TABLE_NAME-mysql-network -e MYSQL_ROOT_PASSWORD=password -p $EXTERNAL_CONTAINER_PORT:$INTERNAL_CONTAINER_PORT -v $ABSOLUTE_PATH:/$FILENAME mysql:$MYSQL_VERSION --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

# wait for mysql start up
sleep 8

# create db and table
docker exec $TABLE_NAME-mysql bash -c "mysql -uroot -ppassword <<< \"create database $DB_NAME\""
docker exec $TABLE_NAME-mysql bash -c "mysql -uroot -ppassword <<< \"${create_table_statement}\""

# populate table
docker exec $TABLE_NAME-mysql bash -c "mysql -uroot -ppassword <<< \"SET GLOBAL local_infile = 1;\""
docker exec $TABLE_NAME-mysql bash -c "mysql -uroot -ppassword --local-infile  <<< \"${import_csv_statement}\""

# run interactive cli
docker run -it --network $TABLE_NAME-mysql-network --rm mysql mysql -h$TABLE_NAME-mysql -uroot -ppassword --default-character-set=utf8 -A "$DB_NAME"


