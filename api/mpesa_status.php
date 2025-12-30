<?php
ob_start();
require_once __DIR__ . '/../config.php';
ob_clean();
header('Content-Type: application/json');

if (!isLoggedIn()) {
    jsonResponse(['success' => false, 'message' => 'Not authenticated'], 401);
}

$data = json_decode(file_get_contents('php://input'), true);
$checkoutRequestId = $data['checkout_request_id'] ?? '';

if (empty($checkoutRequestId)) {
    jsonResponse(['success' => false, 'message' => 'Missing checkout request ID']);
}

// Query M-Pesa status
$result = MpesaAPI::checkStatus($checkoutRequestId);

// Update database
if ($result['status'] !== 'pending') {
    try {
        $stmt = db()->prepare("
            UPDATE mpesa_transactions 
            SET status = ?, mpesa_receipt = ?, updated_at = NOW()
            WHERE checkout_request_id = ?
        ");
        $stmt->execute([
            $result['status'],
            $result['mpesa_receipt'] ?? null,
            $checkoutRequestId
        ]);
    } catch (Exception $e) {
        error_log("M-Pesa Status DB Error: " . $e->getMessage());
    }
}

jsonResponse($result);