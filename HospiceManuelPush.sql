--USE [HOSP_COMP]
--GO
--ALTER PROCEDURE [dbo].[BH_Report_HOSPPCNames_Sp]
--AS

INSERT INTO  dbo.Hosp_PC_Names
SELECT TOP 1000 * FROM OpenQuery ( 
ADSI, 
'SELECT NAME
FROM ''LDAP://OU=BCS Workstations,OU=BCS,OU=Blessing,DC=adbcs,DC=blessinghospital,DC=com'' 
WHERE objectClass = ''Computer'' 
') AS tblADSI
WHERE NAME LIKE 'HOSP%'

INSERT INTO dbo.Hosp_PC_Names
SELECT TOP 1000 * FROM OpenQuery ( 
ADSI, 
'SELECT NAME
FROM ''LDAP://OU=BCS Laptops,OU=BCS,OU=Blessing,DC=adbcs,DC=blessinghospital,DC=com'' 
WHERE objectClass = ''Computer''
') AS tblADSI
WHERE NAME LIKE 'HOSP%'

SELECT * FROM dbo.Hosp_PC_Names