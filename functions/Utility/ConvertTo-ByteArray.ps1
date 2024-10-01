Function ConvertTo-ByteArray {
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
		$Encoding = [System.Text.Encoding]::ASCII
		$Encoding.GetBytes($Content)
	}

	End {}
}