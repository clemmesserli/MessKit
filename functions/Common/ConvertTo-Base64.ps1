Function ConvertTo-Base64 {
	<#
		.SYNOPSIS
		Converts a string to its Base64 encoded representation.

		.DESCRIPTION
		This function takes a string as input and Base64 encodes it using the specified encoding.
		The default encoding is UTF8.

		.PARAMETER String
		The string to be encoded (mandatory).

		.PARAMETER Encoding
		The text encoding to use (optional, defaults to "UTF8").
		Supported values: Ascii, BigEndianUnicode, BigEndianUTF32, Byte, Unicode, UTF32, UTF7, UTF8

		.EXAMPLE
		"Hello World" | ConvertTo-Base64
		# Output: SGVsbG8gV29ybGQ=

		.NOTES
		Enhanced by Codiumate
    #>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[string]$String,

		[Parameter(ValueFromPipelineByPropertyName)]
		[ValidateSet("Ascii", "BigEndianUnicode", "BigEndianUTF32", "Byte", "Unicode", "UTF32", "UTF7", "UTF8")]
		[string]$Encoding = "UTF8"
	)

	Process {
		try {
			$encodedBytes = [System.Text.Encoding]::$encoding.GetBytes($String)
			$encodedText = [System.Convert]::ToBase64String($encodedBytes)
			$encodedText
		} catch {
			Write-Error "Error converting string: $_ to Base64"
		}
	}
}