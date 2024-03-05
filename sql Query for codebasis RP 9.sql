use retail_events_db;





-- 1) List Of Product Base Price Is Grater Than 500 And Promo Type Is BOGOF --

select * 
from fact_events
where base_price > 500
And promo_type = 'BOGOF';









-- 2) Number Of Stores In Each Citys --

select city, count(*) as store_count
from dim_stores
group by city
order by store_count desc;


-- 3) Total Revenue Generated Before And After Promo by Campaign name --

CREATE TEMPORARY TABLE Revenue AS
SELECT 
    dim_campaigns.campaign_id,
    dim_campaigns.campaign_name,
    fact_events.`quantity_sold(before_promo)` AS quantity_sold_before_promo,
    fact_events.`quantity_sold(after_promo)` AS quantity_sold_after_promo,
    fact_events.promo_type,
    fact_events.base_price * fact_events.`quantity_sold(before_promo)` AS rev_bp,
    ROUND(
        CASE
            WHEN fact_events.promo_type = '50% OFF' THEN fact_events.base_price * 0.50 * fact_events.`quantity_sold(after_promo)`
            WHEN fact_events.promo_type = '25% OFF' THEN fact_events.base_price * 0.75 * fact_events.`quantity_sold(after_promo)`
            WHEN fact_events.promo_type = '33% OFF' THEN (fact_events.base_price - 500) * fact_events.`quantity_sold(after_promo)`
            WHEN fact_events.promo_type = '500 Cashback' THEN fact_events.base_price * 0.50 * fact_events.`quantity_sold(after_promo)`
            WHEN fact_events.promo_type = 'BOGOF' THEN fact_events.base_price * 0.50 * fact_events.`quantity_sold(after_promo)` * 2
        END,2) AS rev_ap
FROM fact_events
LEFT JOIN dim_campaigns ON fact_events.campaign_id = dim_campaigns.campaign_id;
select campaign_name,round((SUM(rev_bp)/1000000),2) as totalrevenue_beforepromo,round((SUM(rev_ap)/1000000),2) as totalrevenue_afterpromo
from Revenue
group by campaign_name;






-- 4) Incremental Sold Unit Of Each Category During Diwali Campaign --

SELECT d.category,
SUM(f.`quantity_sold(before_promo)`) AS quantity_sold_before_promo,

Sum(f.`quantity_sold(after_promo)`) AS quantity_sold_after_promo,
((sum(f.`quantity_sold(after_promo)`)- sum(f.`quantity_sold(before_promo)`))/SUM(f.`quantity_sold(before_promo)`)) * 100 AS isu_percentage,
DENSE_RANK() OVER (ORDER BY ((SUM(f.`quantity_sold(after_promo)`) - Sum(f.`quantity_sold(before_promo)`))/SUM(f.`quantity_sold(before_promo)`)) DESC) AS rank_order
FROM fact_events f
join dim_products d ON f.product_code = d.product_code
join dim_campaigns c ON f.campaign_id = c.campaign_id
WHERE c.campaign_name = "Diwali"
group by d.category;

    
    
    
-- 5) Display Top 5 Products, ranked by incremental revenue percentage (IR%) across all campaigns --

select 
	 p.product_name,
     p.category,
     (sum(fe.`quantity_sold(after_promo)`* fe.base_price)-sum(fe.`quantity_sold(before_promo)`* fe.base_price))
									/sum(fe.`quantity_sold(before_promo)` * fe.base_price) * 100 as ir_percentage
from
	 fact_events fe
join 
	 dim_products p on fe.product_code = p.product_code
group by
	 p.product_name,
     p.category
order by
	 ir_percentage desc
limit 5;
