--GO
--/****** Object:  StoredProcedure [dbo].[BH_SSRS_Report_BS_GastricBypass_SleeveClinicalPathway]    Script Date: 9/16/2014 10:39:23 AM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--ALTER PROCEDURE [dbo].[BH_SSRS_Report_BS_GastricBypass_SleeveClinicalPathway] (
--	@JobID INT
--	,@IClientVisitGUID VARCHAR(20) = NULL
--	,@IClientGUID VARCHAR(20) = NULL
--	,@IChartGUID VARCHAR(20) = NULL
--) AS

/*****************************************************************************************************/
/**                                B L E S S I N G   H O S P I T A L                                **/
/*****************************************************************************************************/
/**								*** I M P O R T A N T   N O T I C E ***								**/
/**=================================================================================================**/
/**	This SQL object is provided FROM Blessing Hospital as an example of our coding and there is	no	**/
/** warranty or guarantee.  No SQL code should be implemented in any environment without thorough	**/
/** examination, testing and appropriate back ups prior to implementation. The user/institution of	**/
/** this SQL object takes on full responsibility of the consequences of any implementation of this	**/
/** code and shall not hold Blessing Hospital liable for any consequences.  All modifications made	**/
/** by Blessing Hospital are the intellectual property of Blessing Hospital and should be			**/
/** referenced as such.																				**/
/**=================================================================================================**/
/**	Description: 																					**/
/**-------------------------------------------------------------------------------------------------**/
/** Created: 09/16/2014		SXA Version: 6.1		Work Item: TV-341		Author: Matt Meglan		**/
/**=================================================================================================**/
/**	Mod		WI#			Date		Pgmr		Details												**/
/**-------------------------------------------------------------------------------------------------**/
/**=================================================================================================**/
/*****************************************************************************************************/

--Testing
DECLARE @JobID INT = 2124584
DECLARE @IClientVisitGUID NUMERIC(16,0)
DECLARE @IClientGUID NUMERIC(16,0)
DECLARE @IChartGUID NUMERIC(16,0)

IF OBJECT_ID('tempdb..#temp') IS NOT NULL
	DROP TABLE #temp

SET NOCOUNT ON
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ReportVersion VARCHAR(128)

IF @JobID != 0
BEGIN
	SELECT
		@IClientVisitGUID = cv.GUID,
		@IClientGUID = cv.ClientGUID,
		@IChartGUID = cv.ChartGUID
	FROM CV3VisitListJoin_R vlj (NOLOCK)
	INNER JOIN CV3ClientVisit cv (NOLOCK)
		ON cv.GUID = vlj.ObjectGUID
	WHERE vlj.JobID = @JobID
END
ELSE
	SELECT
		@IClientVisitGUID = @IClientVisitGUID,
		@IClientGUID = @IClientGUID,
		@IChartGUID = @IChartGUID,
		@ReportVersion = 'Bariatric Surgery - Gastric Bypass/Sleeve Clinical Pathway'

DECLARE @DocumentName VARCHAR(128) = 'Bariatric Surgery - Gastric Bypass/Sleeve Clinical Pathway'
DECLARE @ClientDocumentGUID NUMERIC (16,0)

SELECT @ClientDocumentGUID = GUID
FROM dbo.CV3ClientDocumentCUR 
WHERE ClientVisitGUID = @IClientVisitGUID 
AND ClientGUID = @IClientGUID
AND ChartGuID = @IChartGUID
AND PatCareDocGUID = 9000001248202020 --Bariatric Surgery - Gastric Bypass/Sleeve Clinical Pathway

DECLARE @ObsAssociation TABLE
(
	ObsGroup		TINYINT
	,ObsLabelName	VARCHAR(128)
	,ObsReason		VARCHAR(128)
	,ObsWhen		VARCHAR(128)
	,ObsDaysBefore	VARCHAR(128)
	,ObsHoursBefore	VARCHAR(128)
	,ObsPhysician	VARCHAR(128)
	,ObsDate		VARCHAR(128)
)

--General Observations
DECLARE @DocumentDtm DATETIME = dbo.BH_ObservationNameValueConcat_Fn(@IClientVisitGUID,@IClientGUID,@IChartGUID,@DocumentName,'DNSG_BariGastricBypassDate/Time_DO')
DECLARE @OrderingPhyscian VARCHAR(1000) = dbo.BH_ObservationNameValueConcat_Fn(@IClientVisitGUID,@IClientGUID,@IChartGUID,@DocumentName,'DNSG_BariInitProvider_SO')
DECLARE @Diagnosis VARCHAR(1000) = dbo.BH_ObservationNameValueConcat_Fn(@IClientVisitGUID,@IClientGUID,@IChartGUID,@DocumentName,'DNSG_BariInitDiagnosis_SO')

--1 month Clinical Pathway
DECLARE @OtherFreeText1 VARCHAR(1000) = dbo.BH_ObservationLastValue_Fn(@IClientVisitGUID,@IClientGUID,@IChartGUID,@ClientDocumentGUID,'DNSG_BariDCFULab1Month_SO')
INSERT INTO @ObsAssociation SELECT 1, 'Prealbumin', 'DNSG_BariDCPrealbuminReason1Mon_TO', 'DNSG_BariDCPreAlFULabWhen1Month_SO', 'DNSG_BariDCPrealbuminDaysbeforeFUappt1Mon_TO', 'DNSG_BariDCPrealbuminHoursbeforeFUappt1Mon_TO', 'DNSG_BariDCPrealbuminOrderingPhys1Mon_TO', 'DNSG_BariDCPrealbuminOrderingTime1Mon_DO'
INSERT INTO @ObsAssociation SELECT 1, 'CBC','DNSG_BariDCCBCReason1Mon_TO', 'DNSG_BariDCCBCFULabWhen1Month_SO', 'DNSG_BariDCCBCDaysbeforeFUappt1Mon_TO', 'DNSG_BariDCCBCHoursbeforeFUappt1Mon_TO', 'DNSG_BariDCCBCOrderingPhys1Mon_TO', 'DNSG_BariDCCBCOrderingTime1Mon_DO'
INSERT INTO @ObsAssociation SELECT 1, 'BMP', 'DNSG_BariDBCMPReason1Mon_TO', 'DNSG_BariDCBMPFULabWhen1Month_SO', 'DNSG_BariDCBMPDaysbeforeFUappt1Mon_TO', 'DNSG_BariDCBMPHoursbeforeFUappt1Mon_TO', 'DNSG_BariDCBMPOrderingPhys1Mon_TO', 'DNSG_BariDCBMPOrderingTime1Mon_DO'
INSERT INTO @ObsAssociation SELECT 1, 'Magnesium', 'DNSG_BariDCMagReason1Mon_TO', 'DNSG_BariDCMagFULabWhen1Month_SO', 'DNSG_BariDCMagDaysbeforeFUappt1Mon_TO', 'DNSG_BariDCMagHoursbeforeFUappt1Mon_TO', 'DNSG_BariDCMagOrderingPhys1Mon_TO', 'DNSG_BariDCMagOrderingTime1Mon_DO'
INSERT INTO @ObsAssociation SELECT 1, 'Folate (serum and RBC)', 'DNSG_BariDCFolReason1Mon_TO', 'DNSG_BariDCFolateFULabWhen1Month_SO', 'DNSG_BariDCFolDaysbeforeFUappt1Mon_TO', 'DNSG_BariDCFolHoursbeforeFUappt1Mon_TO', 'DNSG_BariDCFolOrderingPhys1Mon_TO', 'DNSG_BariDCFolOrderingTime1Mon_DO'
INSERT INTO @ObsAssociation SELECT 1, 'Thiamine', 'DNSG_BariDCThiamineReason1Mon_TO', 'DNSG_BariDCThiamineFULabWhen1Month_SO', 'DNSG_BariDCThiamineDaysbeforeFUappt1Mon_TO', 'DNSG_BariDCThiamineHoursbeforeFUappt1Mon_TO', 'DNSG_BariDCThiamineOrderingPhys1Mon_TO', 'DNSG_BariDCThiamineOrderingTime1Mon_DO'
INSERT INTO @ObsAssociation SELECT 1, 'Other (Specify)' + ': ' + @OtherFreeText1, 'DNSG_BariDCOtherReason1Mon_TO', 'DNSG_BariDCOtherFULabWhen1Month_SO', 'DNSG_BariDCOtherDaysbeforeFUappt1Mon_TO', 'DNSG_BariDCOtherHoursbeforeFUappt1Mon_TO', 'DNSG_BariDCOtherOrderingPhys1Mon_TO', 'DNSG_BariDCOtherOrderingTime1Mon_DO'

--3 month Clinical Pathway
DECLARE @OtherFreeText2 VARCHAR(1000) = dbo.BH_ObservationLastValue_Fn(@IClientVisitGUID,@IClientGUID,@IChartGUID,@ClientDocumentGUID,'DNSG_BariDCFULab3Month_SO')
INSERT INTO @ObsAssociation SELECT 2, 'Albumin', 'DNSG_BariDCAlbReason3Mon_TO','DNSG_BariDCAlbuminFULabWhen3Month_SO','DNSG_BariDCAlbDaysbeforeFUappt3Mon_TO','DNSG_BariDCAlbHoursbeforeFUappt3Mon_TO','DNSG_BariDCAlbOrderingPhys3Mon_TO','DNSG_BariDCAlbOrderingTime3Mon_DO'
INSERT INTO @ObsAssociation SELECT 2, 'Prealbumin', 'DNSG_BariDCPreAlbReason3Mon_TO','DNSG_BariDCPreAlFULabWhen3Month_SO','DNSG_BariDCPreAlbDaysbeforeFUappt3Mon_TO','DNSG_BariDCPreAlbHoursbeforeFUappt3Mon_TO','DNSG_BariDCPrealbuminOrderingPhys3Mon_TO','DNSG_BariDCPreAlbOrderingTime3Mon_DO'
INSERT INTO @ObsAssociation SELECT 2, 'Folate (serum and RBC)', 'DNSG_BariDCFolReason3Mon_TO','DNSG_BariDCFolateFULabWhen3Month_SO','DNSG_BariDCFolDaysbeforeFUappt3Mon_TO','DNSG_BariDCFolHoursbeforeFUappt3Mon_TO','DNSG_BariDCFolOrderingPhys3Mon_TO','DNSG_BariDCFolOrderingTime3Mon_DO'
INSERT INTO @ObsAssociation SELECT 2, 'Other (Specify)' + ': ' + @OtherFreeText2, 'DNSG_BariDCOtherReason3Mon_TO','DNSG_BariDCOtherFULabWhen3Month_SO','DNSG_BariDCOtherDaysbeforeFUappt3Mon_TO','DNSG_BariDCOtherHoursbeforeFUappt3Mon_TO','DNSG_BariDCOtherOrderingPhys3Mon_TO','DNSG_BariDCOtherOrderingTime3Mon_DO'

--6 month Clinical Pathway
DECLARE @OtherFreeText3 VARCHAR(1000) = dbo.BH_ObservationLastValue_Fn(@IClientVisitGUID,@IClientGUID,@IChartGUID,@ClientDocumentGUID,'DNSG_BariDCFULab6Month_SO')
INSERT INTO @ObsAssociation SELECT 3, 'Lipid Profile', 'DNSG_BariDCLipidsReason6Mon_TO','DNSG_BariDCLipidFULabWhen6Month_SO','DNSG_BariDCLipidsDaysbeforeFUappt6Mon_TO','DNSG_BariDCLipidsHoursbeforeFUappt6Mon_TO','DNSG_BariDCLipidsOrderingPhys6Mon_TO','DNSG_BariDCLipidsOrderingTime6Mon_DO'
INSERT INTO @ObsAssociation SELECT 3, 'Folate, serum and RBC','DNSG_BariDCFolReason6Mon_TO','DNSG_BariDCFolateFULabWhen6Month_SO','DNSG_BariDCFolDaysbeforeFUappt6Mon_TO','DNSG_BariDCFolHoursbeforeFUappt6Mon_TO','DNSG_BariDCFolOrderingPhys6Mon_TO','DNSG_BariDCFolOrderingTime6Mon_DO'
INSERT INTO @ObsAssociation SELECT 3, 'Prealbumin', 'DNSG_BariDCPrealbuminReason6Mon_TO','DNSG_BariDCPreAlFULabWhen6Month_SO','DNSG_BariDCPreAlbDaysbeforeFUappt6Mon_TO','DNSG_BariDCPreAlbHoursbeforeFUappt6Mon_TO','DNSG_BariDCPrealbuminOrderingPhys6Mon_TO','DNSG_BariDCPreAlbOrderingTime6Mon_DO'
INSERT INTO @ObsAssociation SELECT 3, 'Albumin', 'DNSG_BariDCAlbReason6Mon_TO','DNSG_BariDCAlbuminFULabWhen6Month_SO','DNSG_BariDCAlbDaysbeforeFUappt6Mon_TO','DNSG_BariDCAlbHoursbeforeFUappt6Mon_TO','DNSG_BariDCAlbOrderingPhys6Mon_TO','DNSG_BariDCAlbOrderingTime6Mon_DO'
INSERT INTO @ObsAssociation SELECT 3, 'Iron Panel', 'DNSG_BariDCIronReason6Mon_TO','DNSG_BariDCIronFULabWhen6Month_SO','DNSG_BariDCIronDaysbeforeFUappt6Mon_TO','DNSG_BariDCIronHoursbeforeFUappt6Mon_TO','DNSG_BariDCIronOrderingPhys6Mon_TO','DNSG_BariDCIronOrderingTime6Mon_DO'
INSERT INTO @ObsAssociation SELECT 3, 'HgA1C', 'DNSG_BariDCHgA1CReason6Mon_TO','DNSG_BariDCHgA1CFULabWhen6Month_SO','DNSG_BariDCHgA1CDaysbeforeFUappt6Mon_TO','DNSG_BariDCHgA1CHoursbeforeFUappt6Mon_TO','DNSG_BariDCHgA1COrderingPhys6Mon_TO','DNSG_BariDCHgA1COrderingTime6Mon_DO'
INSERT INTO @ObsAssociation SELECT 3, 'Other (Specify)' + ': ' + @OtherFreeText3,'DNSG_BariDCOtherReason6Mon_TO','DNSG_BariDCOtherFULabWhen6Month_SO','DNSG_BariDCOtherDaysbeforeFUappt6Mon_TO','DNSG_BariDCOtherHoursbeforeFUappt6Mon_TO','DNSG_BariDCOtherOrderingPhys6Mon_TO','DNSG_BariDCOtherOrderingTime6Mon_DO'

--12 month Clinical Pathway
DECLARE @OtherFreeText4 VARCHAR(1000) = dbo.BH_ObservationLastValue_Fn(@IClientVisitGUID,@IClientGUID,@IChartGUID,@ClientDocumentGUID,'OtherDiscType')
INSERT INTO @ObsAssociation SELECT 4, 'Iron Panel', 'DNSG_BariDCIronReason12Mon_TO','DNSG_BariDCIronFULabWhen12Month_SO','DNSG_BariDCIronDaysbeforeFUappt12Mon_TO','DNSG_BariDCIronHoursbeforeFUappt12Mon_TO','DNSG_BariDCIronOrderingPhys12Mon_TO','DNSG_BariDCIronOrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'B-12','DNSG_BariDCB12Reason12Mon_TO','DNSG_BariDCB12FULabWhen12Month_SO','DNSG_BariDCB12DaysbeforeFUappt12Mon_TO','DNSG_BariDCB12HoursbeforeFUappt12Mon_TO','DNSG_BariDCB12OrderingPhys12Mon_TO','DNSG_BariDCB12OrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'Vitamin D', 'DNSG_BariDCVitDReason12Mon_TO','DNSG_BariDCVitDFULabWhen12Month_SO','DNSG_BariDCVitDDaysbeforeFUappt12Mon_TO','DNSG_BariDCVitDHoursbeforeFUappt12Mon_TO','DNSG_BariDCVitDOrderingPhys12Mon_TO','DNSG_BariDCVitDOrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'Folate, serum and RBC', 'DNSG_BariDCFolateFULabWhen12Month_SO','DNSG_BariDCFolateFULabWhen12Month_SO','DNSG_BariDCFolDaysbeforeFUappt12Mon_TO','DNSG_BariDCFolHoursbeforeFUappt12Mon_TO','DNSG_BariDCFolOrderingPhys12Mon_TO','DNSG_BariDCFolOrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'Magnesium', 'DNSG_BariDCMagReason12Mon_TO','DNSG_BariDCMagFULabWhen12Month_SO','DNSG_BariDCMagDaysbeforeFUappt12Mon_TO','DNSG_BariDCMagHoursbeforeFUappt12Mon_TO','DNSG_BariDCMagOrderingPhys12Mon_TO','DNSG_BariDCMagOrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'Albumin', 'DNSG_BariDCAlbReason12Mon_TO','DNSG_BariDCAlbuminFULabWhen12Month_SO','DNSG_BariDCAlbDaysbeforeFUappt12Mon_TO','DNSG_BariDCAlbHoursbeforeFUappt12Mon_TO','DNSG_BariDCAlbOrderingPhys12Mon_TO','DNSG_BariDCAlbOrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'CBC', 'DNSG_BariDCCBCReason12Mon_TO','DNSG_BariDCCBCFULabWhen12Month_SO','DNSG_BariDCCBCDaysbeforeFUappt12Mon_TO','DNSG_BariDCCBCHoursbeforeFUappt12Mon_TO','DNSG_BariDCCBCOrderingPhys12Mon_TO','DNSG_BariDCCBCOrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'CMP', 'DNSG_BariDCCMPReason12Mon_TO','DNSG_BariDCCMPFULabWhen12Month_SO','DNSG_BariDCCMPDaysbeforeFUappt12Mon_TO','DNSG_BariDCCMPHoursbeforeFUappt12Mon_TO','DNSG_BariDCCMPOrderingPhys12Mon_TO','DNSG_BariDCCMPOrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'Thiamine', 'DNSG_BariDCThiamineReason12Mon_TO','DNSG_BariDCThiamineFULabWhen12Month_SO','DNSG_BariDCThiamineDaysbeforeFUappt12Mon_TO','DNSG_BariDCThiamineHoursbeforeFUappt12Mon_TO','DNSG_BariDCThiamineOrderingPhys12Mon_TO','DNSG_BariDCThiamineOrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'HgA1C', 'DNSG_BariDCHgA1CReason12Mon_TO','DNSG_BariDCHgA1CFULabWhen12Month_SO','DNSG_BariDCHgA1CDaysbeforeFUappt12Mon_TO','DNSG_BariDCHgA1CHoursbeforeFUappt12Mon_TO','DNSG_BariDCHgA1COrderingPhys12Mon_TO','DNSG_BariDCHgA1COrderingTime12Mon_DO'
INSERT INTO @ObsAssociation SELECT 4, 'Other (Specify)' + ': ' + @OtherFreeText4,'DNSG_BariDCOtherReason12Mon_TO','DNSG_BariDCOtherFULabWhen12Month_SO','DNSG_BariDCOtherDaysbeforeFUappt12Mon_TO','DNSG_BariDCOtherHoursbeforeFUappt12Mon_TO','DNSG_BariDCOtherOrderingPhys12Mon_TO','DNSG_BariDCOtherOrderingTime12Mon_DO'


SELECT
	cv.GUID AS 'ClientVisitGUID'
	,cv.ChartGUID
	,cv.ClientGUID
	,cd.GUID AS 'ClientDocumentGUID'
	,oei.DisplaySequence
	,CASE WHEN oflv.SortSeqNum = 11 THEN 'OtherDiscType' ELSE dbo.BH_ValidLengthString_Fn(ocmi.Name,128) END ObsName
	,CASE
	 WHEN oflv.Value IS NULL THEN
		dbo.BH_ValidLengthString_Fn(o.ValueText,8000)	 
	 ELSE
		dbo.BH_ValidLengthString_Fn(oflv.Value,8000)
	 END ValueText
INTO #temp
FROM
	dbo.CV3ClientVisit cv (NOLOCK)
	INNER JOIN dbo.CV3ClientDocument cd (NOLOCK)
		ON (cv.GUID = cd.ClientVisitGUID
		AND cv.ClientGUID = cd.ClientGUID
		AND cv.ChartGUID = cd.ChartGUID
		AND cd.PatCareDocGUID = 9000001248202020) --Bariatric Surgery - Gastric Bypass/Sleeve Clinical Pathway
	INNER JOIN dbo.CV3ObservationDocument od (NOLOCK)
		ON (cd.GUID = od.OwnerGUID
		AND od.Active = 1)
	INNER JOIN dbo.CV3Observation o (NOLOCK)
		ON (od.ObservationGUID = o.GUID)
	INNER JOIN dbo.CV3ObsCatalogMasterItem ocmi (NOLOCK)
		ON (od.ObsMasterItemGUID = ocmi.GUID)
	LEFT OUTER JOIN dbo.CV3ObservationEntryItem oei (NOLOCK)
		ON (od.ParameterGUID = oei.GUID)
	LEFT OUTER JOIN dbo.SCMObsFSListValues oflv (NOLOCK)
		ON (od.ObservationDocumentGUID = oflv.ParentGUID
		AND cd.ClientGUID = oflv.ClientGUID)
WHERE
	cv.GUID = @IClientVisitGUID
	AND cv.ClientGUID = @IClientGUID
	AND cv.ChartGUID = @IChartGUID
	AND (oflv.Value IS NOT NULL	OR o.ValueText IS NOT NULL)
ORDER BY oei.DisplaySequence ASC

--SELECT * FROM #temp

SELECT
	@DocumentDtm AS 'Document Date Time'
	,@DocumentName AS 'Document Name'
	,@OrderingPhyscian AS 'Ordering Physcian'
	,@Diagnosis AS 'Diagnosis'
	,COALESCE(t.DisplaySequence, t2.DisplaySequence, t3.DisplaySequence, t4.DisplaySequence, t5.DisplaySequence, t6.DisplaySequence) AS DisplaySequence
	,oa.ObsGroup
	,oa.ObsLabelName
	,COALESCE(t.ValueText, t2.ValueText, t3.ValueText, t4.ValueText, t5.ValueText,t6.ValueText) AS 'LabelNull'
	,t.ValueText AS 'Reason'
	,t2.ValueText AS 'When'
	,t3.ValueText AS 'Days before follow-up appointment'
	,t4.ValueText AS 'Hours before follow-up appointment'
	,t5.ValueText AS 'Ordering PHysician'
	,t6.ValueText AS 'Ordering Date'
FROM @ObsAssociation oa
LEFT JOIN #temp t
	ON oa.ObsReason = t.ObsName
LEFT JOIN #temp t2
	ON oa.ObsWhen = t2.ObsName
	AND t2.ValueText NOT IN ('Days', 'Hours')
LEFT JOIN #temp t3
	ON oa.ObsDaysBefore = t3.ObsName
LEFT JOIN #temp t4
	ON oa.ObsHoursBefore = t4.ObsName
LEFT JOIN #temp t5
	ON oa.ObsPhysician = t5.ObsName
LEFT JOIN #temp t6
	ON oa.ObsDate = t6.ObsName 
WHERE 
	t.ValueText IS NOT NULL
	OR t2.ValueText IS NOT NULL
	OR t3.ValueText IS NOT NULL
	OR t4.ValueText IS NOT NULL
	OR t5.ValueText IS NOT NULL
	OR t6.ValueText IS NOT NULL
ORDER BY oa.ObsGroup, t.DisplaySequence

/* End of Stored Procedure */