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



DECLARE @RewardReceiptItems AS table
	( ReceiptObjectID  varchar(30)
	, Payload   nvarchar(max) 
	)

SELECT [StagingJsonReceiptID]
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS ReceiptObjectID
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.bonusPointsEarned') AS BonusPointsEarned
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.bonusPointsEarnedReason') AS BonusPointsEarnedReason

  , dateadd(ms, CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.createDate."$date"') AS bigint ) 
   / 86400000, (CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.createDate."$date"') AS bigint ) / 86400000) + 25567) AS CreatedDateFormatted
  , dateadd(ms, CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.dateScanned."$date"')   AS bigint ) 
   / 86400000, (CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.dateScanned."$date"')   AS bigint ) / 86400000) + 25567) AS DateScannedFormatted
  , dateadd(ms, CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.finishedDate."$date"')   AS bigint ) 
   / 86400000, (CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.finishedDate."$date"')   AS bigint ) / 86400000) + 25567) AS FinishedDateFormatted
  , dateadd(ms, CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.modifyDate."$date"')   AS bigint ) 
   / 86400000, (CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.modifyDate."$date"')   AS bigint ) / 86400000) + 25567) AS ModifyDateFormatted
  , dateadd(ms, CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.pointsAwardedDate."$date"')   AS bigint ) 
   / 86400000, (CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.pointsAwardedDate."$date"')   AS bigint ) / 86400000) + 25567) AS PointsAwardedDate
  , dateadd(ms, CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.purchaseDate."$date"')   AS bigint ) 
   / 86400000, (CAST( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.purchaseDate."$date"')   AS bigint ) / 86400000) + 25567) AS PurchaseDate

  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.createDate."$date"') AS CreatedDate
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.dateScanned."$date"')   AS DateScanned
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.finishedDate."$date"')   AS FinishedDate
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.modifyDate."$date"')   AS ModifyDate
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.pointsAwardedDate."$date"')   AS PointsAwardedDate
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.purchaseDate."$date"')   AS PurchaseDate

  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.pointsEarned') AS PointsEarned
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.purchasedItemCount') AS PurchasedItemCount
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.rewardsReceiptStatus') AS RewardsReceiptStatus
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.totalSpent') AS TotalSpent
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.userId') AS UserId
FROM @StagingJsonReceipt
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0



INSERT INTO @RewardReceiptItems
SELECT 
    JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS ReceiptObjectID
  , JSON_QUERY( CAST( Payload AS nvarchar(max) ) , '$.rewardsReceiptItemList') AS RewardReveiptItems
FROM @StagingJsonReceipt
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0


SELECT rr.ReceiptObjectID , jsonRewardReceiptItem.*
FROM @RewardReceiptItems rr
CROSS APPLY OPENJSON(rr.Payload)
WITH (
	  BarCode nvarchar(max) '$.barcode'
	, BrandCode nvarchar(max) '$.brandCode'
	, [Description] nvarchar(max) '$.description'
	, DiscountedItemPrice decimal(10,2) '$.discountedItemPrice'
	, FinalPrice decimal(10,2) '$.finalPrice'
	, ItemPrice decimal(10,2) '$.itemPrice'
	, NeedsFetchReview bit '$.needsFetchReview'
	, originalReceiptItemText nvarchar(max) '$.originalReceiptItemText'
	, partnerItemId varchar(20) '$.partnerItemId'
	, quantityPurchased int '$.quantityPurchased'
	) as jsonRewardReceiptItem
WHERE ISJSON( CAST( rr.Payload AS nvarchar(max) ) ) > 0


