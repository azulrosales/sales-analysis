-- Who is our best costumer? This could be best answered with RFM Analysis.

-- RFM Analysis:
-- * Indexing technique that uses past purchase behavior to segment costumers.
-- * It uses 3 key metrics:
--		1. Recency. How long ago their last purchase was - last order date.
--		2. Frequency. How often do they purchase - count of total orders.
--		3. Monetary. How much they spent - total spent (either sum or avg). 

DROP TABLE IF EXISTS #RFM;
DROP TABLE IF EXISTS #COSTUMER_SEGMENTATION;

WITH RFM AS ( -- Saving the query result into a CTE called RFM
	SELECT 
		CUSTOMERNAME,
		SUM(SALES) AS MONETARY_VALUE,
		AVG(SALES) AS AVG_MONETARY_VALUE,
		COUNT(ORDERNUMBER) AS FREQUENCY,
		MAX(ORDERDATE) AS LAST_ORDER_DATE,
		(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample]) AS MAX_ORDER_DATE, -- last order date registered in the database
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample])) AS RECENCY
	FROM [dbo].[sales_data_sample]
	GROUP BY CUSTOMERNAME
), 
RFM_CALC AS ( 
-- Creating 5 groups using NTILES(), this will group costumers and give them a score from 1 to 4:
-- The lower the Recency the highest the score, but the highest the Monetary Value and the Frequency
-- of Orders, the highest the score. 
SELECT R.*,
	NTILE(5) OVER (ORDER BY RECENCY DESC) RFM_RECENCY,
	NTILE(5) OVER (ORDER BY FREQUENCY) RFM_FREQUENCY,
	NTILE(5) OVER (ORDER BY AVG_MONETARY_VALUE) RFM_MONETARY
FROM RFM AS R
)

SELECT C.*,
	RFM_RECENCY + RFM_FREQUENCY + RFM_MONETARY AS RFM_SCORE,
	CAST(RFM_RECENCY AS VARCHAR) + '-' + CAST(RFM_FREQUENCY AS VARCHAR) + '-' + CAST(RFM_MONETARY AS VARCHAR) AS RFM_STRING
INTO #RFM
FROM RFM_CALC AS C;

SELECT * FROM #RFM;

-- Customer Segmentation
SELECT 
	CUSTOMERNAME, RFM_RECENCY, RFM_FREQUENCY, RFM_MONETARY,
	CASE
		WHEN RFM_STRING IN ('5-5-5', '5-5-4', '5-4-4', '5-4-5', '4-5-4', '4-5-5', '4-4-5') THEN 'Champion'
		WHEN RFM_STRING IN ('5-4-3', '4-4-4', '4-3-5', '3-5-5', '3-5-4', '3-4-5', '3-4-4', '3-3-5') THEN 'Loyal'
		WHEN RFM_STRING IN ('5-5-3', '5-5-1', '5-5-2', '5-4-1', '5-4-2', '5-3-3', '5-3-2', '5-3-1', 
							'4-5-2', '4-5-1', '4-4-2', '4-4-1', '4-3-1', '4-5-3', '4-3-3', '4-3-2', 
							'4-2-3', '3-5-3', '3-5-2', '3-5-1', '3-4-2', '3-4-1', '3-3-3', '3-2-3') THEN 'Potential Loyalist'
		WHEN RFM_STRING IN ('5-1-2', '5-1-1', '4-2-2', '4-2-1', '4-1-2', '4-1-1', '3-1-1') THEN 'New Costumer'
		WHEN RFM_STRING IN ('5-2-5', '5-2-4', '5-2-3', '5-2-2', '5-2-1', '5-1-5', '5-1-4', '5-1-3', 
							'4-2-5', '4-2-4', '4-1-3', '4-1-4', '4-1-5', '3-1-5', '3-1-4', '3-1-3') THEN 'Promising'
		WHEN RFM_STRING IN ('5-3-5', '5-3-4', '4-4-3', '4-3-4', '3-4-3', '3-3-4', '3-2-5', '3-2-4') THEN 'Needs Attention'
		WHEN RFM_STRING IN ('3-3-1', '3-2-1', '3-1-2', '2-2-1', '2-1-3', '2-3-1', '2-4-1', '2-5-1') THEN 'About To Sleep'
		WHEN RFM_STRING IN ('2-5-5', '2-5-4', '2-4-5', '2-4-4', '2-5-3', '2-5-2', '2-4-3', '2-4-2', 
							'2-3-5', '2-3-4', '2-2-5', '2-2-4', '1-5-3', '1-5-2', '1-4-5', '1-4-3', 
							'1-4-2', '1-3-5', '1-3-4', '1-3-3', '1-2-5', '1-2-4') THEN 'At Risk'
		WHEN RFM_STRING IN ('1-5-5', '1-5-4', '1-4-4', '2-1-4', '2-1-5', '1-1-5', '1-1-4', '1-1-3') THEN 'Cannot Lose Them'
		WHEN RFM_STRING IN ('3-3-2', '3-2-2', '2-3-3', '2-3-2', '2-2-3', '2-2-2', '1-3-2', '1-2-3', 
							'1-2-2', '2-1-2', '2-1-1') THEN 'Hibernating Costumer'
		WHEN RFM_STRING IN ('1-1-1', '1-1-2', '1-2-1', '1-3-1', '1-4-1', '1-5-1') THEN 'Lost Costumer'
	END RFM_SEGMENT
	INTO #COSTUMER_SEGMENTATION
FROM #RFM;
