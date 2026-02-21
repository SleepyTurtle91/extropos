<?php
/**
 * Simple PHP proxy to bypass Appwrite CORS/domain restrictions
 * Forwards requests from the web backend to Appwrite
 */

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Appwrite-Project, X-Appwrite-Key');
header('Content-Type: application/json');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get request details
$method = $_SERVER['REQUEST_METHOD'];
$path = $_GET['path'] ?? '/v1/databases';
$appwriteEndpoint = 'http://localhost:8080';

// Get headers from the incoming request
$projectId = $_SERVER['HTTP_X_APPWRITE_PROJECT'] ?? '';
$apiKey = $_SERVER['HTTP_X_APPWRITE_KEY'] ?? '';

// Build the full URL
$url = $appwriteEndpoint . $path;

// Initialize cURL
$ch = curl_init($url);

// Set cURL options
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);

// Set headers
$headers = [
    'Content-Type: application/json',
    'X-Appwrite-Project: ' . $projectId,
    'X-Appwrite-Key: ' . $apiKey
];
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

// Handle request body for POST/PUT/PATCH
if (in_array($method, ['POST', 'PUT', 'PATCH'])) {
    $body = file_get_contents('php://input');
    curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
}

// Execute the request
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);

curl_close($ch);

// Return the response
http_response_code($httpCode);

if ($error) {
    echo json_encode([
        'error' => $error,
        'message' => 'Proxy error: ' . $error
    ]);
} else {
    echo $response;
}
