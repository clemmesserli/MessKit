function ConvertFrom-MKSecureStringToText {
	<#
	.SYNOPSIS
	Converts a secure string back to plain text.

	.DESCRIPTION
	Converts a secure string back to plain text.

	.PARAMETER SecureString
	The encrypted SecureString object you wish to convert back to plain text.

	.EXAMPLE
	$password = Read-Host -Prompt 'Enter password' -AsSecureString
	$plain = ConvertFrom-MKSecureStringToText -SecureString $password

	.EXAMPLE
	$cred = Get-Credential -UserName $env:USERNAME -Message 'Enter your password'
	$plain = ConvertFrom-MKSecureStringToText -SecureString $cred.Password

	.EXAMPLE
	ConvertFrom-MKSecureStringToText -SecureString (Get-Secret demostring)
	First retrieves a secure string from Secret Vault and then converts to plain text
	Note:  Equivalent to (Get-Secret demostring -AsPlainText)
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Security.SecureString]
		$SecureString
	)

	process {
		try {
			$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($SecureString)
			$plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
			[System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr)
			return $plainText
		} catch {
			Write-Error "An error occurred during the conversion process: $_"
		}
	}
}