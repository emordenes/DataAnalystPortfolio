USE FetchRewards



/****** Object:  Table [dbo].[StagingJsonUser]    ******/
DECLARE @StagingJsonUser table (
	[StagingJsonUserID] int IDENTITY,
	[Payload] [ntext] NULL
)

INSERT INTO @StagingJsonUser ([Payload])
SELECT [txt] FROM OPENROWSET(
BULK N'C:\Users\Charchov\OneDrive\Documents\GitHub\DataAnalystPortfolio\FetchRewards\users.json', 
FORMATFILE=N'C:\Users\Charchov\OneDrive\Documents\GitHub\DataAnalystPortfolio\FetchRewards\StagingFormatter.xml'
) AS Contents


/**************************************************************************************/
/* Get the unique UserObjectIDs and count how many time it exists in the source file  */
/**************************************************************************************/
SELECT  
      JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS UserObjectID
	, COUNT(*) AS [Count UserID exist in users.json file]
FROM @StagingJsonUser
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0
GROUP BY JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"')
ORDER BY COUNT(*)

/**************************************************************************************/
/* Get the distinct rows. this differs from the above staement because the data      */
/* could have a repeated UserObjectID, but differences in other columns               */
/**************************************************************************************/
SELECT  distinct
    JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS UserObjectID
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.active') AS IsActive
  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.createdDate."$date"' )) AS CreatedDateFormatted
  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.lastLogin."$date"' )) AS LastLoginDateFormatted
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.role') AS [Role]
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.signUpSource') AS [SignUpSource]
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.state') AS [State]
FROM @StagingJsonUser
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0


/**************************************************************************************/
/* Because the grouped UserObjectID count(212) is the same number as distinct rows,   */
/* We can assume that each row is unique, and that there are 283 duplicated rows      */
/* We can INSERT distinct rows (212)                                                  */
/**************************************************************************************/
SET IDENTITY_INSERT [User] OFF
INSERT INTO [User] ( UserObjectID, IsActive , DateCreated , DateLastLogin , [Role] , SignupSource , [State] )
SELECT  DISTINCT
    JSON_VALUE( CAST( Payload AS nvarchar(max) ), '$._id."$oid"') AS UserObjectID
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.active') AS IsActive
  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.createdDate."$date"')) AS CreatedDateFormatted
  , [dbo].[FN_CalculateDateTime]( JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.lastLogin."$date"')) AS LastLoginDateFormatted
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.role') AS [Role]
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.signUpSource') AS [SignUpSource]
  , JSON_VALUE( CAST( Payload AS nvarchar(max) ) , '$.state') AS [State]
FROM @StagingJsonUser
WHERE ISJSON( CAST( Payload AS nvarchar(max) ) ) > 0



select * from [User]