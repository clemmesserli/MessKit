function Convert-TextToBinary {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[string]
		$Text,

		[Parameter(Mandatory)]
		[string]
		$OutputPath
	)

	Begin {}

	Process {
		#Embed binaries in PowerShell scripts
		$Bytes = [System.Convert]::FromBase64String($Text)
		[System.IO.File]::WriteAllBytes($OutputPath, $Bytes)
	}

	End {}
}