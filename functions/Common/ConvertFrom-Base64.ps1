Function ConvertFrom-Base64 {
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
		$decodedBytes = [System.Convert]::FromBase64String($string)
		$decodedText = [System.Text.Encoding]::$encoding.GetString($decodedBytes)
		$decodedText
	}

	End {}
}
