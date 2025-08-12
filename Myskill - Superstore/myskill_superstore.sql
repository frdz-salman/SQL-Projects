ALTER TABLE order_detail
MODIFY COLUMN order_date DATE;

/*
Selama transaksi yang terjadi selama 2021, pada bulan apa total nilai transaksi (after_discount) paling besar?
Gunakan is_valid = 1 untuk memfilter data transaksi. Source table: order_detail
*/
SELECT
	monthname(order_date) month_2021_sales,
	round(sum(after_discount),2) total_transaction_value
FROM order_detail
WHERE
	extract(YEAR FROM order_date) = 2021 AND
	is_valid = 1
GROUP BY month_2021_sales
ORDER BY total_transaction_value DESC;

/*
Selama transaksi pada tahun 2022, kategori apa yang menghasilkan nilai transaksi paling
besar? Gunakan is_valid = 1 untuk memfilter data transaksi.
Source table: order_detail, sku_detail
*/
SELECT
	sd.category,
	round(sum(after_discount),2) total_transaction_2022
FROM order_detail od
	LEFT JOIN sku_detail sd
		ON od.sku_id = sd.id
WHERE
	extract(YEAR FROM order_date) = 2022 AND
	od.is_valid = 1
GROUP BY sd.category
ORDER BY total_transaction_2022 DESC;


/*
Bandingkan nilai transaksi dari masing-masing kategori pada tahun 2021 dengan 2022.
Sebutkan kategori apa saja yang mengalami peningkatan dan kategori apa yang mengalami
penurunan nilai transaksi dari tahun 2021 ke 2022. Gunakan is_valid = 1 untuk memfilter data
transaksi.
Source table: order_detail, sku_detail
*/
WITH yearly_transaction AS (
	SELECT
		sd.category,
		extract(YEAR FROM order_date) tahun,
		round(sum(od.after_discount),2) total_transaction_value
	FROM order_detail od
	LEFT JOIN sku_detail sd
		ON od.sku_id = sd.id
	WHERE od.is_valid = 1 AND extract(YEAR FROM order_date) IN (2021,2022)
	GROUP BY sd.category, tahun
),
	growth AS (
	SELECT
		y1.category,
		y0.total_transaction_value transaction_2021,
		y1.total_transaction_value transaction_2022,
		round((y1.total_transaction_value - y0.total_transaction_value),2) transaction_growth,
		round(((y1.total_transaction_value - y0.total_transaction_value)/y0.total_transaction_value)*100,2) growth_percentage
	FROM yearly_transaction y1
	LEFT JOIN yearly_transaction y0
		ON y1.category = y0.category
        AND y1.tahun = y0.tahun + 1
    WHERE y0.total_transaction_value IS NOT NULL AND y1.total_transaction_value IS NOT NULL
)
SELECT *
FROM growth
ORDER BY transaction_growth DESC;

/*
Tampilkan top 5 metode pembayaran yang paling populer digunakan selama 2022
(berdasarkan total unique order). Gunakan is_valid = 1 untuk memfilter data transaksi.
Source table: order_detail, payment_detail
*/
SELECT pd.payment_method,
	count(DISTINCT od.id) payment_2022
FROM order_detail od
LEFT JOIN payment_detail pd
	ON od.payment_id = pd.id
WHERE extract(YEAR FROM order_date) = 2022 AND od.is_valid = 1
GROUP BY pd.payment_method
ORDER BY payment_2022 DESC
LIMIT 5;
/*
Q: Urutkan dari ke-5 produk ini berdasarkan nilai transaksinya.
1. Samsung
2. Apple
3. Sony
4. Huawei
5. Lenovo
Gunakan is_valid = 1 untuk memfilter data transaksi.
Source table: order_detail, sku_detail
*/
SELECT
    CASE
        WHEN LOWER(sd.sku_name) LIKE '%samsung%' THEN 'Samsung'
        WHEN LOWER(sd.sku_name) LIKE '%apple%' OR
        	 LOWER(sd.sku_name) LIKE '%macbook%' OR
        	 LOWER(sd.sku_name) LIKE '%iphone%' THEN 'Apple'
        WHEN LOWER(sd.sku_name) LIKE '%sony%' THEN 'Sony'
        WHEN LOWER(sd.sku_name) LIKE '%huawei%' THEN 'Huawei'
        WHEN LOWER(sd.sku_name) LIKE '%lenovo%' THEN 'Lenovo'
        ELSE NULL
    END AS product_brand,
    ROUND(SUM(od.after_discount), 2) AS total_transaction
FROM order_detail od
LEFT JOIN sku_detail sd
	ON od.sku_id = sd.id
WHERE is_valid = 1
GROUP BY product_brand
HAVING product_brand IS NOT NULL
ORDER BY 2 DESC;

-- ----
WITH total_net_revenue AS (
	SELECT round(sum(price*qty_ordered)-sum(discount_amount),2) net_revenue_Rp
	FROM order_detail
	WHERE is_valid = 1
),
	cogs AS (
	SELECT round(sum(sd.cogs*od.qty_ordered),2) cogs_Rp
	FROM order_detail od
	LEFT JOIN sku_detail sd
		ON od.sku_id = sd.id
	WHERE od.is_valid = 1
),
	net_profit AS (
	SELECT tnr.net_revenue_Rp, c.cogs_Rp, round(tnr.net_revenue_Rp - c.cogs_Rp ) net_profit_Rp
	FROM total_net_revenue tnr, cogs c
)
SELECT *
FROM net_profit;

SELECT
	count(DISTINCT id) total_order,
	sum(qty_ordered) total_quantity
FROM order_detail;

SELECT
    SUM(is_gross) AS gross,
    SUM(is_valid) AS valid,
    SUM(is_net) AS net
FROM order_detail;

SELECT
	round(sum(price*qty_ordered)-sum(discount_amount),2) net_revenue_Rp,
	round(sum(sd.cogs*od.qty_ordered),2) cogs_Rp,
	round(sum(price*qty_ordered)-sum(discount_amount) - sum(sd.cogs*od.qty_ordered)) net_profit_Rp
FROM order_detail od
	LEFT JOIN sku_detail sd
		ON od.sku_id = sd.id
WHERE is_valid = 1;

SELECT
	round(sum(after_discount)/count(DISTINCT id),2) aov
FROM order_detail
WHERE is_valid = 1;
