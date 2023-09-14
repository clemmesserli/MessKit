function Convert-SecureStringToText {
	<#
	.EXAMPLE
		$password = Read-Host -Prompt 'Enter password' -AsSecureString
		$plain = Convert-SecureStringToText -SecureString $password

	.EXAMPLE
		$cred = Get-Credential -UserName $env:USERNAME -Message 'Enter your password'
		$plain = Convert-SecureStringToText -SecureString $cred.Password

	.EXAMPLE
		Convert-SecureStringToText -SecureString (Get-Secret demostring)
		First retrieves a secure string from Secret Vault and then converts to plain text
		Note:  Equivalent to (Get-Secret demostring -AsPlainText)
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Security.SecureString]
		$SecureString
	)

	Begin {}

	Process {
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
		[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
	}

	End {}
}