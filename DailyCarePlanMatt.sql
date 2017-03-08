--USE [TEST]
--GO
--/****** Object:  StoredProcedure [dbo].[BH_SSRS_Report_DailyCarePlan_Sp]    Script Date: 8/15/2014 10:28:37 AM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--ALTER PROCEDURE [dbo].[BH_SSRS_Report_DailyCarePlan_Sp] (
--	@JobID		INT
--,@CVGUID	VARCHAR(20) = NULL
--) AS

/*****************************************************************************************************/
/**                                B L E S S I N G   H O S P I T A L                                **/
/*****************************************************************************************************/
/**								*** I M P O R T A N T   N O T I C E ***								**/
/**=================================================================================================**/
/**	This SQL object is provided from Blessing Hospital as an example of our coding and there is	no	**/
/** warranty or guarantee.  No SQL code should be implemented in any environment without thorough	**/
/** examination, testing and appropriate back ups prior to implementation. The user/institution of	**/
/** this SQL object takes on full responsibility of the consequences of any implementation of this	**/
/** code and shall not hold Blessing Hospital liable for any consequences.  All modifications made	**/
/** by Blessing Hospital are the intellectual property of Blessing Hospital and should be			**/
/** referenced as such.																				**/
/**=================================================================================================**/
/**	Description:																					**/
/**-------------------------------------------------------------------------------------------------**/
/**	This stored procedure is used to return facility information used by SSRS reports.				**/
/**-------------------------------------------------------------------------------------------------**/
/** Created: 08/14/2010		SXA Version: 5.5		Work Item: TK1			Author: Ariel Mears		**/
/**=================================================================================================**/
/**	Mod		WI#				Date		Pgmr		Details											**/
/**-------------------------------------------------------------------------------------------------**/
/**=================================================================================================**/
/*****************************************************************************************************/

SET NOCOUNT ON

DECLARE @JobID INT SET @JobID = 2124157
DECLARE @CVGUID varchar(20) = '9000191339700270'

IF OBJECT_ID('tempdb..#OrderTbl') IS NOT NULL 
	DROP TABLE #OrderTbl
IF OBJECT_ID('tempdb..#CodeStatustbl') IS NOT NULL 
	DROP TABLE #CodeStatustbl

DECLARE @ClientGUID NUMERIC(16,0)
DECLARE @ClientVisitGUID NUMERIC(16,0)
DECLARE @ChartGUID NUMERIC(16,0)
DECLARE @HealthIssue VARCHAR(8000) 
DECLARE @ReportVersion VARCHAR(100)
DECLARE @HealthCarePOA VARCHAR(MAX)
DECLARE @HealthInfoShare VARCHAR(MAX)
DECLARE @HealthInfoShare1 VARCHAR(MAX)
DECLARE @HealthInfoShare2 VARCHAR(MAX)
DECLARE @HealthInfoShare3 VARCHAR(MAX)
DECLARE @HealthInfoShare4 VARCHAR(MAX)
DECLARE @HealthInfoShare5 VARCHAR(MAX)
DECLARE @HealthInfoShare6 VARCHAR(MAX)
DECLARE @HealthInfoShare7 VARCHAR(MAX)

SELECT @ReportVersion = dbo.BH_ReportVersion_Fn(@JobID)  

IF (@JobID != 0)
BEGIN
SELECT 
	 @ClientGUID = cv.ClientGUID
	,@ClientVisitGUID= cv.GUID
	,@ChartGUID = cv.ChartGUID 
FROM
	dbo.CV3VisitListJoin_R vlj (NOLOCK)
	INNER JOIN dbo.CV3CLientVisit cv (NOLOCK)
		ON (vlj.ObjectGUID = cv.GUID)
WHERE
	vlj.JobID = @JobID
END

IF (@JobID = 0)
BEGIN
SELECT 
	 @ClientGUID = cv.ClientGUID
	,@ClientVisitGUID= cv.GUID
	,@ChartGUID = cv.ChartGUID 
	,@ReportVersion = 'Daily Care Plan'
FROM
	dbo.CV3CLientVisit cv (NOLOCK)
WHERE
	cv.GUID = CONVERT(NUMERIC(16,0),@CVGUID)
END
 
; WITH Codestatus AS ( 
	SELECT
		--ClientGuid, name,  ,significantdtm
		 o.ClientGUID
		,o.ClientVisitGUID
		,o.ChartGUID
		,o.Name
		,ISNULL(o.SummaryLine,'') SummaryLine
		,o.OrderStatusCode
		,o.SignificantDtm
		,RowNum = ROW_NUMBER() OVER (PARTITION BY ClientGUID, OrderCatalogMasterItemGUID ORDER BY o.SignificantDtm DESC)
	FROM
		dbo.CV3Order o (NOLOCK)
		LEFT OUTER JOIN dbo.BH_SSRS_DailyCarePlanOrderSetExclusion_Tbl ose (NOLOCK)
			ON (o.OrderSetName = ose.OrderSetName)
		LEFT OUTER JOIN dbo.BH_SSRS_DailyCarePlanTerms_Tbl pt (NOLOCK)
			ON (o.Name = pt.FromTerm)			
--Start of /A									
		INNER JOIN dbo.CV3OrderCatalogItem oci
			ON oci.OrderGUID = o.GUID 
			AND oci.GUID <> 9000003772000720 --'Sodium chloride 0.9!% INJ%'
		INNER JOIN dbo.CV3CatalogClassTypeValue ctv
			ON o.OrderCatalogMasterItemGUID = ctv.CatalogMasterGUID
			AND ctv.Value NOT IN ('Diet', 'Diet_Order', 'Diet ST')    --/A
--End of /A
	WHERE
		o.Name IN ('Code Status','Code Status Clarification')
		AND o.Active = 1
		AND o.Status = 'Active'
		AND o.ClientGUID = @ClientGUID
		AND o.ClientVisitGUID = @ClientVisitGUID
		AND o.ChartGUID = @ChartGUID									
--		AND o.OrderStatusCode = 'AUA1'									--/A
		AND o.OrderStatusCode IN ('AUA1', 'PEND', 'AVACT')				--/A
		AND ose.OrderSetName IS NULL
)


--select * from dbo.CV3OrderStatus
--SELECT * FROM dbo.CV3CatalogItemName Where Name LIKE 'Sodium chloride 0.9!% INJ%' ESCAPE '!'

--select * from dbo.CV3OrderCatalogItem Where Name Like 'Sodium chloride 0.9!% INJ%' ESCAPE '!'  --Order Catlog Item 9000003772000720
--select * from dbo.CV3OrderCatalogItem Where Name Like '%Diet%' ESCAPE '!'  --Order Catlog Item 9000003772000720
--select * from dbo.CV3OrderCatalogMasterItem
--select * from dbo.CV3CatalogClassTypeValue WHERE Value LIKE '%Diet%'

SELECT
	a.* 
INTO
	#CodeStatustbl
FROM
	Codestatus a
	LEFT OUTER JOIN CodeStatus B
		ON (a.ClientGUID = b.ClientGUID
		AND a.ClientVisitGUID = b.ClientVisitGUID
		AND a.ChartGUID = b.ChartGUID
		AND b.Name = 'Code Status'
		AND a.Name = 'Code Status Clarification')
WHERE
	a.RowNum = 1 
	AND (CHARINDEX(b.SummaryLine,a.SummaryLine) = 0 
	OR CHARINDEX(b.SummaryLine,a.SummaryLine) IS NULL)

/**  Get Health Issue information for Report **/

SET @HealthIssue = ''
SELECT
	@HealthIssue =  @HealthIssue +  hd.TypeCode + ':   '+ COALESCE(hd.Description,hd.Text,hd.ShortName) + CHAR(10)
FROM
	dbo.CV3HealthIssueDeclaration hd (NOLOCK)
WHERE
	hd.ClientGUID = @ClientGUID
	AND hd.ClientVisitGUID = @ClientVisitGUID
	AND hd.Status = 'Active'
	AND hd.TypeCode IN ('Principal Dx','Chief Complaint')

SELECT @HealthIssue = CASE WHEN LEN(@HealthIssue) > 1 THEN LEFT(@HealthIssue,LEN(@HealthIssue) - 1) ELSE @HealthIssue END

; WITH OrderTbl as (
	SELECT DISTINCT
		 o.ClientGUID
		,o.ClientVisitGUID
		,o.ChartGUID
		,orc.Code
		,orc.SortCode
		,ISNULL(pt.ToTerm,ocmi.Name) Name
		--, o.Name
		,o.SignificantDtm 
		,o.OrderStatusCode
		,os.Description
		,ISNULL((SELECT ISNULL(me.DosageLow,me.DosageHigh) + ' '+  UOM
		  FROM dbo.CV3MedicationExtension me (NOLOCK)
		  WHERE me.GUID = o.GUID),'') + CASE WHEN pt.ToTerm IS NOT NULL THEN char(13) + char(10) + pt.ToTerm ELSE '' END SummaryLine
		,ISNULL(o.FrequencyCode,
			(SELECT oai.FreqSummaryLine
			 FROM dbo.CV3OrderAddnlInfo oai (NOLOCK)
			 WHERE oai.GUID = o.GUID)
		 ) Frequency
		,(SELECT CASE WHEN IsPRN = 0 THEN NULL ELSE 'PRN' END
		  FROM dbo.CV3OrderAddnlInfo oai (NOLOCK)
		  WHERE oai.GUID = o.GUID) PRN
		--,CodeRowNum=ROW_NUMBER() OVER(PARTITION BY orc.code   ORDER BY orc.Code ASC)
		--, ColNum=(ROW_NUMBER() OVER(PARTITION BY orc.code  ORDER BY orc.SortCode,o.significantdtm ASC)-1) % 2
	FROM
		dbo.CV3Order o (NOLOCK)
		INNER JOIN dbo.CV3OrderCatalogMasterItem ocmi (NOLOCK)
			ON	(o.OrderCatalogMasterItemGUID = ocmi.GUID
			AND o.ClientGUID = @ClientGUID
			AND o.ClientVisitGUID = @ClientVisitGUID
			AND o.ChartGUID = @ChartGUID)
		INNER JOIN dbo.CV3OrderReviewCategory orc (NOLOCK)
			ON (ocmi.OrderReviewCategoryGUID = orc.GUID
			AND orc.Code='Pharmacy')
		INNER JOIN dbo.CV3OrderStatus os (NOLOCK)
			ON (o.OrderStatusCode = os.Code
--			AND os.Code = 'AUA1'								--/A
			AND os.Code IN ('AUA1', 'PEND','AVACT'))			--/A
		LEFT OUTER JOIN dbo.BH_SSRS_DailyCarePlanOrderSetExclusion_Tbl ose (NOLOCK)
			ON (o.OrderSetName = ose.OrderSetName)
		LEFT OUTER JOIN dbo.BH_SSRS_DailyCarePlanTerms_Tbl pt (NOLOCK)
			ON (o.Name = pt.FromTerm)
	WHERE
		ose.OrderSetName IS NULL
	UNION
	SELECT DISTINCT
		 o.ClientGUID
		,o.ClientVisitGUID
		,o.ChartGUID
		,orc.Code
		,orc.SortCode
		,ocmi.Name
		--, o.Name
		,o.SignificantDtm 
		,o.OrderStatusCode
		,os.Description
		,ISNULL(o.SummaryLine,'') /*(SELECT ISNULL(me.DosageLow,me.DosageHigh) + ' '+  UOM
		  FROM dbo.CV3MedicationExtension me (NOLOCK)
		  WHERE me.GUID = o.GUID)*/ 
		  + CASE WHEN pt.ToTerm IS NOT NULL THEN char(13) + char(10) + pt.ToTerm ELSE '' END
		  SummaryLine
		,ISNULL(o.FrequencyCode,
			(SELECT oai.FreqSummaryLine
			 FROM dbo.CV3OrderAddnlInfo oai (NOLOCK)
			 WHERE oai.GUID = o.GUID)
		 ) Frequency
		,(SELECT CASE WHEN IsPRN = 0 THEN NULL ELSE 'PRN' END
		  FROM dbo.CV3OrderAddnlInfo oai (NOLOCK)
		  WHERE oai.GUID = o.GUID) PRN
		--,CodeRowNum=ROW_NUMBER() OVER(PARTITION BY orc.code   ORDER BY orc.Code ASC)
		--, ColNum=(ROW_NUMBER() OVER(PARTITION BY orc.code  ORDER BY orc.SortCode,o.significantdtm ASC)-1) % 2
	FROM
		dbo.CV3Order o (NOLOCK)
		INNER JOIN dbo.CV3OrderCatalogMasterItem ocmi (NOLOCK)
			ON	(o.OrderCatalogMasterItemGUID = ocmi.GUID
			AND o.ClientGUID = @ClientGUID
			AND o.ClientVisitGUID = @ClientVisitGUID
			AND o.ChartGUID = @ChartGUID)
		INNER JOIN dbo.CV3OrderReviewCategory orc (NOLOCK)
			ON (ocmi.OrderReviewCategoryGUID = orc.GUID
			AND orc.Code != 'Pharmacy')
		INNER JOIN dbo.CV3OrderStatus os (NOLOCK)
			ON (o.OrderStatusCode = os.Code
--			AND os.Code IN ('AUA1','PCOL','AUA10'))									--/A
			AND os.Code IN ('AUA1','PCOL','AUA10','PEND','AVACT'))					--/A
		INNER JOIN dbo.CV3CatalogClassTypeValue ctv (NOLOCK)
			ON (ocmi.GUID = ctv.CatalogMasterGUID
			AND ctv.Value = 'BH Daily Care Plan')
			AND ctv.Value NOT IN ('Diet', 'Diet_Order', 'Diet ST')					--/A
		LEFT OUTER JOIN dbo.BH_SSRS_DailyCarePlanOrderSetExclusion_Tbl ose (NOLOCK)
			ON (o.OrderSetName = ose.OrderSetName)
		LEFT OUTER JOIN dbo.BH_SSRS_DailyCarePlanTerms_Tbl pt (NOLOCK)
			ON (o.Name = pt.FromTerm)
	WHERE
		ose.OrderSetName IS NULL
	UNION
	SELECT 
		 o.ClientGUID
		,o.ClientVisitGUID
		,o.ChartGUID
		,'Code Status'
		,-1
		,o.Name
		,o.SignificantDtm 
		,o.OrderStatusCode
		,NULL
		,ISNULL(o.SummaryLine,'') + CASE WHEN pt.ToTerm IS NOT NULL THEN char(13) + char(10) + pt.ToTerm ELSE '' END SummaryLine
		,NULL Frequency
		,NULL PRN
	FROM
		#CodeStatustbl o
		LEFT OUTER JOIN dbo.BH_SSRS_DailyCarePlanTerms_Tbl pt (NOLOCK)
			ON (o.Name = pt.FromTerm)
	/*UNION
	SELECT 
		 o.ClientGUID
		,o.ClientVisitGUID
		,o.ChartGUID
		,'Consulting Physician'
		,-1
		,o.Name
		,o.SignificantDtm 
		,o.OrderStatusCode
		,NULL
		,o.SummaryLine
		,NULL Frequency
		,NULL PRN
	FROM
		#CodeStatustbl o*/
)

SELECT
	 * 
	,RowNum = ROW_NUMBER() OVER(PARTITION BY Code ORDER BY SortCode,SignificantDtm ASC)
	,ColNum = (ROW_NUMBER() OVER(PARTITION BY Code ORDER BY SortCode,SignificantDtm ASC)) % 2
INTO 
	#OrderTbl
FROM
	OrderTbl
ORDER BY
	 Sortcode
	,SignificantDtm

SELECT
	 @HealthCarePOA = dbo.BH_ObservationValue_Fn(cv.GUID,cv.ClientGUID,cv.ChartGUID,cd.GUID,'DBH_AdvDirPOAName_TO')
	,@HealthInfoShare1 = dbo.BH_ObservationLastValue_Fn(cv.GUID,cv.ClientGUID,cv.ChartGUID,cd.GUID,'DBH_HippaSpouse_SO')
	,@HealthInfoShare2 = dbo.BH_ObservationLastValue_Fn(cv.GUID,cv.ClientGUID,cv.ChartGUID,cd.GUID,'DBH_HippaChild_SO')
	,@HealthInfoShare3 = dbo.BH_ObservationLastValue_Fn(cv.GUID,cv.ClientGUID,cv.ChartGUID,cd.GUID,'DBH_HippaParent_SO')
	,@HealthInfoShare4 = dbo.BH_ObservationLastValue_Fn(cv.GUID,cv.ClientGUID,cv.ChartGUID,cd.GUID,'DBH_HippaSibling_SO')
	,@HealthInfoShare5 = dbo.BH_ObservationLastValue_Fn(cv.GUID,cv.ClientGUID,cv.ChartGUID,cd.GUID,'DBH_HippaFriend_SO')
	,@HealthInfoShare6 = dbo.BH_ObservationLastValue_Fn(cv.GUID,cv.ClientGUID,cv.ChartGUID,cd.GUID,'DBH_HippaOther_SO')
FROM
	dbo.CV3ClientVisit cv (NOLOCK)
	INNER JOIN dbo.CV3ClientDocument cd (NOLOCK)
		ON (cv.GUID = cd.ClientVisitGUID
		AND cv.ClientGUID = cd.ClientGUID
		AND cv.ChartGUID = cd.ChartGUID
		AND cd.DocumentName = 'Adult Patient Profile')
WHERE
	cv.GUID = @ClientVisitGUID
	AND cv.ClientGUID = @ClientGUID
	AND cv.ChartGUID = @ChartGUID

SELECT
	@HealthInfoShare = 
		CASE WHEN @HealthInfoShare1 IS NOT NULL THEN 'Spouse/Partner: ' + @HealthInfoShare1 + CHAR(13) + CHAR(10) ELSE '' END +
		CASE WHEN @HealthInfoShare2 IS NOT NULL THEN 'Child(ren): ' + @HealthInfoShare2 + CHAR(13) + CHAR(10) ELSE '' END +
		CASE WHEN @HealthInfoShare3 IS NOT NULL THEN 'Parent(s): ' + @HealthInfoShare3 + CHAR(13) + CHAR(10) ELSE '' END +
		CASE WHEN @HealthInfoShare4 IS NOT NULL THEN 'Sibling(s): ' + @HealthInfoShare4 + CHAR(13) + CHAR(10) ELSE '' END +
		CASE WHEN @HealthInfoShare5 IS NOT NULL THEN 'Friend(s): ' + @HealthInfoShare5 + CHAR(13) + CHAR(10) ELSE '' END +
		CASE WHEN @HealthInfoShare6 IS NOT NULL THEN 'Other: ' + @HealthInfoShare6 ELSE '' END 

SELECT
	  c1.ClientGUID
	 ,c1.ClientVisitGUID
	,c1.ChartGUID
	,@HealthIssue HealthIssue
	,dbo.BH_Allergies_Fn(@ClientGUID) Allergies
	,@ReportVersion prtVersion
	,dbo.BH_PatientFacility_Fn(@ClientVisitGUID,@ClientGUID) PatientFacility
	,@HealthCarePOA HealthCarePOA
	,@HealthInfoShare HealthInfoShare
	,REPLACE(c1.Code,'Pharmacy','Pharmacy (PRN means "As Needed")') Code
	,c1.SortCode
	,c1.Name OrderName1
	,c1.SummaryLine SummaryLine1
	,c1.Frequency Frequency1
	,c1.PRN PRN1
	,c2.Name OrderName2
	,c2.SummaryLine SummaryLine2
	,c2.Frequency Frequency2
	,c2.PRN PRN2
	,C2.RowNum
FROM
	#OrderTbl c1 
	LEFT JOIN #OrderTbl c2
		ON (c1.Code = c2.Code 
		AND c2.ColNum = 0
		AND c1.RowNum + c1.ColNum = c2.RowNum)
WHERE
	c1.ColNum = 1

--SELECT * FROM dbo.CV3HomeMedicationStatusHistory WHERE ClientGUID = 9000038684100200 AND ClientVisitGUID = 9000212397200270
--EXEC BH_MLM_HomeMedSummary_Sp 9000212397200270, 9000038684100200
--Exec BH_SSRS_Report_HomeMedSummary_Sp

/* END OF STORED PROCEDURE */