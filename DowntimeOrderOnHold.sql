--USE [SXADowntimeDB]
--GO
--/****** Object:  StoredProcedure [dbo].[BH_DownTime_Report_OrdersOnHold_Sp]    Script Date: 9/16/2014 9:10:55 AM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--ALTER PROCEDURE [dbo].[BH_DownTime_Report_OrdersOnHold_Sp](
--	@LocationName	VARCHAR(50)
--) AS

/*****************************************************************************************************/
/**                                B L E S S I N G   H O S P I T A L                                **/
/**-------------------------------------------------------------------------------------------------**/
/**	Description:																					**/
/**-------------------------------------------------------------------------------------------------**/
/** Return a list of orders for a given location.													**/
/**=================================================================================================**/
/** Created: 02/01/08		SXA Ver: 4.5		Author: Paul Slater									**/
/**=================================================================================================**/
/**	Mod		Date		Pgmr		Details															**/
/**-------------------------------------------------------------------------------------------------**/
/**=================================================================================================**/
/*****************************************************************************************************/

--SET NOCOUNT ON

---- Open key for decryption
--OPEN SYMMETRIC KEY bA04Ut2_DTK
--DECRYPTION BY CERTIFICATE bA04Ut2_DTC

--DECLARE @LocationName VARCHAR(50) = 'One Day Surgery'

SELECT 
	avl.*,
	avl.ClientGUID,
	avl.GUID AS ClientVisitGUID,
	avl.IDCode,
	avl.VisitIDCode,
	CONVERT(VARCHAR(250),DECRYPTBYKEY(avl.ClientDisplayName)) AS ClientDisplayName,
	avl.AdmitDtm,
	avl.VisitReason,
	avl.GenderCode,
	avl.CurrentLocation,
	CONVERT(INT,CONVERT(VARCHAR(250),DECRYPTBYKEY(avl.BirthYearNum))) AS BirthYearNum,
	CONVERT(INT,CONVERT(VARCHAR(250),DECRYPTBYKEY(avl.BirthMonthNum))) AS BirthMonthNum,
	CONVERT(INT,CONVERT(VARCHAR(250),DECRYPTBYKEY(avl.BirthDayNum))) AS BirthDayNum,
	o.IDCode AS OrderIDCode,
	o.Name AS OrderName,
	o.SummaryLine,
	o.RequestedTime,
	o.SignificantDtm,
	o.Description,
	c.Code
FROM dbo.BH_DownTime_System_Orders o (NOLOCK)
INNER JOIN dbo.BH_DownTime_System_Categories c (NOLOCK)
	ON c.GUID = o.OrderCatalogMasterItemGUID
	AND o.OrderStatusCode = 'HOLD'
INNER JOIN dbo.BH_DownTime_System_ActiveVisitList avl (NOLOCK)
	ON avl.ClientGUID = o.ClientGUID
	AND avl.GUID = o.ClientVisitGUID
	--AND avl.VisitStatus <> 'PRE'
	AND avl.Active = 1
INNER JOIN dbo.BH_DownTime_System_Location l (NOLOCK)
	ON l.GUID = avl.CurrentLocationGUID
WHERE
--l.Name = @LocationName
c.Code NOT IN ('Pharmacy','Pharmacy IV')

-- Close decryption key
--CLOSE SYMMETRIC KEY bA04Ut2_DTK


