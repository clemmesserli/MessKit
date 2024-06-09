Function ConvertFrom-Base64 {
	<#
	.SYNOPSIS
	Converts a Base64 encoded string to plain text using the specified encoding.

	.DESCRIPTION
	This function takes a Base64 encoded string as input and decodes it to plain text using the specified encoding.
	The default encoding is UTF8.

	.PARAMETER Base64String
	The Base64 encoded string to be decoded.

	.PARAMETER Encoding
	The encoding to be used for decoding the Base64 string.
	Supported values: Ascii, BigEndianUnicode, BigEndianUTF32, Byte, Unicode, UTF32, UTF7, UTF8

	.EXAMPLE
	ConvertFrom-Base64 -Base64String "SGVsbG8gV29ybGQh" -Encoding UTF8
	# Output: "Hello World"
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Base64String,

		[Parameter(ValueFromPipelineByPropertyName)]
		[ValidateSet("Ascii", "BigEndianUnicode", "BigEndianUTF32", "Byte", "Unicode", "UTF32", "UTF7", "UTF8")]
		[String]$Encoding = "UTF8"
	)

	Process {
		try {
			$decodedBytes = [System.Convert]::FromBase64String($Base64String)
			$decodedText = [System.Text.Encoding]::$Encoding.GetString($decodedBytes)
			$decodedText
		} catch {
			Write-Error "Error decoding Base64 string: $_"
		}
	}
}