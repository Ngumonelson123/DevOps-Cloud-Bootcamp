<?php
// Database connection configuration
// Update these values to match your environment

$servername = "mysqlserverhost";   // Docker network hostname of the MySQL container
$username   = "<your-db-user>";    // MySQL user created via create_user.sql
$password   = "<your-db-password>";// MySQL user password
$dbname     = "toolingdb";         // Database name (from tooling_db_schema.sql)

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
