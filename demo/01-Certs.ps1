<#
 - Run this file on our WebServer
 - Export DocumentEncryption & ClientAuth certs
	* import public + private keys to client01
	* import only public certs to client02
#>

#region 01 - Creating our RootCA
New-LabCert -CertType "Root" -Subject "MyLabRootCA" -Days 365
#endregion 01

#region 02 - Creating our IssuerCA
New-LabCert -CertType "Intermediate" -Subject "MyLabIssuerCA" -Days 365 -Issuer "MyLabRootCA"
#endregion 02

#region 03 - Creating our certificate for document encryption
## Note: In a production scenario this would be generated on a protected machine and the 'Exportable' option disabled when importing to work machines
New-LabCert -CertType "DocumentEncryption" -CertStore "CurrentUser" -Subject "MyLabDocEncryption" -Days 365 -Issuer "MyLabIssuerCA" #-NonExportable
#endregion 03

#region 04 - Creating our certificate for client authentication
$certParams = @{
	CertStore     = "CurrentUser"
	CertType      = "ClientAuth"
	Days          = 30
	NonExportable = $true
	Issuer        = "MyLabIssuerCA"
	Subject       = "CN=LabAdmin,OU=Users,DC=messlabs,DC=com"
	TargetDomain  = "lab04.messlabs.com"
	UPN           = "LabAdmin@messlabs.com"
}
New-LabCert @certParams

$certParams = @{
	CertStore     = "CurrentUser"
	CertType      = "ClientAuth"
	Days          = 30
	NonExportable = $false
	Issuer        = "MyLabIssuerCA"
	Subject       = "CN=HelpDeskUser,OU=Users,DC=messlabs,DC=com"
	TargetDomain  = "lab04.messlabs.com"
	UPN           = "HelpDeskUser@messlabs.com"
}
New-LabCert @certParams
#endregion 04

#region 05 - Creating a website certificate for Hashicorp Vault
$certParams = @{
	CertType = "Web"
	Subject = "myvault.messlabs.com"
	SubjectAltName = @(
		"myvault",
		"L4WS1901.messlabs.com",
		"L4WS1901"
		)
	Days = 365
	Issuer = "MyLabIssuerCA"
}
New-LabCert @certParams
#endregion