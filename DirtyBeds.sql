USE [TEST]
GO
/****** Object:  StoredProcedure [dbo].[BH_SSRS_Report_DirtyBeds_Sp]    Script Date: 3/20/2013 10:20:23 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[BH_SSRS_Report_DirtyBeds_Sp] (
	@JobID	INT 
) AS

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
/**	Description: Gives the list of dirty beds on all the floors/departments.						**/
/**-------------------------------------------------------------------------------------------------**/
/**	Created FROM original XXX for SCM5.5 upgrade													**/
/**	Made some changes for migration and table index usage but additional changes would				**/
/**	require	clinical use analysis																	**/
/**-------------------------------------------------------------------------------------------------**/
/** Created: 07/05/2007		SXA Version: 4.0		Work Item: N/A		Author: Jeremy Walker		**/
/**=================================================================================================**/
/**	Mod		WI#			Date		Pgmr		Details												**/
/**-------------------------------------------------------------------------------------------------**/
/**	 *		1385		10/27/10	RMZ			5.5 Conversion										**/
/**  A					09/30/11	TLS			Remove beds with holding in name					**/
/**  B		1395		3/20/13		MPM			Added date range									**/
/**=================================================================================================**/
/*****************************************************************************************************/
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--DECLARE @JobID INT SET @JobID = 846823000

DECLARE @tmpDirtyBeds TABLE 
(
	Department	VARCHAR(250),
	RoomNumber	VARCHAR(150),
	RoomStatus	VARCHAR(15),
	RoomChange	DATETIME
)

DECLARE @tmpOccuppiedBeds TABLE 
(
	Department	VARCHAR(250),
	RoomNumber 	VARCHAR(150)
)

DECLARE
	 @Facility		VARCHAR(10)
	,@ReportVersion	VARCHAR(200)
	,@HVCFromDate	DATETIME --B
	,@HVCToDate		DATETIME --B

SELECT
	 @Facility		= dbo.BH_WorkstationFacility_Fn(@JobID)
	,@ReportVersion	= dbo.BH_ReportVersion_Fn(@JobID)
	,@HVCFromDate	= dbo.BH_GetDateTime_Fn(@JobID,'HVCFromDate') --B
	,@HVCToDate	= dbo.BH_GetDateTime_Fn(@JobID,'HVCToDate12am') --B
	--,@HVCFromDate	= '01/02/1900' --B
	--,@HVCToDate	= '01/02/1900' --B
	--,@HVCFromDate	= '03/18/2013' --B
	--,@HVCToDate	= '03/18/2013' --B


IF @HVCFromDate = '01/02/1900' AND @HVCToDate = '01/02/1900' BEGIN --B
INSERT INTO @tmpDirtyBeds
SELECT 
	 l.Name AS Department
	,ebcx1.ColumnDisplayValue
	,ebcx.ColumnDisplayvalue AS DirtyBed
	,(SELECT TOP 1 la.CreatedWhen FROM dbo.SXAEDLocationAudit la (NOLOCK)
	  WHERE la.LocationGUID = eb.EDLocationGUID AND la.ColumnNewValue = 'Dirty' AND la.ColumnName = 'STS' 
	  ORDER BY la.CreatedWhen DESC) CreatedWhen	
FROM 
	dbo.SXAEDBoard eb (nolock)
	INNER JOIN dbo.SXAEDBoardColumnXREF ebcx (nolock)
		ON eb.BoardID = ebcx.BoardID
	INNER JOIN dbo.SXAEDColumn ec (nolock)
		ON ebcx.ColumnID = ec.ColumnID
	INNER JOIN dbo.SXAEDLocation el (nolock) 
		ON eb.EDLocationGUID = el.LocationGUID
	INNER JOIN dbo.CV3Location l(nolock)
		ON el.EDParentLocGUID = l.GUID 
	INNER JOIN dbo.SXAEDBoardColumnXREF ebcx1 (nolock)
		ON eb.BoardID = ebcx1.BoardID
	INNER JOIN dbo.SXAEDColumn ec1 (nolock)
		ON ebcx1.ColumnID = ec1.ColumnID
	INNER JOIN dbo.CV3Location facilityloc (NOLOCK)
		ON facilityloc.GUID = l.ParentGUID

WHERE 
	eb.active = 1
	AND ec.isactive = 1
	AND ec.columnDisplayName = 'STS'    
	AND ebcx.ColumnDisplayValue = 'Dirty'
	and ebcx1.ColumnDisplayValue not like '%Holding%' -- A
	AND ec1.ColumnName = 'Location'
	AND @Facility = CASE facilityloc.Name WHEN 'Illini Community Hospital' THEN 'ICH' ELSE 'BH' END
END

/** Start of B **/
ELSE BEGIN
INSERT INTO @tmpDirtyBeds
SELECT 
	 l.Name AS Department
	,ebcx1.ColumnDisplayValue
	,ebcx.ColumnDisplayvalue AS DirtyBed
	,la.CreatedWhen AS CreatedWhen 

FROM 
	dbo.SXAEDBoard eb (nolock)
	INNER JOIN dbo.SXAEDBoardColumnXREF ebcx (nolock)
		ON eb.BoardID = ebcx.BoardID
	INNER JOIN dbo.SXAEDColumn ec (nolock)
		ON ebcx.ColumnID = ec.ColumnID
	INNER JOIN dbo.SXAEDLocation el (nolock) 
		ON eb.EDLocationGUID = el.LocationGUID
	INNER JOIN dbo.CV3Location l(nolock)
		ON el.EDParentLocGUID = l.GUID 
	INNER JOIN dbo.SXAEDBoardColumnXREF ebcx1 (nolock)
		ON eb.BoardID = ebcx1.BoardID
	INNER JOIN dbo.SXAEDColumn ec1 (nolock)
		ON ebcx1.ColumnID = ec1.ColumnID
	INNER JOIN dbo.CV3Location facilityloc (NOLOCK)
		ON facilityloc.GUID = l.ParentGUID
	FULL OUTER JOIN dbo.SXAEDLocationAudit la (NOLOCK)
		ON la.LocationGUID = el.LocationGUID
WHERE 
	eb.active = 1
	AND ec.isactive = 1
	AND ec.columnDisplayName = 'STS'    
	AND ebcx.ColumnDisplayValue = 'Dirty'
	and ebcx1.ColumnDisplayValue not like '%Holding%' -- A
	AND ec1.ColumnName = 'Location'
	AND @Facility = CASE facilityloc.Name WHEN 'Illini Community Hospital' THEN 'ICH' ELSE 'BH' END
	AND la.LocationGUID = eb.EDLocationGUID 
	AND la.ColumnNewValue = 'Dirty' 
	AND la.ColumnName = 'STS' 
	AND l.name NOT LIKE 'Emergency Department'
  ORDER BY la.CreatedWhen DESC
END
/** End of B **/

INSERT INTO @tmpOccuppiedBeds
SELECT l.Name AS Department,ebcx.ColumnDisplayValue FROM dbo.SXAEDBoard eb (nolock)
INNER JOIN dbo.CV3ClientVisit cv (nolock) ON cv.GUID = eb.ClientVisitGUID
INNER JOIN dbo.SXAEDLocation el (nolock) ON eb.EDLocationGUID = el.LocationGUID
INNER JOIN dbo.CV3Location l (nolock) ON el.EDParentLocGUID = l.GUID 
INNER JOIN dbo.SXAEDBoardColumnXREF ebcx (nolock) ON eb.BoardID = ebcx.BoardID
INNER JOIN dbo.SXAEDColumn ec (nolock) ON ebcx.ColumnID = ec.ColumnID
INNER JOIN dbo.CV3Location facilityloc (NOLOCK) ON facilityloc.GUID = l.FacilityGUID
WHERE eb.active = 1 AND ec.ColumnName = 'Location'
AND @Facility = CASE facilityloc.Name WHEN 'Illini Community Hospital' THEN 'ICH' ELSE 'BH' END

IF @HVCFromDate = '01/02/1900' AND @HVCToDate = '01/02/1900' BEGIN  --B
SELECT
	 @Facility Facility
	,@ReportVersion ReportVersion
	,db.*
FROM 
	@tmpDirtyBeds db
	LEFT OUTER JOIN @tmpOccuppiedBeds ob
		ON ob.Department = db.Department
		AND ob.RoomNumber = db.RoomNumber
WHERE 
	ob.RoomNumber IS NULL
ORDER BY 
	db.Department ASC
END

/** Start of B **/
ELSE BEGIN
SELECT
	 @Facility Facility
	,@ReportVersion ReportVersion
	,db.*
FROM 
	@tmpDirtyBeds db
	LEFT OUTER JOIN @tmpOccuppiedBeds ob
		ON ob.Department = db.Department
		AND ob.RoomNumber = db.RoomNumber
WHERE 
	ob.RoomNumber IS NULL
	AND RoomChange >= @HVCFromDate --B
	AND RoomChange < @HVCToDate +1 --B
ORDER BY 
	db.Department ASC
	,RoomChange
END
/** End of B **/