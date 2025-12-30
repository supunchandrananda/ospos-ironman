-- Update items.cost_price and items.unit_price from CSV
SET FOREIGN_KEY_CHECKS=0;
START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS tmp_price;
CREATE TEMPORARY TABLE tmp_price (
  item_id INT NOT NULL,
  location_id INT NOT NULL,
  qty INT NOT NULL,
  csv_cost_price DECIMAL(15,2) DEFAULT 0,
  csv_unit_price DECIMAL(15,2) DEFAULT 0
);

LOAD DATA LOCAL INFILE 'E:/PROJECTS/OPOS/client-projects/IRON MAN/stock_final_as_at_20251230.csv'
INTO TABLE tmp_price
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
(item_id, location_id, qty, csv_cost_price, csv_unit_price);

-- Update cost_price where CSV provides a positive value
UPDATE ospos_items i
JOIN tmp_price t ON i.item_id = t.item_id
SET i.cost_price = t.csv_cost_price
WHERE t.csv_cost_price > 0;

-- Update unit_price where CSV provides a positive value
UPDATE ospos_items i
JOIN tmp_price t ON i.item_id = t.item_id
SET i.unit_price = t.csv_unit_price
WHERE t.csv_unit_price > 0;

-- Report how many rows would be affected (based on CSV presence)
SELECT 'items_with_csv_cost', COUNT(DISTINCT t.item_id) FROM tmp_price t WHERE t.csv_cost_price > 0;
SELECT 'items_with_csv_unit', COUNT(DISTINCT t.item_id) FROM tmp_price t WHERE t.csv_unit_price > 0;

-- Show sample of updated items (first 10)
SELECT i.item_id, i.cost_price, i.unit_price FROM ospos_items i JOIN tmp_price t ON i.item_id = t.item_id ORDER BY i.item_id LIMIT 10;

COMMIT;
SET FOREIGN_KEY_CHECKS=1;

DROP TEMPORARY TABLE IF EXISTS tmp_price;
