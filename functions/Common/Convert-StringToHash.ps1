Function Convert-StringToHash {
	<#
	.SYNOPSIS
		Convert a string into a hash
	.DESCRIPTION
		Convert a string into a hash using a memorizing stream rather than wasting time saving to file and then using Get-FileHash.
		A hash is a way to uniquely identify a text without exposing the actual text.
		Hashes are used to identify strings of text, find duplicate file content, and validate passwords.
	.EXAMPLE
		Convert-StringToHash 'The Quick Brown Fox.'
	.EXAMPLE
		$string1 = Convert-StringToHash 'The Quick Brown Fox.'
		$string2 = Convert-StringToHash 'the quick brown fox.'
		Compare-Object $string1.hash $string2.hash
	.EXAMPLE
		(Get-Content ./private/names.txt) | Foreach-Object { ConvertTo-TitleCase -String $_ }
		Accepts a file with list of users or books and will convert each row
	.LINK
		https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-hashes-from-text
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[String]$String
	)

	Begin {}

	Process {
		$stream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($String))
		$hash = Get-FileHash -InputStream $stream -Algorithm SHA1
		$stream.Close()
		$stream.Dispose()

		$hash
	}

	End {}
}
