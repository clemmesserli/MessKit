Function Unlock-MyVault {
	[CmdletBinding()]
	Param (
		[String]$SeedFile = (Get-MyParam).'Unlock-MyVault'.SeedFile
	)

	Begin {}

	Process {
		$params = @{
			Password        = (ConvertTo-SecureString -AsPlainText -Force (Unprotect-CmsMessage -Path "$SeedFile" ))
			PasswordTimeout = 28800
		}
		Unlock-SecretStore @params
	}

	End {}
}