<?php
// Database connection configuration
// These values are injected via Docker environment variables
$servername = getenv('MYSQL_SERVER') ?: "mysqlserverhost";
$username   = getenv('MYSQL_USER')   ?: "<user>";
$password   = getenv('MYSQL_PASS')   ?: "<client-secret-password>";
$dbname     = getenv('MYSQL_DBNAME') ?: "toolingdb";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
