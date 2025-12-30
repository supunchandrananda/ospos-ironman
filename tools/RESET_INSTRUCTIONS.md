# Reset Sales and Stock — Instructions

What this does
- Deletes all sales and suspended sales records and related child rows.
- Truncates `ospos_item_quantities` so you can import correct quantities.

Before you run
- Backup your database. Do NOT skip this step.
- Confirm you are working on the correct database (use a copy first if unsure).

Steps (PowerShell / XAMPP example)

1) Backup DB

```powershell
& 'C:\\xampp\\mysql\\bin\\mysqldump.exe' -u root -p your_db_name > db-backup.sql
```

2) Place your stock CSV next to the SQL file and name it `stock.csv`.
   - Format: `item_id,location_id,quantity` (no header row)

3) Run the SQL template (this deletes sales and truncates quantities)

```powershell
& 'C:\\xampp\\mysql\\bin\\mysql.exe' -u root -p your_db_name < tools/reset_sales_and_stock.sql
```

4) Import your `stock.csv` (example using LOCAL INFILE)

```sql
LOAD DATA LOCAL INFILE 'C:/path/to/stock.csv' INTO TABLE ospos_item_quantities
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
(item_id, location_id, quantity);
```

Notes & safety
- If you want to preserve the inventory ledger (`ospos_inventory`) do NOT delete rows there. Instead rebuild `ospos_item_quantities` from `ospos_inventory`:

```sql
TRUNCATE TABLE ospos_item_quantities;
INSERT INTO ospos_item_quantities (item_id, location_id, quantity)
SELECT trans_items, trans_location, SUM(trans_inventory)
FROM ospos_inventory
GROUP BY trans_items, trans_location;
```

- Validate results by running:

```sql
SELECT COUNT(*) AS items, SUM(quantity) AS total_qty FROM ospos_item_quantities;
```

If you want, I can generate a ready-to-run `stock.csv` template from a list of `item_id,location_id,quantity` you provide, or adapt the SQL to preserve inventory ledger entries. Which would you prefer? 
