CREATE USER '<user>'@'%' IDENTIFIED BY '<client-secret-password>';
GRANT ALL PRIVILEGES ON *.* TO '<user>'@'%';
FLUSH PRIVILEGES;
