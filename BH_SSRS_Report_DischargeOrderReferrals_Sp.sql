USE [TEST]
GO
/****** Object:  StoredProcedure [dbo].[BH_SSRS_Report_DischargeOrderReferrals_Sp]    Script Date: 9/9/2014 9:18:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[BH_SSRS_Report_DischargeOrderReferrals_Sp] (
	@JobID INT
) AS

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
/**	Description:	Returns followup orders from the discharge note									**/
/**-------------------------------------------------------------------------------------------------**/
/**				Created from original XXX for SCM5.5 upgrade				**/
/**			Made some changes for migration and table index usage but additional changes would		**/
/**				require	clinical use analysis														**/
/**-------------------------------------------------------------------------------------------------**/
/** Created: 02/04/2010		SXA Version: 5.5		Work Item: XX#		Author: Ariel Mears			**/
/**=================================================================================================**/
/**	Mod		WI#			Date		Pgmr		Details												**/
/**-------------------------------------------------------------------------------------------------**/
/**	/B		08/23/10	RMZ			Added Obs to list												**/
/**	/C		10/01/2010	rrs			SCm 5.5 report conversions										**/
/** /D					11/30/2010	PWS			Added a client guid join to increase perfomance.	**/
/** /E      BAR-1085    04/18/2012  NN			Change DNSG_DCCardRehabReason_TO observation to     **/
/**                                             DNSG_DCCardRehabPhaseII_RO                          **/
/**	/F		BAR-1724	05/14/2012	PWS			Change to observation values.						**/
/** /G		FaceToFace	03/18/2014	NGC			Add observations for Face To Face					**/	
/**=================================================================================================**/
/*****************************************************************************************************/
SET NOCOUNT ON
--DECLARE @JobID INT SET @JobID = 1485000

DECLARE @ClientVisitGUID NUMERIC(16,0)
DECLARE @ClientGUID NUMERIC(16,0)
DECLARE @ChartGUID NUMERIC(16,0)


DECLARE @ObsNames TABLE (
	 ObsNameValue		VARCHAR(128)
	,ValueType			INT
)

DECLARE @ObsAssociation TABLE (
	 OrderName		VARCHAR(128)
	,ObsType		VARCHAR(128)
	,ObsComment		VARCHAR(256)
	,ObsPhysician	VARCHAR(128)
	,ObsDate		VARCHAR(50)
)

DECLARE @OrderItems TABLE (
	 ObsName		VARCHAR(128)
	,ValueText		VARCHAR(8000)
)

DECLARE @FinalResults TABLE (
	 OrderName		VARCHAR(128)
	,TypeValue		VARCHAR(128)
	,Comment		VARCHAR(8000)
	,Physician		VARCHAR(128)
	,SignDate		VARCHAR(50)
)

DECLARE 
	 @VisitNurseValue VARCHAR(MAX)
	,@LabDraw VARCHAR(MAX)

INSERT INTO @ObsNames SELECT 'DNSG_DCRehab_SO',1
INSERT INTO @ObsNames SELECT 'DNSG_DCRehabPTType_SO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCRehabPTComments_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyPT_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDatePT_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCRehabOTType_SO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCRehabOTComments_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyOT_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDateOT_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCRehabSTType_SO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCRehabSTComments_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyST_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDateST_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCCardRehabReason_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCCardRehabPhaseII_RO',2 ---------/E
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyCardiacRehab_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDateCardiacRehab_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCPulmonaryRehabReason_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyPulmonaryRehab_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDatePulmonaryRehab_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyVisitingNurse_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDateVisitingNurse_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCReasonForHomeNurse_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyLabHomeVisit_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDateLabHomeVisit_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCLabHomeVisitReason_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyHospiceRef_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDateHospiceReferral_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCHospiceReferralReason_TO',2
INSERT INTO @ObsNames SELECT 'DBH_DC HCLabDraws_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyOtherRef_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDateOtherRef_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCReasonOtherRef_TO',2
--start /G
INSERT INTO @ObsNames SELECT 'DNSG_DCHomecareType_RO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCHomecareVisitNurse_RO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCVisitNurseAssmtInst_RO',2
INSERT INTO @ObsNames SELECT 'DNSG_VisitNurseDiseaseMgmt_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_WoundType_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_OstomyCare_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingPhyFaceToFace_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCOrderingDateFaceToFace_DO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCHomecarePT_RO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCHomecarePTOther_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCHomecareOT_RO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCHomecareOTOther_TO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCHomecareST_RO',2
INSERT INTO @ObsNames SELECT 'DNSG_DCHomecareSTOther_TO',2
--end /G

/* Start of /F */
--INSERT INTO @ObsAssociation SELECT 'PT - Evaluate and Treat','DNSG_DCRehabPTType_SO','DNSG_DCRehabPTComments_TO','DNSG_DCOrderingPhyPT_TO','DNSG_DCOrderingDatePT_DO'
--INSERT INTO @ObsAssociation SELECT 'OT - Evaluate and Treat','DNSG_DCRehabOTType_SO','DNSG_DCRehabOTComments_TO','DNSG_DCOrderingPhyOT_TO','DNSG_DCOrderingDateOT_DO'
--INSERT INTO @ObsAssociation SELECT 'ST - Evaluate and Treat','DNSG_DCRehabSTType_SO','DNSG_DCRehabSTComments_TO','DNSG_DCOrderingPhyST_TO','DNSG_DCOrderingDateST_DO'
INSERT INTO @ObsAssociation SELECT 'PT Outpatient - Evaluate and Treat','DNSG_DCRehabPTType_SO','DNSG_DCRehabPTComments_TO','DNSG_DCOrderingPhyPT_TO','DNSG_DCOrderingDatePT_DO'
INSERT INTO @ObsAssociation SELECT 'OT Outpatient - Evaluate and Treat','DNSG_DCRehabOTType_SO','DNSG_DCRehabOTComments_TO','DNSG_DCOrderingPhyOT_TO','DNSG_DCOrderingDateOT_DO'
INSERT INTO @ObsAssociation SELECT 'ST Outpatient - Evaluate and Treat','DNSG_DCRehabSTType_SO','DNSG_DCRehabSTComments_TO','DNSG_DCOrderingPhyST_TO','DNSG_DCOrderingDateST_DO'
/* End of /F */
INSERT INTO @ObsAssociation SELECT 'Cardiac Rehab Phase II',NULL,'DNSG_DCCardRehabPhaseII_RO','DNSG_DCOrderingPhyCardiacRehab_TO','DNSG_DCOrderingDateCardiacRehab_DO' --/E
INSERT INTO @ObsAssociation SELECT 'Cardiac Rehab Phase II OLD',NULL,'DNSG_DCCardRehabReason_TO','DNSG_DCOrderingPhyCardiacRehab_TO','DNSG_DCOrderingDateCardiacRehab_DO' --/E
INSERT INTO @ObsAssociation SELECT 'Pulmonary Rehab',NULL,'DNSG_DCPulmonaryRehabReason_TO','DNSG_DCOrderingPhyPulmonaryRehab_TO','DNSG_DCOrderingDatePulmonaryRehab_DO'
INSERT INTO @ObsAssociation SELECT 'Visiting Nurse Eval',NULL,'DNSG_DCReasonForHomeNurse_TO','DNSG_DCOrderingPhyVisitingNurse_TO','DNSG_DCOrderingDateVisitingNurse_DO'
INSERT INTO @ObsAssociation SELECT 'Lab Home Visit',NULL,'DNSG_DCLabHomeVisitReason_TO','DNSG_DCOrderingPhyLabHomeVisit_TO','DNSG_DCOrderingDateLabHomeVisit_DO'
INSERT INTO @ObsAssociation SELECT 'Hospice Referral',NULL,'DNSG_DCHospiceReferralReason_TO','DNSG_DCOrderingPhyHospiceRef_TO','DNSG_DCOrderingDateHospiceReferral_DO'
INSERT INTO @ObsAssociation SELECT 'Outpatient Medical Nutrition Services',NULL,'DNSG_DCOutpatientNutritionReason_TO','DNSG_DCOrderingPhyOutpatientNutrition_TO','DNSG_DCOrderingDateOutpatientNutrition_DO' -- /A
INSERT INTO @ObsAssociation SELECT 'Other Discharge Referral (specify):','OtherDiscType','DNSG_DCReasonOtherRef_TO','DNSG_DCOrderingPhyOtherRef_TO','DNSG_DCOrderingDateOtherRef_DO' -- /A

SELECT @ClientVisitGUID = cv.GUID, @ClientGUID = cv.ClientGUID, @ChartGUID = cv.ChartGUID
FROM CV3VisitListJoin_R vlj (NOLOCK) INNER JOIN CV3ClientVisit cv (NOLOCK) ON cv.GUID = vlj.ObjectGUID
WHERE vlj.JobID = @JobID


--select * from @ObsNames

INSERT INTO @OrderItems
SELECT
	 CASE WHEN oflv.SortSeqNum = 11 THEN 'OtherDiscType' ELSE dbo.BH_ValidLengthString_Fn(ocmi.Name,128) END ObsName
	,CASE
	 WHEN oflv.Value IS NULL THEN
		dbo.BH_ValidLengthString_Fn(o.ValueText,8000)	 
	 ELSE
		dbo.BH_ValidLengthString_Fn(oflv.Value,8000)
	 END ValueText
FROM
	dbo.CV3ClientVisit cv (NOLOCK)
	INNER JOIN dbo.CV3ClientDocument cd (NOLOCK)
		ON (cv.GUID = cd.ClientVisitGUID
		AND cv.ClientGUID = cd.ClientGUID
		AND cv.ChartGUID = cd.ChartGUID)
	INNER JOIN dbo.CV3ObservationDocument od (NOLOCK)
		ON (cd.GUID = od.OwnerGUID
		AND od.Active = 1)
	INNER JOIN dbo.CV3Observation o (NOLOCK)
		ON (od.ObservationGUID = o.GUID)
	INNER JOIN dbo.CV3ObsCatalogMasterItem ocmi (NOLOCK)
		ON (od.ObsMasterItemGUID = ocmi.GUID)
	INNER JOIN @ObsNames obn
		ON (ocmi.Name = obn.ObsNameValue)
	LEFT OUTER JOIN dbo.CV3ObservationEntryItem oei (NOLOCK)
		ON (od.ParameterGUID = oei.GUID)
	LEFT OUTER JOIN dbo.SCMObsFSListValues oflv (NOLOCK)
		ON (od.ObservationDocumentGUID = oflv.ParentGUID
		AND cd.ClientGUID = oflv.ClientGUID) --/D
WHERE
	cv.GUID = @ClientVisitGUID
	AND cv.ClientGUID = @ClientGUID
	AND cv.ChartGUID = @ChartGUID
	AND cd.DocumentName = 'Discharge Orders'
	AND (oflv.Value IS NOT NULL	OR o.ValueText IS NOT NULL)

--select * from @OrderItems --TESTING ONLY
--select * from @ObsAssociation

--start /E
declare @Comments varchar(max) = ''

SELECT  @Comments=@Comments+oi3.ValueText + CHAR(10)
FROM @ObsAssociation oa3
INNER JOIN @OrderItems oi3 
ON (oa3.ObsComment = oi3.ObsName)

select @Comments=case when left(@Comments,1)=CHAR(10) 
						 then right(@Comments,len(@Comments)-2) 
						 else @Comments end   
--End /E

INSERT INTO @FinalResults
SELECT
	 dbo.BH_ValidLengthString_Fn(oi.ValueText,128) OrderName
	,(SELECT TOP 1 dbo.BH_ValidLengthString_Fn(oi2.ValueText,128)
	  FROM @ObsAssociation oa2
	  INNER JOIN @OrderItems oi2 ON (oa2.ObsType = oi2.ObsName)
	  WHERE oi.ValueText = oa2.OrderName) TypeValue
	,@Comments  Comment --/E
	/*(SELECT TOP 1 dbo.BH_ValidLengthString_Fn(oi3.ValueText,8000)
	  FROM @ObsAssociation oa3
	  INNER JOIN @OrderItems oi3 ON (oa3.ObsComment = oi3.ObsName)
	  /*WHERE oi.ValueText = oa3.OrderName*/)*/
	,(SELECT TOP 1 dbo.BH_ValidLengthString_Fn(oi4.ValueText,128)
	  FROM @ObsAssociation oa4
	  INNER JOIN @OrderItems oi4 ON (oa4.ObsPhysician = oi4.ObsName)
	  WHERE oi.ValueText = oa4.OrderName) Physician
	,(SELECT TOP 1 dbo.BH_ValidLengthString_Fn(oi5.ValueText,50)
	  FROM @ObsAssociation oa5
	  INNER JOIN @OrderItems oi5 ON (oa5.ObsDate = oi5.ObsName)
	  WHERE oi.ValueText = oa5.OrderName) SignDate
FROM
	@OrderItems oi
	INNER JOIN @ObsNames obn
		ON (oi.ObsName = obn.ObsNameValue
		AND obn.ValueType = 1)


--select * from @FinalResults --TESTING ONLY

SELECT @LabDraw = CHAR(10) + 'Lab Draws: ' + oi.ValueText FROM @OrderItems oi WHERE oi.ObsName = 'DBH_DC HCLabDraws_TO'

SELECT @VisitNurseValue = COALESCE(@VisitNurseValue + ', ','') + oi.ValueText
FROM @OrderItems oi WHERE oi.ObsName = 'DNSG_DCReasonForHomeNurse_TO' AND oi.ValueText <> 'Other'

IF @LabDraw IS NOT NULL
BEGIN
	UPDATE @FinalResults 
	SET Comment = @VisitNurseValue + @LabDraw
	WHERE OrderName = 'Visiting Nurse Eval'
END
ELSE
BEGIN
	UPDATE @FinalResults
	SET Comment = @VisitNurseValue
	WHERE OrderName = 'Visiting Nurse Eval'
END

DECLARE @ReportVersion VARCHAR(100)
	SET @ReportVersion = [dbo].[BH_ReportVersion_Fn](@JobID)

--select * from @FinalResults --TESTING ONLY

SELECT 
	 dbo.BH_PatientFacility_Fn(@ClientVisitGUID,@ClientGUID) AS Facility
	 ,@ReportVersion [Version]
	,@ClientVisitGUID ClientVisitGUID
	,@ClientGUID ClientGUID
	,Physician + ' (' + ISNULL((SELECT TOP 1 OccupationCode FROM CV3User (NOLOCK) WHERE DisplayName LIKE Physician + '%' ORDER BY TouchedWhen DESC),'') + ')' Physician
	,fr.OrderName
	,fr.TypeValue
	,fr.Comment
	,fr.SignDate
FROM 
	@FinalResults fr
WHERE 
	fr.OrderName IS NOT NULL
	AND fr.Physician IS NOT NULL
ORDER BY
	 fr.Physician
	,fr.OrderName
