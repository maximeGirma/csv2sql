#!/bin/bash
# bash v4


# TODO : parametrize (filename, output as sqlscript ...)
# TODO : use var instead of hard coded var
# TODO : headers are in first row in table (id 1)
# TODO : Last row in table is NULL
# TODO :  argument to open mysql cli after import

docker rm -f some-mysql
docker network rm some-mysql-network


DB_NAME="test"


create_table_statement="CREATE TABLE IF NOT EXISTS test.test (id INT NOT NULL AUTO_INCREMENT,"

# get first line of csv
keys=$(head -n 1 data.csv)

# replace commas with spaces to iterate on bash array
keys=$(echo $keys | sed 's/,/ /g')

# create_table_statement to create table in db
for key in $keys
do
    create_table_statement="${create_table_statement} $key VARCHAR(200),"
    
done
create_table_statement="${create_table_statement} PRIMARY KEY (id))"



# prepare import csv statement from csv keys
import_csv_statement="load data local infile '/data.csv' into table test.test fields terminated by ',' enclosed by '\\\"' lines terminated by '\n' ("

for key in $keys
do
    import_csv_statement="${import_csv_statement} $key,"
    
done
# ${var%?} remove last character
import_csv_statement="${import_csv_statement%?} );"


# create network
docker network create some-mysql-network

#create stack
docker run -d --name some-mysql --network some-mysql-network -e MYSQL_ROOT_PASSWORD=password -p 3306:3306 -v /home/maxime/projects/docker/db/data.csv:/data.csv mysql:latest


# create db

docker exec some-mysql bash -c "echo ..."

sleep 8

docker exec some-mysql bash -c "mysql -uroot -ppassword <<< \"create database test\""
docker exec some-mysql bash -c "mysql -uroot -ppassword <<< \"${create_table_statement}\""

echo $import_csv_statement

docker exec some-mysql bash -c "mysql -uroot -ppassword <<< \"SET GLOBAL local_infile = 1;\""
docker exec some-mysql bash -c "mysql -uroot -ppassword --local-infile  <<< \"${import_csv_statement}\""


docker run -it --network some-mysql-network --rm mysql mysql -hsome-mysql -uroot -ppassword "test;"


