-- create_user.sql
-- Run this script to create a dedicated MySQL user for the Tooling app.
-- Never use root for application connections.
--
-- Usage:
--   docker exec -i mysql-server mysql -uroot -p$MYSQL_PW < ./mysql-scripts/create_user.sql

CREATE USER '<your-db-user>'@'%' IDENTIFIED BY '<your-db-password>';
GRANT ALL PRIVILEGES ON * . * TO '<your-db-user>'@'%';
FLUSH PRIVILEGES;
