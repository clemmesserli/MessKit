Function Unlock-MKVault {
	[CmdletBinding()]
	Param (
		[String]$SeedFile = (Get-MyParam).'Unlock-MKVault'.SeedFile
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