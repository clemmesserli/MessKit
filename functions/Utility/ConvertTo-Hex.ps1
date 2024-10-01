Function ConvertTo-Hex {
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'String')]
		[String]$String,

		[Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'File')]
		[ValidateScript( { Test-Path $_ })]
		[String]$FilePath
	)

	Begin {}

	Process {
		switch ($PsCmdlet.ParameterSetName) {
			"String" {
				$Content = $String
			}
			"File" {
				$Content = [System.IO.File]::ReadAllLines( ( Resolve-Path $FilePath ) )
			}
		}

		$hex = ""
		$Content.ToCharArray() | ForEach-Object -Process {
			$hex += '{0:X}' -f [Int][char]$_
		}
		$hex
	}

	End {}
}