USE [PROD1]
GO
/****** Object:  StoredProcedure [dbo].[BH_SSRS_Report_MissingMSP_Sp]    Script Date: 4/17/2013 11:17:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[BH_SSRS_Report_MissingMSP_Sp](
	 @JobID	INT
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
/**	Description:		                                                                        	**/
/**-------------------------------------------------------------------------------------------------**/
/**	Return a listing of patients in observation visits in whom has charges in						**/								
/** temporary locations with their start/stop times													**/
/**-------------------------------------------------------------------------------------------------**/
/**-------------------------------------------------------------------------------------------------**/
/** Created: 09/17/2010		SXA Version: 51		Work Item: XX#		Author: Jason Gerding			**/
/**=================================================================================================**/
/**	Mod		WI#			Date		Pgmr		Details												**/
/**	/A		1398		4/18/2013	MPM			Added Patient Facility								**/
/**																									**/
/**-------------------------------------------------------------------------------------------------**/
/**=================================================================================================**/
/*****************************************************************************************************/

--DECLARE @JobID INT
--SET @JobID = 961638000

--Start of /A
DECLARE @temp TABLE 
(
	MRN					Varchar(100),
	Name				Varchar(100),
	Admitdtm			DATETIME,
	VisitType			Varchar(20),
	CareLevel			Varchar(50),
	ClientVisitGUID		Numeric(16,0),
	ClientGUID			Numeric(16,0),
	VisitStatus			Char(3),
	IsThirdPartyLiable	Varchar(50),
	IsWorkRelated		Varchar(50),
	CareLevelCode		Varchar(50),
	Ins					Varchar(30),
	Facility			Char(2),
	ReportVersion		Varchar(20),
	PatientFacility		Varchar(10)
)
--End of /A

DECLARE
	@Facility		VARCHAR(10),
	@ReportVersion	VARCHAR(50),
	@HVCFromDate	DATETIME,
	@HVCToDate		DATETIME

SELECT
	@Facility = dbo.BH_WorkstationFacility_Fn(@JobID),
	@ReportVersion = dbo.BH_ReportVersion_Fn(@JobID),
	@HVCFromDate = dbo.BH_GetDateTime_Fn(@JobID,'HVCFromDate'),
	@HVCToDate = dbo.BH_GetDateTime_Fn(@JobID,'HVCToDate12am')
	--@Facility = 'BH',--dbo.BH_WorkstationFacility_Fn(@JobID),
	--@ReportVersion ='Test'-- dbo.BH_ReportVersion_Fn(@JobID),
	--@HVCFromDate = '10/24/2012',--dbo.BH_GetDateTime_Fn(@JobID,'HVCFromDate'),
	--@HVCToDate = '10/25/2012'--dbo.BH_GetDateTime_Fn(@JobID,'HVCToDate12am') + 1

INSERT INTO @temp
SELECT 
	  cv.IDCode + '/' + cv.VisitIDCode AS MRN
	, cv.ClientDisplayName Name
	, CONVERT(VARCHAR(10),cv.AdmitDtm,101) Admitdtm
	, cv.TypeCode as VisitType
	, cv.CareLevelCode as CareLevel
	, cv.GUID as ClientVisitGUID
	, cv.ClientGUID
	, cv.VisitStatus
	, mspq.IsThirdPartyLiable
	, mspq.IsWorkRelated
	, cv.CareLevelCode 
	, dbo.BH_PrimaryInsurance_Fn(cv.guid,cv.clientguid) Ins
	, @Facility Facility
	, @ReportVersion ReportVersion
	, PatientFacility = NULL
FROM dbo.CV3ClientVisit cv (NOLOCK)
	LEFT OUTER JOIN SXAAMMSPQuestionnaire mspq (NOLOCK)
		ON mspq.ClientGUID = cv.ClientGUID
		AND mspq.VisitGUID = cv.GUID
	WHERE cv.AdmitDtm >= @HVCFromDate
	AND cv.AdmitDtm < @HVCToDate +1
	AND dbo.BH_PrimaryInsurance_Fn(cv.GUID,cv.ClientGUID) LIKE '%Medicare%'
	AND (cv.VisitStatus IN ('ADM','DSC','CLS'))
	AND (mspq.IsThirdPartyLiable IS NULL OR mspq.IsWorkRelated IS NULL)
	AND cv.CareLevelCode <> 'Specimen'

----Start of /A
UPDATE @temp
SET PatientFacility = dbo.BH_PatientFacility_Fn(ClientVisitGUID, ClientGUID)
----End of /A 