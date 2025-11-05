function ConvertFrom-Base64 {
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

	ConvertFrom-Base64 -Base64String "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\=" -Encoding UTF8

	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[string]$Base64String,

		[Parameter(ValueFromPipelineByPropertyName)]
		[ValidateSet("Ascii", "BigEndianUnicode", "BigEndianUTF32", "Byte", "Unicode", "UTF32", "UTF7", "UTF8")]
		[string]$Encoding = "UTF8"
	)

	process {
		try {
			# Clean input - remove whitespace and newlines
			$cleanInput = $Base64String -replace '\s', ''
			
			# Handle Base64URL encoding (convert to standard Base64)
			$standardBase64 = $cleanInput.Replace('-', '+').Replace('_', '/')

			# Add padding if needed
			switch ($standardBase64.Length % 4) {
				2 { $standardBase64 += '==' }
				3 { $standardBase64 += '=' }
			}

			$decodedBytes = [System.Convert]::FromBase64String($standardBase64)
			$decodedText = [System.Text.Encoding]::$Encoding.GetString($decodedBytes)
			$decodedText
		} catch {
			Write-Error "Error decoding Base64 string: $_"
		}
	}
}