USE [TEST]
GO
/****** Object:  StoredProcedure [dbo].[BH_SSRS_Report_NarcoticTracking_Sp]    Script Date: 7/10/2013 3:14:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[BH_SSRS_Report_NarcoticTracking_Sp] (
	@JobID INT
)AS

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
/**	Description: Audit report that returns the amount of wasted narcotics in the Hospital.			**/
/**-------------------------------------------------------------------------------------------------**/
/** REPORT USAGE:	BHNarcoticTracking.rdl															**/
/**-------------------------------------------------------------------------------------------------**/
/** Created: 7/10/2013   SXA Version: 5.5	Work Item: TFS-165, BAR-2109  Author: Matthew Meglan    **/
/**=================================================================================================**/
/**	Mod		WI#			Date		Pgmr		Details												**/
/**																									**/
/**-------------------------------------------------------------------------------------------------**/
/**=================================================================================================**/
/*****************************************************************************************************/

--DECLARE @JobID INT SET @JobID = 181015000

IF OBJECT_ID('tempdb..#temp') IS NOT NULL 
	DROP TABLE #temp
IF OBJECT_ID('tempdb..#temp2') IS NOT NULL 
	DROP TABLE #temp2	

DECLARE 
	 @FromDate			DATETIME
	,@ToDate			DATETIME
	,@Control			VARCHAR(255)
	,@Facility			VARCHAR(10)
	,@ReportVersion		VARCHAR(100)	

SELECT
	 @ReportVersion = dbo.BH_ReportVersion_Fn(@JobID)
	,@Facility = dbo.BH_WorkstationFacility_Fn(@JobID)
	,@ToDate = dbo.BH_SXADate_Fn(@JobID,'HVCToDate12am')
	,@FromDate = dbo.BH_SXADate_Fn(@JobID,'HVCFromDate')
	,@Control = dbo.BH_SXAData_Fn(@JobID,'HVCLine1')

--SET @FromDate = '2013/06/01'
--SET @ToDate = '2013/07/10'
--SET @Control = 123456

DECLARE 
	@DocGUID Numeric(16,0),
	@AmountGUID Numeric(16,0),
	@ControlGUID Numeric(16,0),
	@MedicationGUID Numeric(16,0)
	
SELECT @DocGUID = GUID 
FROM dbo.CV3PatientCareDocument 
WHERE Name = 'PCA/Controlled Substances' 

SELECT @AmountGUID = GUID
FROM dbo.CV3ObsCatalogMasterItem
WHERE Name = 'dnsg_amount in ml waste_no'

SELECT @ControlGUID = GUID
FROM dbo.CV3ObsCatalogMasterItem
WHERE Name = 'DNSG_ControlNumber_NO'

SELECT @MedicationGUID = GUID
FROM dbo.CV3ObsCatalogMasterItem ocmi
WHERE ocmi.Name = 'DNSG_PCATherapy_UO'


IF @Control IS NULL
BEGIN
	SELECT cv.GUID AS CVGUID, 
		cd.GUID AS DocGUID,
		ocmi.GUID AS ObsCatGUID,
		u.DisplayName AS WasteUser, 
		o.ValueText, 
		cv.IDCode AS MRN, 
		cd.AuthoredDTM AS WasteDTM, 
		fslv.Value,
		ocmi.Name
	INTO #temp
	FROM dbo.CV3ClientVisit cv
	INNER JOIN dbo.CV3ClientDocument cd
		ON cv.GUID = cd.ClientVisitGUID
		AND cv.ClientGUID = cd.ClientGUID
		AND cv.ChartGUID = cd.ChartGUID
	INNER JOIN dbo.CV3ObservationDocument od
		ON cd.GUID = od.OwnerGUID
	INNER JOIN dbo.CV3Observation o
		ON od.ObservationGUID = o.GUID
	INNER JOIN dbo.CV3ObsCatalogMasterItem ocmi
		ON od.ObsMasterItemGUID = ocmi.GUID
	INNER JOIN dbo.CV3User u
		on od.CreatedBy = u.IDCode
	LEFT OUTER JOIN dbo.SCMObsFSListValues fslv
		ON fslv.ParentGUID = od.ObservationDocumentGUID
		AND fslv.ClientGUID = cv.ClientGUID
		AND fslv.Active = 1
	WHERE cd.PatCareDocGUID = @DocGUID
	AND od.Active = 1
	ORDER BY WasteDTM

	SELECT t1.WasteUser, 
		t1.CVGUID, 
		t1.ValueText AS AmtWasted, 
		t1.MRN, t1.WasteDTM, 
		t2.ValueText AS ControlNumber, 
		t3.Value AS Medication,
		@ReportVersion AS ReportVersion,
		@Facility AS Facility
	FROM #temp t1
	LEFT OUTER JOIN #temp t2
		ON t1.DocGUID = t2.DocGUID
		AND t2.ObsCatGUID = @ControlGUID
	LEFT OUTER JOIN #temp t3
		ON t1.DocGUID = t3.DocGUID
		AND t3.ObsCatGUID = @MedicationGUID
	WHERE t1.ObsCatGUID = @AmountGUID
	AND t1.WasteDTM BETWEEN @FromDate AND @ToDate + 1 
END
ELSE
BEGIN   
	SELECT cv.GUID AS CVGUID, 
		cd.GUID AS DocGUID,
		ocmi.GUID AS ObsCatGUID,
		u.DisplayName AS WasteUser, 
		o.ValueText, 
		cv.IDCode AS MRN, 
		cd.AuthoredDTM AS WasteDTM, 
		fslv.Value,
		ocmi.Name
	INTO #temp2
	FROM dbo.CV3ClientVisit cv
	INNER JOIN dbo.CV3ClientDocument cd
		ON cv.GUID = cd.ClientVisitGUID
		AND cv.ClientGUID = cd.ClientGUID
		AND cv.ChartGUID = cd.ChartGUID
	INNER JOIN dbo.CV3ObservationDocument od
		ON cd.GUID = od.OwnerGUID
	INNER JOIN dbo.CV3Observation o
		ON od.ObservationGUID = o.GUID
	INNER JOIN dbo.CV3ObsCatalogMasterItem ocmi
		ON od.ObsMasterItemGUID = ocmi.GUID
	INNER JOIN dbo.CV3User u
		on od.CreatedBy = u.IDCode
	LEFT OUTER JOIN dbo.SCMObsFSListValues fslv
		ON fslv.ParentGUID = od.ObservationDocumentGUID
		AND fslv.ClientGUID = cv.ClientGUID
		AND fslv.Active = 1
	WHERE cd.PatCareDocGUID = @DocGUID
	AND od.Active = 1
	ORDER BY WasteDTM

	SELECT t1.WasteUser, 
		t1.CVGUID, 
		t1.ValueText AS AmtWasted, 
		t1.MRN, t1.WasteDTM, 
		t2.ValueText AS ControlNumber, 
		t3.Value As Medication,
		@ReportVersion AS ReportVersion,
		@Facility AS Facility
	FROM #temp2 t1
	LEFT OUTER JOIN #temp2 t2
		ON t1.DocGUID = t2.DocGUID
		AND t2.ObsCatGUID = @ControlGUID
	LEFT OUTER JOIN #temp2 t3
		ON t1.DocGUID = t3.DocGUID
		AND t3.ObsCatGUID = @MedicationGUID
	WHERE t1.ObsCatGUID = @AmountGUID
	AND t2.ValueText = @Control
END 

/* END OF STORED PROCEDURE */