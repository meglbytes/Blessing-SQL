USE [TEST]
GO
/****** Object:  StoredProcedure [dbo].[BH_SSRS_Report_DischargeOrderReferrals_Sp]    Script Date: 9/30/2014 12:51:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[BH_SSRS_Report_DischargeOrderReferrals_Sp] 
	@JobID INT
 AS

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
/**	Description: Returns followup orders from the discharge note									**/
/**-------------------------------------------------------------------------------------------------**/
/** Created: 09/09/2014	SXA Version: 6.1		Work Item: TV-2936		Author: Matt Meglan			**/
/**=================================================================================================**/
/**	Mod		WI#			Date		Pgmr		Details												**/
/**-------------------------------------------------------------------------------------------------**/
/**=================================================================================================**/
/*****************************************************************************************************/

SET NOCOUNT ON
--DECLARE @JobID INT SET @JobID = 2124678

if OBJECT_ID('tempdb..#temp') IS NOT NULL
	DROP TABLE #temp

DECLARE @ClientVisitGUID NUMERIC(16,0)
DECLARE @ChartGUID NUMERIC(16,0)
DECLARE @ClientGUID NUMERIC(16,0)

DECLARE @DocumentName VARCHAR(100) = 'Discharge Orders'
DECLARE @PatCareDocGUID	NUMERIC(16,0) = (SELECT GUID FROM dbo.CV3PatientCareDocument WHERE Name = @DocumentName)
DECLARE @ReportVersion VARCHAR(100) = [dbo].[BH_ReportVersion_Fn](@JobID)

SELECT 
	@ClientVisitGUID = cv.GUID
	,@ChartGUID = cv.ChartGUID
	,@ClientGUID = cv.ClientGUID
FROM CV3VisitListJoin_R vlj (NOLOCK) 
INNER JOIN CV3ClientVisit cv (NOLOCK) 
	ON cv.GUID = vlj.ObjectGUID
WHERE vlj.JobID = @JobID

--SET @ClientVisitGUID = 9000203392200270
--SET @ClientGUID = 9000039227800200
--SET @ChartGUID = 9000199873700170

DECLARE @DocumentDtm DATETIME
DECLARE @DocumentGUID NUMERIC(16,0)

SELECT @DocumentGUID = GUID
		,@DocumentDtm = cd.Entered
FROM dbo.CV3ClientDocument cd 
WHERE cd.ClientVisitGUID = @ClientVisitGUID
AND cd.ClientGUID = @ClientGUID
AND cd.ChartGUID = @ChartGUID
AND cd.DocumentName = @DocumentName

DECLARE @Facility VARCHAR(2) = dbo.BH_PatientFacility_Fn(@ClientVisitGUID,@ClientGUID)

DECLARE @ObsAssociation TABLE (
	Category		VARCHAR(1000)
	,OrderName		VARCHAR(1000)
	,ObsComment		VARCHAR(1000)
	,ObsPhysician	VARCHAR(1000)
	,ObsDate		VARCHAR(1000)
	,ObsExtra		VARCHAR(1000)
)

DECLARE @ObsNames TABLE (
	ObsName VARCHAR(128)
)

INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'PT Outpatient - Evaluate and Treat', 'DNSG_DCRehabPTComments_TO','DNSG_DCOrderingPhyPT_TO','DNSG_DCOrderingDatePT_DO', NULL
INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'OT Outpatient - Evaluate and Treat', 'DNSG_DCRehabOTComments_TO','DNSG_DCOrderingPhyOT_TO','DNSG_DCOrderingDateOT_DO',NULL
INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'ST Outpatient - Evaluate and Treat', 'DNSG_DCRehabSTComments_TO','DNSG_DCOrderingPhyST_TO','DNSG_DCOrderingDateST_DO',NULL
DECLARE @CardiacReasons VARCHAR(1000) = dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCCardRehabPhaseII_RO')
INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'Cardiac Rehab Phase II', @CardiacReasons,'DNSG_DCOrderingPhyCardiacRehab_TO','DNSG_DCOrderingDateCardiacRehab_DO',NULL
INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'Pulmonary Rehab', 'DNSG_DCPulmonaryRehabReason_TO','DNSG_DCOrderingPhyLabHomeVisit_TO','DNSG_DCOrderingDateLabHomeVisit_DO',NULL
INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'Lab Home Visit', 'DNSG_DCLabHomeVisitReason_TO','DNSG_DCOrderingPhyLabHomeVisit_TO','DNSG_DCOrderingDateLabHomeVisit_DO', 'DNSG_DCLabDraws_TO'
INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'Diabetic Education', 'DNSG_DCDiabeticEdReason_TO','DNSG_DCOrderingPhyDiabeticEd_TO','DNSG_DCOrderingDateDiabeticEd_DO',NULL
INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'Hospice Referral', 'DNSG_DCHospiceReferralReason_TO','DNSG_DCOrderingPhyHospiceRef_TO','DNSG_DCOrderingDateHospiceReferral_DO',NULL
INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'Outpatient Medical Nutrition Services', 'DNSG_DCOutpatientNutritionReason_TO','DNSG_DCOrderingPhyOutpatientNutrition_TO','DNSG_DCOrderingDateOutpatientNutrition_DO',NULL
DECLARE @OtherDischarge VARCHAR(1000) = dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCRehab_SO')
SELECT @OtherDischarge = SUBSTRING(@OtherDischarge, CHARINDEX('(specify):',@OtherDischarge,1)+12,LEN(@OtherDischarge) - (CHARINDEX('(specify):',@OtherDischarge,1)))
INSERT INTO @ObsAssociation SELECT 'Outpatient Discharge Referrals', 'Other: ' + @OtherDischarge, 'DNSG_DCReasonOtherRef_TO','DNSG_DCOrderingPhyOtherRef_TO','DNSG_DCOrderingDateOtherRef_DO',NULL

DECLARE @NurseServices VARCHAR(8000) = dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCHomecareVisitNurse_RO')
DECLARE @Assessment VARCHAR(8000) = 'assessment/instruction on: ' + dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCVisitNurseAssmtInst_RO')
DECLARE @WoundType VARCHAR (1000) = 'wound type: ' + dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_WoundType_TO')
DECLARE @OstomyCare VARCHAR (1000) = 'ostomoy care: ' + dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_OstomyCare_TO')
DECLARE @DrainCare VARCHAR (1000) = 'drain care: ' + dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DrainCare_TO')
INSERT INTO @ObsAssociation SELECT 'Homecare Discharge Referrals', 'Nurse',@NurseServices,NULL, NULL, NULL
DECLARE @PTServices VARCHAR(1000) = LEFT(dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCHomecarePT_RO'),18) + ', ' + dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCHomecarePTOther_TO')
INSERT INTO @ObsAssociation SELECT 'Homecare Discharge Referrals', 'PT',@PTServices,NULL, NULL, NULL
DECLARE @OTServices VARCHAR(1000) = LEFT(dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCHomecareOT_RO'),18) + ', ' + dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCHomecareOTOther_TO')
INSERT INTO @ObsAssociation SELECT 'Homecare Discharge Referrals', 'OT',@OTServices,NULL, NULL, NULL
DECLARE @STServices VARCHAR(1000) = LEFT(dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCHomecareST_RO'),18) + ', ' + dbo.BH_ObservationNameValueConcat_Fn(@ClientVisitGUID,@ClientGUID,@ChartGUID,@DocumentName, 'DNSG_DCHomecareSTOther_TO')
INSERT INTO @ObsAssociation SELECT 'Homecare Discharge Referrals', 'ST',@STServices,NULL, NULL, NULL

SELECT
	cv.GUID AS 'ClientVisitGUID'
	,cv.ChartGUID
	,cv.ClientGUID
	,cd.GUID AS 'DocumentGUID'
	,cd.CreatedWhen
	,oei.DisplaySequence
	,CASE 
		WHEN oflv.SortSeqNum = 11 THEN 'OtherDiscType' 
		ELSE dbo.BH_ValidLengthString_Fn(ocmi.Name,128) 
		END ObsName
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
		AND cd.PatCareDocGUID = @PatCareDocGUID)
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
	cv.GUID = @ClientVisitGUID
	AND cv.ClientGUID = @ClientGUID
	AND cv.ChartGUID = @ChartGUID
	AND (oflv.Value IS NOT NULL	OR o.ValueText IS NOT NULL)
ORDER BY oei.DisplaySequence ASC

--select * from #temp order by DisplaySequence

SELECT
	@ClientVisitGUID AS 'ClientVisitGUID'
	,@ClientGUID AS 'ClientGUID'
	,@ChartGUID AS 'ChartGUID'
	,@Facility AS 'Facility'
	,@ReportVersion AS 'ReportVersion'
	,@DocumentName AS 'DocumentName'
	,COALESCE(t.DisplaySequence, t2.DisplaySequence, t3.DisplaySequence, t4.DisplaySequence) AS 'DisplaySequence'
	,oa.Category
	,oa.OrderName
	,ISNULL(t.ValueText, oa.ObsComment) AS 'Reasons'
	,ISNULL(t2.ValueText, dbo.BH_OBservationValue_Fn(@ClientVisitGUID, @ClientGUID, @ChartGUID, @DocumentGUID, 'DNSG_DCCareProviders_SO')) AS 'Physician'
	,COALESCE(t3.ValueText, oa.ObsDate, LEFT(CONVERT(VARCHAR(20),@DocumentDtm,120),16)) AS 'Signed'
	,ISNULL(t4.ValueText, oa.ObsExtra) AS 'Other'
	,@Assessment AS Assessment
	,@WoundType AS WoundType
	,@OstomyCare AS OstomyCare
	,@DrainCare AS DrainCare
FROM @ObsAssociation oa
LEFT JOIN #temp t
	ON oa.ObsComment = t.ObsName
LEFT JOIN #temp t2
	ON oa.ObsPhysician = t2.ObsName
LEFT JOIN #temp t3
	ON oa.ObsDate = t3.ObsName
LEFT JOIN #temp t4
	ON oa.ObsExtra = t4.ObsName

--/* End of Stored Procedure */
