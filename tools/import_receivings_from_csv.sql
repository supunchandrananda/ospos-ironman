-- Import receivings from CSV and create a single receiving with items
-- IMPORTANT: This script expects the CSV at the path provided below and that you have a backup.
-- CSV format: item_id,location_id,quantity

SET FOREIGN_KEY_CHECKS=0;
START TRANSACTION;

-- Create temp table for import
DROP TEMPORARY TABLE IF EXISTS temp_import;
CREATE TEMPORARY TABLE temp_import (
  item_id INT NOT NULL,
  location_id INT NOT NULL,
  qty INT NOT NULL,
  csv_cost_price DECIMAL(15,2) DEFAULT 0,
  csv_unit_price DECIMAL(15,2) DEFAULT 0
);

-- Load CSV directly (expects columns: item_id,location_id,quantity,cost_price,unit_price)
LOAD DATA LOCAL INFILE 'E:/PROJECTS/OPOS/client-projects/IRON MAN/stock_final_as_at_20251230.csv' 
INTO TABLE temp_import 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n' 
(item_id, location_id, qty, csv_cost_price, csv_unit_price);

-- Insert single receiving header
INSERT INTO ospos_receivings (receiving_time, supplier_id, employee_id, comment, payment_type, reference)
VALUES (NOW(), 3, 1, 'Imported receiving', '', 'IMPORT_20251227');
SET @receiving_id = LAST_INSERT_ID();

-- Insert receivings items (quantity_purchased=qty, receiving_quantity=1 for standard unit)
INSERT INTO ospos_receivings_items (receiving_id, item_id, description, serialnumber, line, quantity_purchased, item_cost_price, item_unit_price, discount, item_location, receiving_quantity)
SELECT
  @receiving_id AS receiving_id,
  t.item_id,
  '' AS description,
  '' AS serialnumber,
  ROW_NUMBER() OVER (ORDER BY t.item_id) AS line,
  t.qty AS quantity_purchased,
  COALESCE(t.csv_cost_price, i.cost_price, 0) AS item_cost_price,
  COALESCE(t.csv_unit_price, i.unit_price, 0) AS item_unit_price,
  0 AS discount,
  t.location_id AS item_location,
  1 AS receiving_quantity
FROM temp_import t
JOIN ospos_items i ON i.item_id = t.item_id
ORDER BY t.item_id;

-- Update item_quantities (insert or update with qty)
INSERT INTO ospos_item_quantities (item_id, location_id, quantity)
SELECT item_id, location_id, qty FROM temp_import
ON DUPLICATE KEY UPDATE quantity = VALUES(quantity);

-- Insert inventory ledger rows for the receiving
INSERT INTO ospos_inventory (trans_items, trans_user, trans_date, trans_comment, trans_location, trans_inventory)
SELECT t.item_id, 1 AS trans_user, NOW() AS trans_date, CONCAT('RECV ', @receiving_id) AS trans_comment, t.location_id, t.qty
FROM temp_import t;

COMMIT;
SET FOREIGN_KEY_CHECKS=1;

-- Clean up
DROP TEMPORARY TABLE IF EXISTS temp_import;

-- Summary output
SELECT 'receiving_id' AS label, @receiving_id AS value;
SELECT 'receivings_count', COUNT(*) FROM ospos_receivings;
SELECT 'receivings_items_count', COUNT(*) FROM ospos_receivings_items WHERE receiving_id = @receiving_id;
SELECT 'item_quantities_count', COUNT(*) FROM ospos_item_quantities;
SELECT 'inventory_entries_count', COUNT(*) FROM ospos_inventory WHERE trans_comment = CONCAT('RECV ', @receiving_id);
