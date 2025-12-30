-- ================================================================
-- CHAIRMAN POS - Multi-Tenant Database Schema
-- Developer: Glen | +254735065427
-- ================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+03:00";

-- ----------------------------------------------------------------
-- Database Creation
-- ----------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS `chairman_pos` 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `chairman_pos`;

-- ----------------------------------------------------------------
-- Table: companies (Multi-tenant support)
-- ----------------------------------------------------------------

CREATE TABLE `companies` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_code` VARCHAR(20) NOT NULL,
    `company_name` VARCHAR(200) NOT NULL,
    `address` TEXT,
    `phone` VARCHAR(50),
    `email` VARCHAR(100),
    `logo` VARCHAR(255) DEFAULT NULL,
    `receipt_header` TEXT,
    `receipt_footer` TEXT,
    `mpesa_shortcode` VARCHAR(20) DEFAULT NULL,
    `mpesa_passkey` VARCHAR(255) DEFAULT NULL,
    `mpesa_consumer_key` VARCHAR(255) DEFAULT NULL,
    `mpesa_consumer_secret` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `company_code` (`company_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------
-- Table: users
-- ----------------------------------------------------------------

CREATE TABLE `users` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT(11) UNSIGNED NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `pin` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(100) NOT NULL,
    `role` ENUM('superadmin', 'admin', 'manager', 'cashier') DEFAULT 'cashier',
    `is_active` TINYINT(1) DEFAULT 1,
    `last_login` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `email_pin` (`email`, `pin`),
    KEY `company_id` (`company_id`),
    CONSTRAINT `users_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------
-- Table: products
-- ----------------------------------------------------------------

CREATE TABLE `products` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT(11) UNSIGNED NOT NULL,
    `barcode` VARCHAR(100) DEFAULT NULL,
    `product_name` VARCHAR(200) NOT NULL,
    `description` TEXT,
    `unit` VARCHAR(50) DEFAULT 'pc',
    `cost_price` DECIMAL(15,2) DEFAULT 0.00,
    `selling_price` DECIMAL(15,2) DEFAULT 0.00,
    `stock_quantity` DECIMAL(15,2) DEFAULT 0.00,
    `reorder_level` DECIMAL(15,2) DEFAULT 5.00,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `company_id` (`company_id`),
    KEY `barcode` (`barcode`),
    KEY `product_name` (`product_name`),
    CONSTRAINT `products_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------
-- Table: customers
-- ----------------------------------------------------------------

CREATE TABLE `customers` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT(11) UNSIGNED NOT NULL,
    `customer_name` VARCHAR(200) NOT NULL,
    `phone` VARCHAR(50),
    `email` VARCHAR(100),
    `address` TEXT,
    `balance` DECIMAL(15,2) DEFAULT 0.00,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `company_id` (`company_id`),
    CONSTRAINT `customers_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------
-- Table: sales
-- ----------------------------------------------------------------

CREATE TABLE `sales` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT(11) UNSIGNED NOT NULL,
    `sale_number` VARCHAR(50) NOT NULL,
    `user_id` INT(11) UNSIGNED NOT NULL,
    `customer_id` INT(11) UNSIGNED DEFAULT NULL,
    `subtotal` DECIMAL(15,2) DEFAULT 0.00,
    `discount` DECIMAL(15,2) DEFAULT 0.00,
    `tax` DECIMAL(15,2) DEFAULT 0.00,
    `total` DECIMAL(15,2) DEFAULT 0.00,
    `amount_paid` DECIMAL(15,2) DEFAULT 0.00,
    `change_amount` DECIMAL(15,2) DEFAULT 0.00,
    `payment_method` ENUM('cash', 'mpesa', 'card', 'credit') DEFAULT 'cash',
    `mpesa_phone` VARCHAR(20) DEFAULT NULL,
    `mpesa_receipt` VARCHAR(50) DEFAULT NULL,
    `status` ENUM('completed', 'pending', 'cancelled') DEFAULT 'completed',
    `sale_date` DATE NOT NULL,
    `sale_time` TIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `sale_number` (`company_id`, `sale_number`),
    KEY `company_id` (`company_id`),
    KEY `user_id` (`user_id`),
    KEY `customer_id` (`customer_id`),
    KEY `sale_date` (`sale_date`),
    CONSTRAINT `sales_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
    CONSTRAINT `sales_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
    CONSTRAINT `sales_customer_fk` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------
-- Table: sale_items
-- ----------------------------------------------------------------

CREATE TABLE `sale_items` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `sale_id` INT(11) UNSIGNED NOT NULL,
    `product_id` INT(11) UNSIGNED NOT NULL,
    `quantity` DECIMAL(15,2) NOT NULL,
    `unit_price` DECIMAL(15,2) NOT NULL,
    `discount` DECIMAL(15,2) DEFAULT 0.00,
    `subtotal` DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `sale_id` (`sale_id`),
    KEY `product_id` (`product_id`),
    CONSTRAINT `sale_items_sale_fk` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`id`) ON DELETE CASCADE,
    CONSTRAINT `sale_items_product_fk` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------
-- Table: mpesa_transactions
-- ----------------------------------------------------------------

CREATE TABLE `mpesa_transactions` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT(11) UNSIGNED NOT NULL,
    `sale_id` INT(11) UNSIGNED DEFAULT NULL,
    `checkout_request_id` VARCHAR(100),
    `merchant_request_id` VARCHAR(100),
    `phone_number` VARCHAR(20),
    `amount` DECIMAL(15,2),
    `mpesa_receipt` VARCHAR(50),
    `transaction_date` DATETIME,
    `status` ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    `result_code` VARCHAR(10),
    `result_desc` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `company_id` (`company_id`),
    KEY `sale_id` (`sale_id`),
    KEY `checkout_request_id` (`checkout_request_id`),
    CONSTRAINT `mpesa_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE,
    CONSTRAINT `mpesa_sale_fk` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------
-- Table: receipts
-- ----------------------------------------------------------------

CREATE TABLE `receipts` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `sale_id` INT(11) UNSIGNED NOT NULL,
    `receipt_text` LONGTEXT,
    `printed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `sale_id` (`sale_id`),
    CONSTRAINT `receipts_sale_fk` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------
-- Table: settings
-- ----------------------------------------------------------------

CREATE TABLE `settings` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `company_id` INT(11) UNSIGNED NOT NULL,
    `setting_key` VARCHAR(100) NOT NULL,
    `setting_value` TEXT,
    PRIMARY KEY (`id`),
    UNIQUE KEY `company_setting` (`company_id`, `setting_key`),
    CONSTRAINT `settings_company_fk` FOREIGN KEY (`company_id`) REFERENCES `companies` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------
-- Insert Demo Data
-- ----------------------------------------------------------------

-- Company: Baraka Tele
INSERT INTO `companies` (`id`, `company_code`, `company_name`, `address`, `phone`, `email`, `receipt_header`, `receipt_footer`) VALUES
(1, 'BARAKA', 'Baraka Tele', 'Nairobi, Kenya', '+254700000000', 'info@barakatele.com', 'BARAKA TELE\nYour Trusted Partner\nTel: +254700000000', 'Thank you for shopping with us!\nPowered by Chairman POS');

-- Users for Baraka Tele (same email, different PINs for different roles)
INSERT INTO `users` (`company_id`, `email`, `pin`, `full_name`, `role`) VALUES
(1, 'barakatele@gmail.com', 'Admin2025', 'Admin User', 'admin'),
(1, 'barakatele@gmail.com', 'cashier2025', 'Cashier User', 'cashier'),
(1, 'manager@barakatele.com', 'Manager2025', 'Manager User', 'manager');

-- Sample Products
INSERT INTO `products` (`company_id`, `barcode`, `product_name`, `unit`, `cost_price`, `selling_price`, `stock_quantity`) VALUES
(1, '5901234123457', 'Safaricom Airtime 100', 'pc', 97.00, 100.00, 100),
(1, '5901234123458', 'Safaricom Airtime 50', 'pc', 48.50, 50.00, 100),
(1, '5901234123459', 'Safaricom Airtime 20', 'pc', 19.40, 20.00, 100),
(1, '5901234123460', 'Airtel Airtime 100', 'pc', 96.00, 100.00, 50),
(1, '5901234123461', 'Airtel Airtime 50', 'pc', 48.00, 50.00, 50),
(1, '5901234123462', 'Telkom Airtime 100', 'pc', 95.00, 100.00, 30),
(1, '5901234123463', 'USB Cable Type-C', 'pc', 150.00, 250.00, 20),
(1, '5901234123464', 'Phone Charger Fast', 'pc', 300.00, 500.00, 15),
(1, '5901234123465', 'Earphones Wired', 'pc', 80.00, 150.00, 40),
(1, '5901234123466', 'Screen Protector', 'pc', 50.00, 100.00, 60),
(1, '5901234123467', 'Phone Case Universal', 'pc', 100.00, 200.00, 35),
(1, '5901234123468', 'Memory Card 32GB', 'pc', 400.00, 600.00, 10),
(1, '5901234123469', 'Power Bank 10000mAh', 'pc', 800.00, 1200.00, 8),
(1, '5901234123470', 'Bluetooth Speaker Mini', 'pc', 500.00, 800.00, 12);

-- Default Customer (Cash Sales)
INSERT INTO `customers` (`company_id`, `customer_name`, `phone`) VALUES
(1, 'Walk-in Customer', '0000000000');

COMMIT;