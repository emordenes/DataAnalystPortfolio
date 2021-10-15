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


INSERT INTO @RewardReceiptItems
SELECT 
    JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS ReceiptObjectID
  , JSON_QUERY( CAST( Payload AS nvarchar(max) ) , '$.rewardsReceiptItemList') AS RewardReveiptItems
FROM @StagingJsonReceipt
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0




/**************************************************************************************/
/* We are able to extract 6941 ReceiptItems from the Recipt.json file                */
/**************************************************************************************/
SELECT  COUNT(*) AS [Total ReceipItems]
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




/**************************************************************************************/
/* Out of 6941 ReceiptItems, there are 2997 without BarCode and BrandCode (43%)       */
/* and 3851 without BarCode alone (55%)                                               */
/* This presents a mayor issue, since, being able to Query on Brands per Receipt will */
/* not yield accurate results.  This is because the relationship keys (foreign keys)  */
/* between [ResultItem] and [Brand] tables require BarCode column to be present       */
/**************************************************************************************/
SELECT  COUNT(*) AS [Receipt Items With Null BarCode And BrandCode]
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
AND jsonRewardReceiptItem.BarCode  IS NULL AND jsonRewardReceiptItem.BrandCode  IS NULL 


/************************************************************************************************/
/* We noticed that  NeedsFetchReviewReason is an indicator to use BarCode or UserFlaggedBarCode */
/* When NeedsFetchReviewReason = 'USER_FLAGGED' we may be able to use UserFlaggedBarCode,       */
/* otherwise, we can use BarCode                                                                */
/* After testing, we still have negative results.                                               */
/* Even with this logic, there are still 3705 missing BarCodes (53%).                           */ 
/************************************************************************************************/
SELECT    rr.ReceiptObjectID
		, CASE NeedsFetchReviewReason WHEN 'USER_FLAGGED' THEN UserFlaggedBarCode ELSE BarCode END  AS [Conditional BarCode]
		, jsonRewardReceiptItem.*
		
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
	, NeedsFetchReviewReason varchar(max) '$.needsFetchReviewReason'
	, originalReceiptItemText nvarchar(max) '$.originalReceiptItemText'
	, partnerItemId varchar(20) '$.partnerItemId'
	, quantityPurchased int '$.quantityPurchased'
	, RewardsGroup varchar(100) '$.rewardsGroup'
	, RewardsProductPartnerID varchar(30) '$.rewardsProductPartnerId'
	, PreventTargetGapPoints bit '$.preventTargetGapPoints'
	, UserFlaggedBarCode varchar(20) '$.userFlaggedBarcode'
	, UserFlaggedDescription varchar(100) '$.userFlaggedDescription'
	, UserFlaggedNewItem bit '$.userFlaggedNewItem'
	, UserFlaggedPrice decimal(10,2) '$.userFlaggedPrice'
	, UserFlaggedQuantity int '$.userFlaggedQuantity'

	) as jsonRewardReceiptItem
WHERE ISJSON( CAST( rr.Payload AS nvarchar(max) ) ) > 0
AND (CASE NeedsFetchReviewReason WHEN 'USER_FLAGGED' THEN UserFlaggedBarCode ELSE BarCode END) IS NULL


/*********************************************************************************************************/
/* There are 6861 ReceiptItems (98%) that do not have an associated BarCode/BrandCode in the Brand table */
/* There are 6859 ReceiptItems (98%) that do not have an associated BarCode in the Brand table           */
/* There are 6312 ReceiptItems (99%) that do not have an associated BrandCode in the Brand table         */
/* This presents a mayor issue, since, being able to Query on Brands per Receipt will                    */
/* not yield accurate results.  This is because in order to retrieve Brand related data per Recipts ,    */
/* the Brand must be present in the Brand table.                                                         */
/* This issue is also caused by the many missing Barcode and BrandCode in the ReceiptItem data           */
/*********************************************************************************************************/
SELECT 
		  jsonRewardReceiptItem.BarCode AS [BarCode+BrandCode (in receipts.json) that does not exist in brands.json file]
		, jsonRewardReceiptItem.BrandCode AS [BarCode+BrandCode (in receipts.json)]
		, b.BarCode [BarCode does not exist in brands.json]
		, b.BrandCode [BrandCode does not exist in brands.json]
		, rr.ReceiptObjectID
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
LEFT JOIN [Brand] b ON  jsonRewardReceiptItem.BarCode   = b.BarCode
					AND jsonRewardReceiptItem.BrandCode = b.BrandCode
WHERE ISJSON( CAST( rr.Payload AS nvarchar(max) ) ) > 0
AND b.BrandObjectID IS NULL


/************************************************************************************************************/
/* We can remove any enforcement on Foreign Key Contraint on the BarCode/BrandCode relationship             */
/* (see ERD)  between ReceiptItem and Brand                                                                 */
/************************************************************************************************************/
/* We can insert into the ReceiptItem table   as the data is currenlty available                            */
/* Once the data is in the relational database, we can run more queries for analysis                        */
/* This is a mayor data issue and Stakeholder will be notified, since it negatively impact the requirements */
/************************************************************************************************************/

INSERT INTO   [ReceiptItem] (ReceiptObjectID , BarCode , BrandCode , [Description] , DiscountedItemPrice  
			, FinalPrice , ItemPrice , NeedFetchReview , NeedsFetchReviewReason , OriginalReceiptItemText 
			, PartnerItemID , QuantityPurchased , RewardsGroup , RewardsProductPartnerID , PreventTargetGapPoints
			, UserFlaggedBarCode , UserFlaggedDescription , UserFlaggedNewItem , UserFlaggedPrice , UserFlaggedQuantity )
SELECT    rr.ReceiptObjectID
		, jsonRewardReceiptItem.BarCode
		, jsonRewardReceiptItem.BrandCode
		, jsonRewardReceiptItem.[Description]
		, jsonRewardReceiptItem.DiscountedItemPrice
		, jsonRewardReceiptItem.FinalPrice
		, jsonRewardReceiptItem.ItemPrice
		, jsonRewardReceiptItem.NeedsFetchReview
		, jsonRewardReceiptItem.NeedsFetchReviewReason
		, jsonRewardReceiptItem.OriginalReceiptItemText
		, jsonRewardReceiptItem.PartnerItemID
		, jsonRewardReceiptItem.QuantityPurchased
		, jsonRewardReceiptItem.RewardsGroup
		, jsonRewardReceiptItem.RewardsProductPartnerID
		, jsonRewardReceiptItem.PreventTargetGapPoints
		, jsonRewardReceiptItem.UserFlaggedBarCode
		, jsonRewardReceiptItem.UserFlaggedDescription
		, jsonRewardReceiptItem.UserFlaggedNewItem
		, jsonRewardReceiptItem.UserFlaggedPrice
		, jsonRewardReceiptItem.UserFlaggedQuantity

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
	, NeedsFetchReviewReason varchar(max) '$.needsFetchReviewReason'
	, originalReceiptItemText nvarchar(max) '$.originalReceiptItemText'
	, partnerItemId varchar(20) '$.partnerItemId'
	, quantityPurchased int '$.quantityPurchased'
	, RewardsGroup varchar(100) '$.rewardsGroup'
	, RewardsProductPartnerID varchar(30) '$.rewardsProductPartnerId'
	, PreventTargetGapPoints bit '$.preventTargetGapPoints'
	, UserFlaggedBarCode varchar(20) '$.userFlaggedBarcode'
	, UserFlaggedDescription varchar(100) '$.userFlaggedDescription'
	, UserFlaggedNewItem bit '$.userFlaggedNewItem'
	, UserFlaggedPrice decimal(10,2) '$.userFlaggedPrice'
	, UserFlaggedQuantity int '$.userFlaggedQuantity'

	) as jsonRewardReceiptItem
WHERE ISJSON( CAST( rr.Payload AS nvarchar(max) ) ) > 0


select * from [ReceiptItem]


