#!/bin/sh

echo "seting up $1"
# get deps
apk add curl jq
# get the wait-until script
curl -L https://raw.githubusercontent.com/nickjj/wait-until/v0.2.0/wait-until -o /usr/local/bin/wait-until && \
chmod +x /usr/local/bin/wait-until
# run the script and everything else
wait-until "echo 'Checking if Metabase is ready' && curl -s http://$1/api/health | grep -ioE 'ok'" 60 && \
if curl -s http://$1/api/session/properties | jq -r '."setup-token"' | grep -ioE "null"; then echo 'Instance already configured, exiting (or <v43)'; else \
echo 'Setting up the instance' && \
token=$(curl -s http://$1/api/session/properties | jq -r '."setup-token"') && \
echo 'Setup token fetched, now configuring with:' && \
echo "{'token':'$token','user':{'first_name':'a','last_name':'b','email':'a@b.com','site_name':'metabot1','password':'metabot1','password_confirm':'metabot1'},'database':null,'invite':null,'prefs':{'site_name':'metabot1','site_locale':'en','allow_tracking':'false'}}" > file.json && \
sed 's/'\''/\"/g' file.json > file2.json && \
cat file2.json && \
sessionToken=$(curl -s http://$1/api/setup -H 'Content-Type: application/json' --data-binary @file2.json | jq -r '.id') && echo ' < Admin session token, exiting' && \
# creating a postgres
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"postgres","name":"pg","details":{"host":"pgpool-data-db","port":"5432","dbname":"sample","user":"metabase","password":"metasample123","schema-filters-type":"all","ssl":false,"tunnel-enabled":false,"advanced-options":false},"is_full_sync":true}' &&
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"postgres","name":"postgres-other","details":{"host":"postgres-another-data","port":"5432","dbname":"sample","user":"metabase","password":"metasample123","schema-filters-type":"all","ssl":false,"tunnel-enabled":false,"advanced-options":false},"is_full_sync":true}' &&
curl -s -X POST http://$1/api/database -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken" --data '{"engine":"postgres","name":"postgres-app-db","details":{"host":"pgpool-app-db","port":"5432","dbname":"metabase","user":"metabase","password":"metabase","schema-filters-type":"all","ssl":false,"tunnel-enabled":false,"advanced-options":false},"is_full_sync":true}' &&
curl -s -X DELETE http://$1/api/database/1 -H 'Content-Type: application/json' --cookie "metabase.SESSION=$sessionToken"; fi