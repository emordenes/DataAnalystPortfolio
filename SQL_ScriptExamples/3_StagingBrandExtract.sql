USE FetchRewards

/****** Object:  Table [dbo].[StagingJsonBrand]    ******/
DECLARE @StagingJsonBrand table (
	[StagingJsonBrandID] int IDENTITY,
	[Payload] [ntext] NULL
)


INSERT INTO @StagingJsonBrand ([Payload])
SELECT [txt] FROM OPENROWSET(
BULK N'C:\Users\Charchov\OneDrive\Documents\GitHub\DataAnalystPortfolio\FetchRewards\brands.json', 
FORMATFILE=N'C:\Users\Charchov\OneDrive\Documents\GitHub\DataAnalystPortfolio\FetchRewards\StagingFormatter.xml'
) AS Contents



/**************************************************************************************/
/* Get the unique UserObjectIDs and count how many time it exists in the source file  */
/**************************************************************************************/
SELECT JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.barcode') AS BarCode
  , COUNT(*) AS [Count BarCode exist in brands.json file]
FROM @StagingJsonBrand
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0
GROUP BY JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.barcode')
ORDER BY COUNT(*)


/**************************************************************************************/
/* The following BarCodes are duplicated and are associated to different products.    */
/*  This appears to be a data issue that can throw off our queries.                   */
/*  We will try to look for a UNIQUE combinaton of column values.                     */
/*           '511111504788'        */
/*           '511111004790'        */
/*           '511111704140'        */
/*           '511111605058'        */
/*           '511111305125'        */
/*           '511111504139'        */
/*           '511111204923'        */
/**************************************************************************************/


SELECT distinct
    JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS BrandObjectID
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$.name') AS [Name]
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.barcode') AS [DUPLICATE BarCode]
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.brandCode') AS BrandCode
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.category') AS Category
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.categoryCode') AS CategoryCode
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.cpg."$id"."$oid"') AS CpgObjectID
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.cpg."$ref"')   AS CpgRef
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$.topBrand') AS [IsTopBrand]
FROM @StagingJsonBrand
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0
and JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.barcode')  IN (
  '511111504788'
, '511111004790'
, '511111704140'
, '511111605058'
, '511111305125'
, '511111504139'
, '511111204923'
)
order by JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.barcode')




/**************************************************************************************/
/* The combination BarCode + BrandCode gives us a UNIQUE KEY combination              */
/* We can use this combination as  our lookup value and will need to be reflected     */
/* in the ForeignKey relationships. */
/**************************************************************************************/
SELECT JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.barcode') AS BarCode
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.brandCode') AS BrandCode
  , COUNT(*) AS [Count BarCode+BrandCode combo exist in brands.json file]
FROM @StagingJsonBrand
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0
GROUP BY JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.barcode'), JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.brandCode')
ORDER BY COUNT(*)



/**************************************************************************************/
/* Finally, We can INSERT distinct rows (1167)                                                  */
/**************************************************************************************/
SET IDENTITY_INSERT [Brand] OFF
INSERT INTO [Brand] ( BrandObjectID, [Name], BarCode , BrandCode , Category , CategoryCode , CpgObjectID , CpgRef , IsTopBrand )
SELECT DISTINCT
    JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS BrandObjectID
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$.name') AS [Name]
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.barcode') AS BarCode
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.brandCode') AS BrandCode
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.category') AS Category
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.categoryCode') AS CategoryCode
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.cpg."$id"."$oid"') AS CpgObjectID
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.cpg."$ref"')   AS CpgRef
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$.topBrand') AS [IsTopBrand]
FROM @StagingJsonBrand
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0



select * from [Brand]