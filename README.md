# csv2sql

A bash script to turn a csv file into a single table database.

The script creates a mysql container, load your csv in it and open an interactive to allow you to interact with the table.

## Documentation

### Installation

- Have a debian based linux distribution
- Have bash v4 installed
- Have docker installed
- Pull the lastest tag available

### Usage


- Clean your csv

First you need to be sure your columns name are sql friendly, please avoid space in column name. Simply use letters and numbers.
The name of the csv itself should be sql friendly, no space, no dash, juste letters and numbers.

- Use the script

`./csv2sql /absolute_path/to_your_file "delimiter"`

The first argument is the absolute path to your file

The second one is the delimiter used by your "csv", traditionally it's `,` or `;`

- Use the cli

The script should open you a cli after a few loading seconds.

Then simply type `show tables;` to be sure that your table has been created, the table name is generated from your file name.

You're ready to use your simple use table !

- clean the container

After exiting the cli, the docker image should be removed, if not you can delete it manually with `docker rm -f csv2sql`