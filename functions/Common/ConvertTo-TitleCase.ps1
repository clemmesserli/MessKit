Function ConvertTo-TitleCase {
	<#
	.SYNOPSIS
		Takes a string of raw text and converts first letter of each word to upper case
	.DESCRIPTION
		Takes a string of raw text and converts first letter of each word to upper case.  All other letters will be lower case.
	.EXAMPLE
		ConvertTo-TitleCase -String "jane doe"
		Upper case first letter of each word.
	.EXAMPLE
		ConvertTo-TitleCase -String "THE quick Brown FoX" -Verbose
		Upper case first letter of each word.  Lower case all other letters.
	.EXAMPLE
		(Get-Content ./private/names.txt) | Foreach-Object { ConvertTo-TitleCase -String $_ }
		Accepts a file with list of users or books and will convert each row
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[String]$String
	)

	Begin {}

	Process {
		$textInfo = (Get-Culture).TextInfo

		Write-Verbose "Original Text:`t $($textInfo.ToTitleCase($String))"

		$textInfo.ToTitleCase($String.ToLower())
	}

	End {}
}