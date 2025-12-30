-- Reset all sales and provide a template to reset item quantities.
-- IMPORTANT: BACKUP your database before running this file.
-- Example (PowerShell/XAMPP):
-- & 'C:\\xampp\\mysql\\bin\\mysqldump.exe' -u root -p your_db_name > db-backup.sql
-- & 'C:\\xampp\\mysql\\bin\\mysql.exe' -u root -p your_db_name < tools/reset_sales_and_stock.sql

SET FOREIGN_KEY_CHECKS=0;
START TRANSACTION;

-- Remove all sales (main and suspended) and their child rows
DELETE FROM ospos_sales_items_taxes;
DELETE FROM ospos_sales_payments;
DELETE FROM ospos_sales_items;
DELETE FROM ospos_sales;

-- Conditionally delete suspended sales tables if they exist (avoids errors when not present)
SELECT COUNT(*) INTO @c FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'ospos_sales_suspended_items_taxes';
SET @sql = IF(@c > 0, 'DELETE FROM ospos_sales_suspended_items_taxes;', 'SELECT 0;');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT COUNT(*) INTO @c FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'ospos_sales_suspended_payments';
SET @sql = IF(@c > 0, 'DELETE FROM ospos_sales_suspended_payments;', 'SELECT 0;');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT COUNT(*) INTO @c FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'ospos_sales_suspended_items';
SET @sql = IF(@c > 0, 'DELETE FROM ospos_sales_suspended_items;', 'SELECT 0;');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT COUNT(*) INTO @c FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'ospos_sales_suspended';
SET @sql = IF(@c > 0, 'DELETE FROM ospos_sales_suspended;', 'SELECT 0;');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Conditionally delete receivings and their items
SELECT COUNT(*) INTO @c FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'ospos_receivings_items';
SET @sql = IF(@c > 0, 'DELETE FROM ospos_receivings_items;', 'SELECT 0;');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT COUNT(*) INTO @c FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'ospos_receivings';
SET @sql = IF(@c > 0, 'DELETE FROM ospos_receivings;', 'SELECT 0;');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Optionally delete inventory ledger rows created by sales/receivings. We'll remove entries beginning with 'POS ' and 'RECV '.
SELECT COUNT(*) INTO @c FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'ospos_inventory';
SET @sql = IF(@c > 0, "DELETE FROM ospos_inventory WHERE trans_comment LIKE 'POS %' OR trans_comment LIKE 'RECV %';", 'SELECT 0;');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- If you track inventory ledger entries and want them removed as well,
-- uncomment the following line. This deletes rows whose comment begins with 'POS '.
-- DELETE FROM ospos_inventory WHERE trans_comment LIKE 'POS %';

-- Remove related reporting / payments rows if any other tables exist (be cautious)

COMMIT;
SET FOREIGN_KEY_CHECKS=1;

-- Reset item quantities table (this will remove current values).
-- We assume you will IMPORT or INSERT the correct quantities below.
TRUNCATE TABLE ospos_item_quantities;

-- Example insert statements: replace with your actual values or use CSV import.
-- INSERT INTO ospos_item_quantities (item_id, location_id, quantity) VALUES (1, 1, 10);
-- INSERT INTO ospos_item_quantities (item_id, location_id, quantity) VALUES (2, 1, 5);

-- If you have a CSV `stock.csv` with rows: item_id,location_id,quantity
-- and you want to load it via MySQL client with LOCAL INFILE enabled you can run:
-- LOAD DATA LOCAL INFILE 'stock.csv' INTO TABLE ospos_item_quantities
-- FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' (item_id, location_id, quantity);

-- Quick verification queries you can run after executing the file:
-- SELECT COUNT(*) AS items, SUM(quantity) AS total_qty FROM ospos_item_quantities;
-- SELECT item_id, location_id, quantity FROM ospos_item_quantities ORDER BY item_id LIMIT 50;
