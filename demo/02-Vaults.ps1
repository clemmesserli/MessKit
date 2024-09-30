<#
- Due to time constraints, we will briefly touch on SecretStore & HashiCorp
- KeePass, AZKeyVault, AWS KMS are all additional options among several others
#>

#region Microsoft SecretStore
$securePasswordPath = "C:\LabSources\PSVault.xml"
New-Password -PwdLength 24 | Export-Clixml -Path $securePasswordPath

Register-SecretVault -Name 'PSVault3' -ModuleName 'Microsoft.PowerShell.SecretStore' -DefaultVault
$password = Import-Clixml -Path $securePasswordPath

$storeConfiguration = @{
	Authentication  = 'Password'
	PasswordTimeout = 1800 # 30 min
	Interaction     = 'None'
	Password        = (ConvertTo-SecureString $password -AsPlainText -Force)
	Confirm         = $false
}
Set-SecretStoreConfiguration @storeConfiguration

# Import the masterkey and unlock vault
$password = Import-Clixml -Path $securePasswordPath
Unlock-SecretStore -Password $password
#endregion
