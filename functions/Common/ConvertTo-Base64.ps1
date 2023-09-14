Function ConvertTo-Base64 {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$string,

		[Parameter(ValueFromPipelineByPropertyName)]
		[ValidateSet("Ascii", "BigEndianUnicode", "BigEndianUTF32", "Byte", "Unicode", "UTF32", "UTF7", "UTF8")]
		[String]$encoding = "UTF8"
	)

	Begin {}

	Process {
		$encodedBytes = [System.Text.Encoding]::$encoding.GetBytes($string)
		$encodedText = [System.Convert]::ToBase64String($encodedBytes)
		$encodedText
	}

	End {}
}