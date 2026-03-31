<?php
$PROJECT_NAME = getenv('PROJECT_NAME') ?? '';
echo "<h1>Project: " . htmlspecialchars($PROJECT_NAME, ENT_QUOTES, 'UTF-8') . "</h1>";
echo "<p>Deployed successfully!</p>";
?>
