Function Convert-StringToHash {
	[CmdletBinding()]
	Param (
		[String]$String = 'this is the text that you want to convert into a hash'
	)

	Begin {}

	Process {
		<#
			https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-hashes-from-text
			A hash is a way to uniquely identify a text without exposing the actual text.
			Hashes are used to identify strings of text, find duplicate file content, and validate passwords.
			PowerShell 5 and better even comes with a cmdlet to calculate hash values for files: Get-FileHash.

			However, Get-FileHash has no way of calculating hashes from strings.
			Instead of saving string values to file just to calculate the hash value, you can use a so-called memory stream instead.
			Here is a piece of code that calculates a hash from any string:
		#>
		$stream = [IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($String))
		$hash = Get-FileHash -InputStream $stream -Algorithm SHA1
		$stream.Close()
		$stream.Dispose()

		$hash
	}

	End {}
}
