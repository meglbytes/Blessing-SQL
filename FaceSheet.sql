USE [TEST]
GO
/****** Object:  StoredProcedure [dbo].[BH_SSRS_Report_FaceSheet_Sp]    Script Date: 3/13/2013 8:15:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[BH_SSRS_Report_FaceSheet_Sp] (
	@JobID INT = NULL
)
AS

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
/**	Description:																					**/
/**-------------------------------------------------------------------------------------------------**/
/**	Pulls information about the patient for the facesheet report.									**/
/**-------------------------------------------------------------------------------------------------**/
/** Created: 05/19/2011		SXA Version: 5.5		Work Item: N/A		Author: Paul Slater			**/
/**=================================================================================================**/
/**	Mod		WI#			Date		Pgmr		Details												**/
/**-------------------------------------------------------------------------------------------------**/
/**	/A					1/8/2013	TKH			When contacts that were pushed to BAR from 			**/
/**												Healthquest for the Go-live on 10/1/2012, the		**/
/**												records that were put into CV3Phone put a value of 0**/ 
/**												into the Active field.  This stored proc checks to	**/
/**												see if the contact itself is active from the line	**/
/**												cc.Active = 1.  So, we don't need to check to see	**/
/**												if the phone number is active in CV3Phone.  I also	**/
/**												verified that changing a contact's phone number		**/
/**												would not add a new row into CV3Phone, so we will	**/
/**												never have multiple records to worry about.	This	**/
/**												is the same criteria that Allscripts uses to pull	**/
/**												the contact phone number in BAR	- reference			**/
/**												the stored proc SXAAMPhoneClientContactSelPr		**/
/** /B		1243		3/13/2013	MPM			Added referring physician to the report.  Supressed **/
/**												'Unknown', 'Unlisted', or 'No Referring' from being **/
/**												populated.											**/														
/**																									**/
/**=================================================================================================**/
/*****************************************************************************************************/

--DECLARE @JobID INT
--SELECT @JobID = 618963000

DECLARE
	@ReportVersion		VARCHAR(250),
	@ClientVisitGUID	NUMERIC(16,0),
	@ClientGUID			NUMERIC(16,0)

SELECT
	@ReportVersion = dbo.BH_ReportVersion_Fn(@JobID),
	@ClientVisitGUID = cv.GUID,
	@ClientGUID = cv.ClientGUID
FROM dbo.CV3VisitListJoin_R vlj (NOLOCK)
INNER JOIN dbo.CV3ClientVisit cv (NOLOCK)
	ON cv.GUID = vlj.ObjectGUID
WHERE vlj.JobID = @JobID

DECLARE @Person TABLE
(
	Type					VARCHAR(25),
	ScopeLevel				INT,
	Name					VARCHAR(150),
	RelationshipCode		VARCHAR(50),
	SSN						VARCHAR(15),
	DateOfBirth				DATETIME,
	AddressLine1			VARCHAR(150),
	AddressLine2			VARCHAR(150),
	City					VARCHAR(150),
	State					VARCHAR(150),
	ZipCode					VARCHAR(15),
	HomePhoneNumber			VARCHAR(20),
	BusinessPhoneNumber		VARCHAR(20),
	BusinessPhoneExtension	VARCHAR(20)
)

-- Get guarantor information
-- The ISNULL() statements are because the guarantor could link to the CV3Client
-- table or the CV3ClientContact table.
INSERT INTO @Person
SELECT
	'Guarantor' AS Type,
	1 AS ScopeLevel,
	ISNULL(c.DisplayName,cc.Name) AS Name,
	r.Code AS RelationshipCode,
	dbo.BH_PatientSSN_Fn(ISNULL(c.GUID,cc.GUID)) AS SSN,
	dbo.BH_PatientDateOfBirth_Fn(ISNULL(c.GUID,cc.GUID)) AS DateOfBirth,
	a.Line1 AS AddressLine1,
	a.Line2 AS AddressLine2,
	a.City AS City,
	a.CountryDvsnCode AS State,
	a.PostalCode AS ZipCode,
	CASE
		WHEN homephone.Extension IS NULL AND homephone.AreaCode IS NULL THEN homephone.PhoneNumber
		WHEN homephone.Extension IS NULL THEN '(' + homephone.AreaCode + ') ' + homephone.PhoneNumber
		WHEN homephone.AreaCode IS NULL THEN homephone.PhoneNumber
		ELSE '(' + homephone.AreaCode + ') ' + homephone.PhoneNumber + ' x' + homephone.Extension
	END AS HomePhoneNumber,
	CASE
		WHEN businessphone.AreaCode IS NULL THEN businessphone.PhoneNumber
		ELSE '(' + businessphone.AreaCode + ') ' + businessphone.PhoneNumber
	END AS WorkPhoneNumber,
	businessphone.Extension AS WorkPhoneExtension
FROM dbo.SXAAMVisitRegistration vr (NOLOCK)
INNER JOIN dbo.SXAAMGuarantor g (NOLOCK)
	ON g.GuarantorID = vr.GuarantorID
INNER JOIN dbo.CV3Relationship r (NOLOCK)
	ON r.GUID = g.RelationshipGUID
LEFT OUTER JOIN dbo.CV3Client c (NOLOCK)
	ON c.GUID = g.ClientGUID
LEFT OUTER JOIN dbo.CV3ClientContact cc (NOLOCK)
	ON cc.GUID = g.ClientContactGUID
LEFT OUTER JOIN dbo.CV3Address a (NOLOCK)
	ON a.ParentGUID = ISNULL(c.GUID,cc.GUID)
	AND a.Status = 'Active'
	AND a.Active = 1
LEFT OUTER JOIN dbo.CV3Phone homephone (NOLOCK)
	ON homephone.PersonGUID = ISNULL(c.GUID,cc.GUID)
	AND homephone.PhoneType = 'Home'
LEFT OUTER JOIN dbo.CV3Phone businessphone (NOLOCK)
	ON businessphone.PersonGUID = ISNULL(c.GUID,cc.GUID)
	AND businessphone.PhoneType = 'Business'
WHERE vr.ClientVisitGUID = @ClientVisitGUID

-- Get emerergency contact and nearest relative information
INSERT INTO @Person
SELECT
	CASE
		WHEN cc.TypeCode = 'Emergency' THEN 'Emergency Contact'
		WHEN cc.TypeCode = 'Nearest Relativ' THEN 'Nearest Relative'
	END AS Type,
	cc.ScopeLevel AS ScopeLevel,
	cc.Name AS Name,
	cc.RelationshipCode AS RelationshipCode,
	dbo.BH_PatientSSN_Fn(cc.GUID) AS SSN,
	dbo.BH_PatientDateOfBirth_Fn(cc.GUID) AS DateOfBirth,
	a.Line1 AS AddressLine1,
	a.Line2 AS AddressLine2,
	a.City AS City,
	a.CountryDvsnCode AS State,
	a.PostalCode AS ZipCode,
	CASE
		WHEN homephone.Extension IS NULL AND homephone.AreaCode IS NULL THEN homephone.PhoneNumber
		WHEN homephone.Extension IS NULL THEN '(' + homephone.AreaCode + ') ' + homephone.PhoneNumber
		WHEN homephone.AreaCode IS NULL THEN homephone.PhoneNumber
		ELSE '(' + homephone.AreaCode + ') ' + homephone.PhoneNumber + ' x' + homephone.Extension
	END AS HomePhoneNumber,
	CASE
		WHEN businessphone.AreaCode IS NULL THEN businessphone.PhoneNumber
		ELSE '(' + businessphone.AreaCode + ') ' + businessphone.PhoneNumber
	END AS WorkPhoneNumber,
	businessphone.Extension AS WorkPhoneExtension
FROM dbo.CV3ClientContact cc (NOLOCK)
LEFT OUTER JOIN dbo.CV3Address a (NOLOCK)
	ON a.ParentGUID = cc.GUID
	AND a.Status = 'Active'
	AND a.Active = 1
LEFT OUTER JOIN dbo.CV3Phone homephone (NOLOCK)
	ON homephone.PersonGUID = cc.GUID
	AND homephone.PhoneType = 'Home'
LEFT OUTER JOIN dbo.CV3Phone businessphone (NOLOCK)
	ON businessphone.PersonGUID = cc.GUID
	AND businessphone.PhoneType = 'Business'
WHERE cc.TypeCode IN ('Emergency','Nearest Relativ')
AND cc.Active = 1
AND (cc.ScopeLevel = 3 OR cc.ClientVisitGUID = @ClientVisitGUID)	
AND cc.ClientGUID = @ClientGUID

SELECT TOP 1
	hid.description, hid.text,
	'Face Sheet' AS ReportVersion,
	dbo.BH_PatientFacility_Fn(cv.GUID,c.GUID) AS Facility,
	cv.GUID AS ClientVisitGUID,
	cv.ClientGUID AS ClientGUID,
	cv.IDCode + ' / ' + cv.VisitIDCode AS MRN,
	cv.VisitIDCode AS VisitIDCode,
	--cv.CurrentLocation,
	CASE
		--WHEN @ReportVersion = 'Face Sheet - ED Reprint' THEN 'Emergency Department'
		WHEN @ReportVersion = 'Face Sheet - ED Reprint' THEN 'ED Waiting Room'
		ELSE cv.CurrentLocation
	END AS CurrentLocation,
	--cv.TypeCode AS VisitTypeCode,
	CASE
		WHEN @ReportVersion = 'Face Sheet - ED Reprint' THEN 'Emergency'
		ELSE cv.TypeCode
	END AS VisitTypeCode,
	--cv.CareLevelCode,
	CASE
		WHEN @ReportVersion = 'Face Sheet - ED Reprint' THEN 'Emergency Room'
		ELSE cv.CareLevelCode
	END AS CareLevelCode,
	--cv.AdmitDtm,
	CASE
		WHEN @ReportVersion = 'Face Sheet - ED Reprint' THEN
			dbo.BH_PatientEDAdmissionDtm_Fn(cv.GUID,cv.ClientGUID)
		ELSE cv.AdmitDtm
	END AS AdmitDtm,
	cv.DischargeDtm,
	dbo.BH_PatientPreviousAdmitDtm_Fn(cv.GUID,cv.ClientGUID) AS PreviousAdmitDtm,
	--s.Description AS Service,
	CASE
		WHEN @ReportVersion = 'Face Sheet - ED Reprint' THEN 'Emergency Room'
		ELSE s.Description
	END AS Service,
	accident.Code AS AccidentCode,
	admitting.DisplayName AS AdmittingMD,
	admitting.IDCode AS AdmittingMDID,
	attending.DisplayName AS AttendingMD,
	attending.IDCode AS AttendingMDID,
	primarymd.DisplayName AS PrimaryMD,
	primarymd.IDCode AS PrimaryMDID,
	-- Start of B
	CASE
		WHEN referring.DisplayName LIKE '%Unknown%' THEN ''
		WHEN referring.DisplayName LIKE '%Unlisted%' THEN ''
		WHEN referring.DisplayName LIKE '%No Referring%' THEN ''
		ELSE referring.DisplayName
	END AS ReferringMD,
	CASE
		WHEN referring.IDCode  LIKE '%Unknown%' THEN ''
		WHEN referring.IDCode LIKE '%Unlisted%' THEN ''
		WHEN referring.IDCode LIKE '%No Referring%' THEN ''
		ELSE referring.IDCode
	END AS referringMDID,
	-- End of B
	ISNULL(hid.Description,hid.ShortName) AS ChiefComplaint,
	primarydx.ShortName AS PrimaryDx,
	primarydx.Code AS PrimaryDxCode,
	c.DisplayName AS PatientName,
	dbo.BH_PatientDateOfBirth_Fn(c.GUID) AS PatientDateOfBirth,
	dbo.BH_PatientAge_Fn(c.GUID) AS PatientAge,
	c.GenderCode AS PatientGender,
	dbo.BH_PatientHeight_Fn(c.GUID) AS PatientHeight,
	dbo.BH_PatientWeight_Fn(c.GUID) AS PatientWeight,
	c.RaceCode AS PatientRace,
	c.MaritalStatusCode AS PatientMaritalStatus,
	a.Line1 AS PatientAddressLine1,
	a.Line2 AS PatientAddressLine2,
	a.City AS PatientCity,
	a.CountryDvsnCode AS PatientState,
	a.PostalCode AS PatientZipCode,
	dbo.BH_PatientPhone_Fn(c.GUID) AS PatientPhoneNumber,
	dbo.BH_PatientSSN_Fn(c.GUID) AS PatientSSN,
	c.ReligionCode AS PatientReligion,
	ci.Note AS Notes,
	employer.Name AS EmployerName,
	employer.AddressLine1 AS EmployerAddressLine1,
	employer.AddressLine2 AS EmployerAddressLine2,
	employer.City AS EmployerCity,
	employer.State AS EmployerState,
	employer.ZipCode AS EmployerZipCode,
	employer.PhoneNumber AS EmployerPhoneNumber,
	employer.PhoneExtension AS EmployerPhoneExtension,
	employer.Occupation AS EmployerOccupation,
	employer.StartDate AS EmployerStartDate,
	employer.EndDate AS EmployerEndDate,
	employer.Code AS EmployerStatus,
	guarantor.Name AS GuarantorName,
	guarantor.RelationshipCode AS GuarantorRelationshipCode,
	guarantor.SSN AS GuarantorSSN,
	guarantor.DateOfBirth AS GuarantorDateOfBirth,
	guarantor.AddressLine1 AS GuarantorAddressLine1,
	guarantor.AddressLine2 AS GuarantorAddressLine2,
	guarantor.City AS GuarantorCity,
	guarantor.State AS GuarantorState,
	guarantor.ZipCode AS GuarantorZipCode,
	guarantor.HomePhoneNumber AS GuarantorHomePhoneNumber,
	guarantor.BusinessPhoneNumber AS GuarantorWorkPhoneNumber,
	guarantor.BusinessPhoneExtension AS GuarantorWorkPhoneExtension,
	emercontact.Name AS EmergencyContactName,
	emercontact.RelationshipCode AS EmergencyContactRelation,
	emercontact.AddressLine1 AS EmergencyContactAddressLine1,
	emercontact.AddressLine2 AS EmergencyContactAddressLine2,
	emercontact.City AS EmergencyContactCity,
	emercontact.State AS EmergencyContactState,
	emercontact.ZipCode AS EmergencyContactZipCode,
	emercontact.HomePhoneNumber AS EmergencyContactHomePhoneNumber,
	emercontact.BusinessPhoneNumber AS EmergencyContactWorkPhoneNumber,
	emercontact.BusinessPhoneExtension AS EmergencyContactWorkPhoneExtension,
	nrelative.Name AS RelativeName,
	nrelative.RelationshipCode AS RelativeRelation,
	nrelative.AddressLine1 AS RelativeAddressLine1,
	nrelative.AddressLine2 AS RelativeAddressLine2,
	nrelative.City AS RelativeCity,
	nrelative.State AS RelativeState,
	nrelative.ZipCode AS RelativeZipCode,
	nrelative.HomePhoneNumber AS RelativeHomePhoneNumber,
	nrelative.BusinessPhoneNumber AS RelativeWorkPhoneNumber,
	nrelative.BusinessPhoneExtension AS RelativeWorkPhoneExtenstion
INTO #tmpFaceSheetInfo
FROM dbo.CV3VisitListJoin_R vlj (NOLOCK)
INNER JOIN dbo.CV3ClientVisit cv (NOLOCK)
	ON cv.GUID = vlj.ObjectGUID
INNER JOIN dbo.CV3Client c (NOLOCK)
	ON c.GUID = cv.ClientGUID
INNER JOIN dbo.CV3Service s (NOLOCK)
	ON s.GUID = cv.ServiceGUID
INNER JOIN dbo.SXAAMClientInfo ci (NOLOCK)
	ON ci.ClientGUID = cv.ClientGUID
LEFT OUTER JOIN dbo.CV3HealthIssueDeclaration hid (NOLOCK)
	ON hid.ClientVisitGUID = cv.GUID
	AND hid.ClientGUID = cv.ClientGUID
	AND hid.TypeCode IN ('Complaint_ECLP','Chief Complaint')
	AND hid.Status = 'Active'
LEFT OUTER JOIN dbo.CV3Address a (NOLOCK)
	ON a.ParentGUID = c.GUID
	AND a.Status = 'Active'
	AND a.Active = 1
LEFT OUTER JOIN
(
	SELECT
		va.ClientVisitGUID,
		at.Code
	FROM dbo.SXAAMVisitAccident va (NOLOCK)
	INNER JOIN dbo.SXAAMAccidentType at (NOLOCK)
		ON at.AccidentTypeID = va.AccidentTypeID
) accident
	ON accident.ClientVisitGUID = cv.GUID
LEFT OUTER JOIN
(
	SELECT
		ce.ClientGUID,
		ce.ClientVisitGUID,
		e.Name,
		a.Line1 AS AddressLine1,
		a.Line2 AS AddressLine2,
		a.City,
		a.CountryDvsnCode AS State,
		a.PostalCode AS ZipCode,
		et.Code,
		CASE
			WHEN p.AreaCode IS NULL THEN p.PhoneNumber
			ELSE '(' + p.AreaCode + ') ' + p.PhoneNumber
		END AS PhoneNumber,
		p.Extension AS PhoneExtension,
		ce.Occupation,
		ce.StartDate,
		ce.EndDate
	FROM dbo.SXAAMClientEmployment ce (NOLOCK)
	INNER JOIN dbo.SXAAMEmployer e (NOLOCK)
		ON e.EmployerID = ce.EmployerID
	INNER JOIN dbo.CV3EmploymentType et (NOLOCK)
		ON et.GUID = ce.EmploymentTypeGUID
	LEFT OUTER JOIN dbo.SXAAMEmployerAddress ea (NOLOCK)
		ON ea.EmployerID = e.EmployerID
	LEFT OUTER JOIN dbo.CV3Address a (NOLOCK)
		ON a.GUID = ea.AddressGUID
		AND a.Status = 'Active'
		AND a.Active = 1
	LEFT OUTER JOIN dbo.SXAAMEmployerPhone ep (NOLOCK)
		ON ep.EmployerID = e.EmployerID
	LEFT OUTER JOIN dbo.CV3Phone p (NOLOCK)
		ON p.GUID = ep.PhoneGUID
	WHERE ce.Active = 1
) employer
	ON employer.ClientVisitGUID = cv.GUID
	AND employer.ClientGUID = cv.ClientGUID
LEFT OUTER JOIN @Person guarantor
	ON guarantor.Type = 'Guarantor'

LEFT OUTER JOIN
(
	SELECT
		cpvr.ClientVisitGUID,
		cpvr.ClientGUID,
		cp.DisplayName,
		cpid.IDCode
	FROM dbo.CV3CareProviderVisitRole cpvr (NOLOCK)
	INNER JOIN dbo.CV3CareProvider cp (NOLOCK)
		ON cp.GUID = cpvr.ProviderGUID
	INNER JOIN dbo.CV3CareProviderID cpid (NOLOCK)
		ON cpid.ProviderGUID = cp.GUID
	WHERE cpvr.RoleCode = 'Admitting'
	AND cpvr.Active = 1
	AND ISNULL(cpvr.ToDtm,GETDATE()) >= GETDATE()
	AND cpid.ProviderIDTypeCode = 'Primary'
	AND cpid.Active = 1
) admitting
	ON admitting.ClientVisitGUID = cv.GUID
	AND admitting.ClientGUID = cv.ClientGUID
LEFT OUTER JOIN
(
	SELECT
		cpvr.ClientVisitGUID,
		cpvr.ClientGUID,
		cp.DisplayName,
		cpid.IDCode
	FROM dbo.CV3CareProviderVisitRole cpvr (NOLOCK)
	INNER JOIN dbo.CV3CareProvider cp (NOLOCK)
		ON cp.GUID = cpvr.ProviderGUID
	INNER JOIN dbo.CV3CareProviderID cpid (NOLOCK)
		ON cpid.ProviderGUID = cp.GUID
	WHERE cpvr.RoleCode = 'Attending'
	AND cpvr.Active = 1
	AND ISNULL(cpvr.ToDtm,GETDATE()) >= GETDATE()
	AND cpid.ProviderIDTypeCode = 'Primary'
	AND cpid.Active = 1
) attending
	ON attending.ClientVisitGUID = cv.GUID
	AND attending.ClientGUID = cv.ClientGUID
LEFT OUTER JOIN
(
	SELECT
		cpvr.ClientVisitGUID,
		cpvr.ClientGUID,
		cp.DisplayName,
		cpid.IDCode
	FROM dbo.CV3CareProviderVisitRole cpvr (NOLOCK)
	INNER JOIN dbo.CV3CareProvider cp (NOLOCK)
		ON cp.GUID = cpvr.ProviderGUID
	INNER JOIN dbo.CV3CareProviderID cpid (NOLOCK)
		ON cpid.ProviderGUID = cp.GUID
	WHERE cpvr.RoleCode = 'Referring'
	AND cpvr.Active = 1
	AND ISNULL(cpvr.ToDtm,GETDATE()) >= GETDATE()
	AND cpid.ProviderIDTypeCode = 'Primary'
	AND cpid.Active = 1
) referring
	ON referring.ClientVisitGUID = cv.GUID
	AND referring.ClientGUID = cv.ClientGUID
LEFT OUTER JOIN
(
	SELECT
		cpvr.ClientVisitGUID,
		cpvr.ClientGUID,
		cpvr.ScopeLevel,
		cp.DisplayName,
		cpid.IDCode
	FROM dbo.CV3CareProviderVisitRole cpvr (NOLOCK)
	INNER JOIN dbo.CV3CareProvider cp (NOLOCK)
		ON cp.GUID = cpvr.ProviderGUID
	INNER JOIN dbo.CV3CareProviderID cpid (NOLOCK)
		ON cpid.ProviderGUID = cp.GUID
	WHERE cpvr.RoleCode = 'Primary Care Provider'
	AND cpvr.Active = 1
	AND ISNULL(cpvr.ToDtm,GETDATE()) >= GETDATE()
	AND cpid.ProviderIDTypeCode = 'Primary'
	AND cpid.Active = 1
) primarymd
	ON primarymd.ClientGUID = cv.ClientGUID
	AND (primarymd.ClientVisitGUID = cv.GUID OR primarymd.ScopeLevel = 3)
LEFT OUTER JOIN @Person emercontact
	ON emercontact.Type = 'Emergency Contact'
LEFT OUTER JOIN @Person nrelative
	ON nrelative.Type = 'Nearest Relative'
LEFT OUTER JOIN
(
	SELECT TOP 10
		hid.ClientVisitGUID,
		hid.ClientGUID,
		hid.ShortName,
		chi.Code
	FROM dbo.CV3HealthIssueDeclaration hid (NOLOCK)
	INNER JOIN dbo.CV3CodedHealthIssue chi (NOLOCK)
		ON chi.GUID = hid.CodedHealthIssueGUID
	WHERE hid.TypeCode = 'Principal Dx'
	AND hid.Status = 'Active'
) primarydx
	ON primarydx.ClientVisitGUID = cv.GUID
	AND primarydx.ClientGUID = cv.ClientGUID
WHERE JobID = @JobID
ORDER BY guarantor.ScopeLevel,emercontact.ScopeLevel,nrelative.ScopeLevel

--Build a single table to store the client events and health manager events
DECLARE @Event TABLE
(
	ClientGUID		NUMERIC(16,0),
	Type			VARCHAR(250),
	Description		VARCHAR(250),
	OnsetDate		DATETIME,
	OnsetDateString	VARCHAR(20)
)
INSERT INTO @Event
SELECT
	fsi.ClientGUID AS ClientGUID,
	ced.TypeCode AS EventType,
	ced.Description AS EventDescription,
	CASE
		WHEN ced.OnsetDayNum > 0 THEN
			CONVERT(DATETIME,
			CONVERT(VARCHAR(2),ced.OnsetMonthNum) + '/' + 
			CONVERT(VARCHAR(2),ced.OnsetDayNum) + '/' + 
			CONVERT(VARCHAR(4),ced.OnsetYearNum))
		ELSE NULL
	END AS EventOnsetDate,
	CASE
		WHEN ced.OnsetDayNum > 0 THEN NULL
		ELSE
			CASE
				WHEN (ced.OnsetMonthNum = 0 AND ced.OnsetYearNum = 0) THEN 'Unkown'
				WHEN (ced.OnsetMonthNum = 0 AND ced.OnsetYearNum <> 0) THEN LTRIM(STR(STR(ced.OnsetYearNum)))
				ELSE DATENAME (m,CONVERT(DATETIME,str(ced.OnsetMonthNum) + '/' + STR(1) + '/' + STR(ced.OnsetYearNum))) + '-' + LTRIM(STR(STR(ced.OnsetYearNum)))
			END
	END AS EventOnsetDateString
FROM #tmpFaceSheetInfo fsi
INNER JOIN dbo.CV3ClientEventDeclaration ced (NOLOCK)
	ON ced.ClientGUID = fsi.ClientGUID
	AND (ced.ClientVisitGUID = fsi.ClientVisitGUID OR ced.ScopeLevel > 1)
	AND ced.Status = 'Active'
UNION
SELECT
	fsi.ClientGUID AS ClientGUID,
	er.ReferenceString AS EventType,
	e.Name AS EventDescription,
	CASE
		WHEN seo.ActionDay > 0 THEN
			CONVERT(DATETIME,
			CONVERT(VARCHAR(2),seo.ActionMonth) + '/' + 
			CONVERT(VARCHAR(2),seo.ActionDay) + '/' + 
			CONVERT(VARCHAR(4),seo.ActionYear))
		ELSE NULL
	END AS EventOnsetDate,
	CASE
		WHEN seo.ActionDay > 0 THEN NULL
		ELSE
			CASE
				WHEN (seo.ActionMonth = 0 AND seo.ActionYear = 0) THEN 'Unkown'
				WHEN (seo.ActionMonth = 0 AND seo.ActionYear <> 0) THEN LTRIM(STR(STR(seo.ActionYear)))
				ELSE DATENAME (m,CONVERT(DATETIME,str(seo.ActionMonth) + '/' + STR(1) + '/' + STR(seo.ActionYear))) + '-' + LTRIM(STR(STR(seo.ActionYear)))
			END
	END AS EventOnsetDateString
FROM #tmpFaceSheetInfo fsi
INNER JOIN dbo.SXAHMScheduledEventOccurrence seo (NOLOCK)
	ON seo.ClientGUID = fsi.ClientGUID
INNER JOIN dbo.SXAHMEvent e (NOLOCK)
	ON e.EventID = seo.EventID
INNER JOIN dbo.CV3EnumReference er (NOLOCK)
	ON er.EnumValue = e.Type
	AND er.TableName = 'SXAHMEvent'
	AND er.ColumnName = 'Type'

--Build final results
SELECT
	fsi.*,
	1 AS DetailType,
	insurance.[Type] AS InsuranceType,
	insurance.[Plan] AS InsurancePlan,
	insurance.PolicyNum AS InsurancePolicyNumber,
	insurance.GroupNum AS InsuranceGroupNumber,
	insurance.AddressLine1 AS InsuranceAddressLine1,
	insurance.AddressLine2 AS InsuranceAddressLine2,
	insurance.City AS InsuranceCity,
	insurance.State AS InsuranceState,
	insurance.ZipCode AS InsuranceZipCode,
	insurance.SequenceNum AS InsuranceSequenceNumber,
	CASE
		WHEN insurance.AreaCode IS NULL THEN insurance.PhoneNumber
		ELSE '(' + insurance.AreaCode + ') ' + insurance.PhoneNumber
	END AS InsurancePhoneNumber,
	NULL AS CommentType,
	NULL AS CommentText,
	NULL AS EventType,
	NULL AS EventDescription,
	NULL AS EventOnsetDate,
	NULL AS EventOnsetDateString
FROM #tmpFaceSheetInfo fsi
LEFT OUTER JOIN
(
	SELECT
		frpc.ClientVisitGUID,
		frpc.ClientGUID,
		sit.Name AS [Type],
		frp.Name AS [Plan],
		frpc.PolicyNum,
		frpc.GroupNum,
		frpc.SequenceNum,
		frp.AddrLine1 AS AddressLine1,
		frp.AddrLine2 AS AddressLine2,
		frp.City AS City,
		frp.CountryDvsnCode AS State,
		frp.PostalCode AS ZipCode,
		frp.AreaCode,
		frp.PhoneNumber
	FROM dbo.CV3FRPContract frpc (NOLOCK)
	LEFT JOIN dbo.CV3FRP frp (NOLOCK)
		ON frp.GUID = frpc.FRPGUID
		AND frp.Active = 1
	LEFT JOIN dbo.SXAAMInsuranceCarrier sic (NOLOCK)
		ON SIC.InsuranceCarrierID = frp.InsuranceCarrierID
	LEFT JOIN dbo.SXAAMInsuranceType sit (NOLOCK)
		ON sit.InsuranceTypeID = frp.InsuranceTypeID
	WHERE frpc.Status ='Active'
	AND frpc.Active = 1
) insurance
	ON insurance.ClientVisitGUID = fsi.ClientVisitGUID
	AND insurance.ClientGUID = fsi.ClientGUID
UNION ALL
SELECT
	fsi.*,
	2 AS DetailType,
	NULL AS InsuranceType,
	NULL AS InsuranceCarier,
	NULL AS InsurancePolicyNumber,
	NULL AS InsuranceGroupNumber,
	NULL AS InsuranceAddressLine1,
	NULL AS InsuranceAddressLine2,
	NULL AS InsuranceCity,
	NULL AS InsuranceState,
	NULL AS InsuranceZipCode,
	NULL AS InsuranceSequenceNumber,
	NULL AS InsurancePhoneNumber,
	cd.TypeCode AS CommentType,
	cd.Text AS CommentText,
	NULL AS EventType,
	NULL AS EventDescription,
	NULL AS EventOnsetDate,
	NULL AS EventOnsetDateString
FROM #tmpFaceSheetInfo fsi
LEFT OUTER JOIN dbo.CV3CommentDeclaration cd (NOLOCK)
	ON cd.ClientGUID = fsi.ClientGUID
	AND (cd.ClientVisitGUID = fsi.ClientVisitGUID OR cd.ScopeLevel = 3)
	AND cd.Status = 'Active'
	AND cd.TypeCode = 'Patient Access'
/*UNION ALL
SELECT
	fsi.*,
	3 AS DetailType,
	NULL AS InsuranceType,
	NULL AS InsuranceCarier,
	NULL AS InsurancePolicyNumber,
	NULL AS InsuranceGroupNumber,
	NULL AS InsuranceAddressLine1,
	NULL AS InsuranceAddressLine2,
	NULL AS InsuranceCity,
	NULL AS InsuranceState,
	NULL AS InsuranceZipCode,
	NULL AS InsuranceSequenceNumber,
	NULL AS InsurancePhoneNumber,	
	NULL AS CommentType,
	NULL AS CommentText,
	e.Type AS EventType,
	e.Description AS EventDescription,
	e.OnsetDate AS EventOnsetDate,
	e.OnsetDateString AS EventOnsetDateString
FROM #tmpFaceSheetInfo fsi
LEFT OUTER JOIN @Event e
	ON e.ClientGUID = fsi.ClientGUID
*/
DROP TABLE #tmpFaceSheetInfo
