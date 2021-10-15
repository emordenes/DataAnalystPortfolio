USE FetchRewards



/****** Object:  Table [dbo].[StagingJsonReceipt]    ******/

DECLARE @StagingJsonReceipt table (
	[StagingJsonReceiptID] int IDENTITY,
	[Payload] [ntext] NULL
)

INSERT INTO @StagingJsonReceipt ([Payload])
SELECT [txt] FROM OPENROWSET(
BULK N'C:\Users\Charchov\OneDrive\Documents\GitHub\DataAnalystPortfolio\FetchRewards\receipts.json', 
FORMATFILE=N'C:\Users\Charchov\OneDrive\Documents\GitHub\DataAnalystPortfolio\FetchRewards\StagingFormatter.xml'
) AS Contents



/**************************************************************************************/
/* Receipt _uuid (ReciptObjtID) is unique for the whole source file, this is good.    */
/* We can assume that each row is unique.                                             */
/**************************************************************************************/
SELECT 
    JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS ReceiptObjectID
  , COUNT(*) AS [Count existinig DUPLICATE  ReceiptID in receipt.json file]
FROM @StagingJsonReceipt
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0
GROUP BY JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"')
HAVING COUNT(*) > 1

/**************************************************************************************/
/* There are 148 Receipts that do not have a UserID in the User table.                */
/* We should import these receipt anyway, so we do not lose Receipt data.             */
/* We can remove any enforcement on Foreign Key Contraint on the User relationship    */
/* (see ERD)  between Receipt and User   */
/**************************************************************************************/
SELECT 
    JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS ReceiptObjectID
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$.userId')    AS [UserID does not exist in users.json file]
FROM @StagingJsonReceipt
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0
AND  JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$.userId') NOT IN (SELECT UserObjectID FROM [User])



/************************************************************************************************/
/* Finally, we can INSERT all the UNIQUE Receipts into the Receipt table  (1119)                */
/************************************************************************************************/
INSERT INTO Receipt ( ReceiptObjectID, BonusPointsEarned , BonusPointsEarnedReason , DateCreated , DateScanned , DateFinished
					, DateModified , DatePointsAwarded , DatePurchased , PointsEarned , PurchasedItemCount , RewardReceiptStatus 
					, TotalSpent , UserObjectID )
SELECT 
    JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS ReceiptObjectID
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.bonusPointsEarned') AS BonusPointsEarned
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.bonusPointsEarnedReason') AS BonusPointsEarnedReason

  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.createDate."$date"')) AS CreatedDateFormatted
  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.dateScanned."$date"')) AS DateScannedFormatted
  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.finishedDate."$date"')) AS FinishedDateFormatted
  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.modifyDate."$date"')) AS ModifyDateFormatted
  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.pointsAwardedDate."$date"')) AS PointsAwardedDate
  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.purchaseDate."$date"')) AS PurchaseDate

  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.pointsEarned') AS PointsEarned
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.purchasedItemCount') AS PurchasedItemCount
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.rewardsReceiptStatus') AS RewardsReceiptStatus
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.totalSpent') AS TotalSpent
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.userId') AS UserId
FROM @StagingJsonReceipt
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0

select * from Receipt
