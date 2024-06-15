Function ConvertTo-TitleCase {
	<#
		.SYNOPSIS
		Converts the first letter of each word in a string to uppercase and all other letters to lowercase.

		.DESCRIPTION
		This function takes a string of raw text and converts the first letter of each word to uppercase and all other letters to lowercase.

		.EXAMPLE
		ConvertTo-TitleCase -String "jane doe"
		Converts "jane doe" to "Jane Doe".

		.EXAMPLE
		ConvertTo-TitleCase -String "THE quick Brown FoX", "COW JUMPED OVER THE MOON!"
		Converts "THE quick Brown FoX" and "COW JUMPED OVER THE MOON!" to title case.

		.EXAMPLE
		(Get-Content ./private/names.txt) | ConvertTo-TitleCase
		Accepts a file with a list of strings or content and converts each line to title case
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[AllowEmptyString()]
		[String[]]$String
	)

	Process {
		$textInfo = (Get-Culture).TextInfo
		try {
			Write-Verbose "Original Text:`t $($textInfo.ToTitleCase($String))"
			$String | ForEach-Object {
				if (-not [string]::IsNullOrWhiteSpace($_)) {
					$textInfo.ToTitleCase($_.ToLower())
				}
			}
		} catch {
			Write-Error "An error occurred during the conversion process: $_"
		}
	}
}