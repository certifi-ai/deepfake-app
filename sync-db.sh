#!/bin/sh

REMOTE_USER=default
REMOTE_DB=verceldb
REMOTE_HOST=PLACEHOLDER-HOSTNAME.postgres.vercel-storage.com

LOCAL_USER=mylocaluser
LOCAL_DB=mydatabase

echo "Downloading snapshot of prod database..."
pg_dump -U $REMOTE_USER -h $REMOTE_HOST -Fc --clean --if-exists $REMOTE_DB > prod.dump

echo "Replacing local database with prod data..."
pg_restore -U $LOCAL_USER -d $LOCAL_DB --no-owner --role=$LOCAL_USER -c prod.dump

rm prod.dump
