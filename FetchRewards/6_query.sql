use FetchRewards

/****************************************************************************************************************************/
/* When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?  */
/****************************************************************************************************************************/
DECLARE @RewardReceiptStatus AS table (  RewardReceiptStatus varchar(12) )
INSERT INTO @RewardReceiptStatus VALUES ('ACCEPTED')
INSERT INTO @RewardReceiptStatus VALUES ('REJECTED')

SELECT rrs.RewardReceiptStatus , count(r.TotalSpent) AS AverageSpent 
FROM Receipt r
right JOIN @RewardReceiptStatus rrs ON r.RewardReceiptStatus = rrs.RewardReceiptStatus
GROUP BY rrs.RewardReceiptStatus




