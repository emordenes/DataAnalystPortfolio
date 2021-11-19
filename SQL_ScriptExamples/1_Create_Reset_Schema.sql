USE [FetchRewards]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/***********************************/
/* DROP table schemas              */
/***********************************/
IF EXISTS (SELECT * FROM sysobjects WHERE NAME='ReceiptItem' AND xtype='U')
	DROP TABLE  [dbo].[ReceiptItem]

IF EXISTS (SELECT * FROM sysobjects WHERE NAME='Receipt' AND xtype='U')
	DROP TABLE  [dbo].[Receipt]

IF EXISTS (SELECT * FROM sysobjects WHERE NAME='Brand' AND xtype='U')
	DROP TABLE  [dbo].[Brand]

IF EXISTS (SELECT * FROM sysobjects WHERE NAME='User' AND xtype='U')
	DROP TABLE  [dbo].[User]


IF EXISTS (SELECT * FROM   sys.objects WHERE  object_id = OBJECT_ID(N'[dbo].[FN_CalculateDateTime]') AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
	DROP FUNCTION [dbo].[FN_CalculateDateTime]

/***********************************/
/* Create User table schema        */
/***********************************/

CREATE TABLE [dbo].[User](
	[UserID] [int] IDENTITY(1,1) NOT NULL,
	[UserObjectID] [varchar](30) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[DateCreated] [datetime] NOT NULL,
	[DateLastLogin] [datetime] NULL,
	[Role] [varchar](20) NOT NULL,
	[SignupSource] [varchar](20) NULL,
	[State] [varchar](10) NULL,
	CONSTRAINT [PK_User] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_UserObjectID] ON [dbo].[User]
(
	[UserObjectID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/***********************************/
/* Create Brand table schema       */
/***********************************/
CREATE TABLE [dbo].[Brand](
	[BrandID] [int] IDENTITY(1,1) NOT NULL,
	[BrandObjectID] [varchar](30) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[BarCode] [varchar](20) NOT NULL,
	[BrandCode] [varchar](100) NULL,
	[Category] [varchar](50) NULL,
	[CategoryCode] [varchar](30) NULL,
	[CpgObjectID] [varchar](30) NOT NULL,
	[CpgRef] [varchar](10) NOT NULL,
	[IsTopBrand] [bit] NULL,
	CONSTRAINT [PK_Brand] PRIMARY KEY CLUSTERED 
(
	[BrandID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_BrandObjectID] ON [dbo].[Brand]
(
	[BrandObjectID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_Brand_BarCode_BrandCode] ON [dbo].[Brand]
(
	[BarCode] ASC,
	[BrandCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/***********************************/
/* Create Receipt table schema     */
/***********************************/
CREATE TABLE [dbo].[Receipt](
	[ReceiptID] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptObjectID] [varchar](30) NOT NULL,
	[BonusPointsEarned] [int] NULL,
	[BonusPointsEarnedReason] [nvarchar](500) NULL,
	[DateCreated] [datetime] NOT NULL,
	[DateScanned] [datetime] NOT NULL,
	[DateFinished] [datetime] NULL,
	[DateModified] [datetime] NOT NULL,
	[DatePointsAwarded] [datetime] NULL,
	[DatePurchased] [datetime] NULL,
	[PointsEarned] [decimal](10, 4) NULL,
	[PurchasedItemCount] [int] NULL,
	[RewardReceiptStatus] [varchar](10) NOT NULL,
	[TotalSpent] [decimal](10, 2) NULL,
	[UserObjectID] [varchar](30) NOT NULL,
	CONSTRAINT [PK_Receipt] PRIMARY KEY CLUSTERED 
(
	[ReceiptID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Receipt]  WITH NOCHECK ADD  CONSTRAINT [FK_Receipt_User_ByUserObjectID] FOREIGN KEY([UserObjectID])
REFERENCES [dbo].[User] ([UserObjectID])
GO

ALTER TABLE [dbo].[Receipt] NOCHECK CONSTRAINT [FK_Receipt_User_ByUserObjectID]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_ReceiptObjectID] ON [dbo].[Receipt]
(
	[ReceiptObjectID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO



/***********************************/
/* Create ReceiptItem table schema */
/***********************************/
CREATE TABLE [dbo].[ReceiptItem](
	[ReceiptItemID] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptObjectID] [varchar](30) NOT NULL,
	[BarCode] [varchar](20) NULL,
	[BrandCode] [varchar](100) NULL,
	[Description] [nvarchar](max) NULL,
	[DiscountedItemPrice] [decimal](10, 2) NULL,
	[FinalPrice] [decimal](10, 2) NULL,
	[ItemPrice] [decimal](10, 2) NULL,
	[NeedFetchReview] [bit] NULL,
	[NeedsFetchReviewReason] nvarchar(max) NULL,
	[OriginalReceiptItemText] [nvarchar](max) NULL,
	[PartnerItemID] [int] NULL,
	[QuantityPurchased] [int] NULL,
	[RewardsGroup] varchar(100) NULL,
	[RewardsProductPartnerID] varchar(30) NULL,
	[PreventTargetGapPoints] bit NULL,
	[UserFlaggedBarCode] varchar(20) NULL,
	[UserFlaggedDescription] varchar(100) NULL,
	[UserFlaggedNewItem] bit NULL,
	[UserFlaggedPrice] decimal(10,2) NULL,
	[UserFlaggedQuantity] int NULL

	CONSTRAINT [PK_ReceiptItem] PRIMARY KEY CLUSTERED 
(
	[ReceiptItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ReceiptItem]  WITH NOCHECK ADD  CONSTRAINT [FK_ReceiptItem_Brand_ByBarCode_AND_BrandCode] FOREIGN KEY([BarCode], [BrandCode])
REFERENCES [dbo].[Brand] ([BarCode], [BrandCode])
GO

ALTER TABLE [dbo].[ReceiptItem] NOCHECK CONSTRAINT [FK_ReceiptItem_Brand_ByBarCode_AND_BrandCode]
GO

ALTER TABLE [dbo].[ReceiptItem]  WITH CHECK ADD  CONSTRAINT [FK_ReceiptItem_Receipt_ByReceiptObjectID] FOREIGN KEY([ReceiptObjectID])
REFERENCES [dbo].[Receipt] ([ReceiptObjectID])
GO

ALTER TABLE [dbo].[ReceiptItem] CHECK CONSTRAINT [FK_ReceiptItem_Receipt_ByReceiptObjectID]
GO



/*******************************************/
/* Create FUNCTION  [FN_CalculateDateTime] */
/*******************************************/
CREATE FUNCTION [dbo].[FN_CalculateDateTime]
(
	-- Add the parameters for the function here
	@NumericDateAsString varchar(20)
)
RETURNS datetime
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultDate datetime
	DECLARE @NumericDate bigint = CAST( @NumericDateAsString   AS bigint ) 

	-- Add the T-SQL statements to compute the return value here
   SET @ResultDate =   DATEADD(
								  MILLISECOND
								, @NumericDate / 86400000
								, (@NumericDate / 86400000) + 25567
							)

  

	-- Return the result of the function
	RETURN @ResultDate

END
GO



/***********************************/
/* Check all tables             */
/***********************************/

SELECT * FROM ReceiptItem
GO

SELECT * FROM Receipt
GO

SELECT * FROM Brand
GO

SELECT * FROM [User]
GO