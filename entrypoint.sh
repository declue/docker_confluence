#!/bin/bash

keytool -storepass changeit -noprompt -import -alias mysqlclientcertificate2 -file /etc/certs/client-cert.pem

exec "$@"
