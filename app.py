# source:
# https://kb.objectrocket.com/postgresql/python-and-postgresql-docker-container-part-2-1063

#!/usr/bin/python3
# -*- coding: utf-8 -*-

import datetime
import psycopg2
import os
import time

hostname = os.environ['HOSTNAME']

hostname_replaced = hostname.replace('-', '_')

table_name = hostname

try:
    conn = psycopg2.connect(
        dbname = "test_db",
        user = "jonas",
        host = "minor-version-upgrade-test-aurora-cluster-primary.cluster-c4lg5bob8cbp.us-west-2.rds.amazonaws.com",
        password = "password123456789"
    )
except psycopg2.OperationalError as e:
    # format time as 'HH:MM:SS CT'
    current_datetime = datetime.datetime.now()
    current_time = current_datetime.strftime('%T CT')
    print(f"[ERROR]: database down at {current_time}")
else:
    # declare a cursor object from the connection
    cursor = conn.cursor()

    # format time as 'HH:MM:SS CT'
    current_datetime = datetime.datetime.now()
    current_time = current_datetime.strftime('%T CT')

    # execute an SQL statement using the psycopg2 cursor object
    cursor.execute(f"create table {table_name}(id serial primary key, time char(11) not null)")

    # not the same time, but oh well
    print(f"[INFO]: table {table_name} created at {current_time}")
    
    # actually have to commit changes, doh!
    conn.commit()

    # close the cursor object to avoid memory leaks
    cursor.close()

    # close the connection as well
    conn.close()

# connection and write loop
while True:
    try:
        conn = psycopg2.connect(
            dbname = "test_db",
            user = "jonas",
            host = "minor-version-upgrade-test-aurora-cluster-primary.cluster-c4lg5bob8cbp.us-west-2.rds.amazonaws.com",
            password = "password123456789"
        )
    except psycopg2.OperationalError as e:
        # format time as 'HH:MM:SS CT'
        current_datetime = datetime.datetime.now()
        current_time = current_datetime.strftime('%T CT')
        print(f"[ERROR]: database down at {current_time}")
        time.sleep(1)
    else:
        # declare a cursor object from the connection
        cursor = conn.cursor()

        # format time as 'HH:MM:SS CT'
        current_datetime = datetime.datetime.now()
        current_time = current_datetime.strftime('%T CT')

        # execute an SQL statement using the psycopg2 cursor object
        cursor.execute(f"INSERT into {table_name} (time) VALUES ('{current_time}')")
        # not the same time, but oh well
        print(f"[INFO]: database up at {current_time}")
        
        # actually have to commit changes, doh!
        conn.commit()
        time.sleep(1)

        # close the cursor object to avoid memory leaks
        cursor.close()

        # close the connection as well
        conn.close()
