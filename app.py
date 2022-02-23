# source:
# https://kb.objectrocket.com/postgresql/python-and-postgresql-docker-container-part-2-1063

#!/usr/bin/python3
# -*- coding: utf-8 -*-

import datetime

# import the connect library from psycopg2
from psycopg2 import connect

current_datetime = datetime.datetime.now()
current_time = current_datetime.strftime('%T CT')

table_name = "test_table"

# declare connection instance
conn = connect(
    dbname = "test_db",
    user = "jonas",
    host = "minor-version-upgrade-test-aurora-cluster-primary.cluster-c4lg5bob8cbp.us-west-2.rds.amazonaws.com",
    password = "password123456789"
)

# declare a cursor object from the connection
cursor = conn.cursor()

# execute an SQL statement using the psycopg2 cursor object
cursor.execute(f"INSERT into {table_name} (time) VALUES ('{current_time}')")
conn.commit()
cursor.execute(f"SELECT * from {table_name}")

# enumerate() over the PostgreSQL records
for i, record in enumerate(cursor):
    print(record[1])

# close the cursor object to avoid memory leaks
cursor.close()

# close the connection as well
conn.close()
