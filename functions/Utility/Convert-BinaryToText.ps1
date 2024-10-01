function Convert-BinaryToText {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[string]$Path
	)

	Begin {}

	Process {
		#Embed binaries in PowerShell scripts
		$Bytes = [System.IO.File]::ReadAllBytes($Path)
		[System.Convert]::ToBase64String($Bytes)
	}

	End {}
}