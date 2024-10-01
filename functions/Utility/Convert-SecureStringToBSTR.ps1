Function Convert-SecureStringToBSTR {
	<#
	.EXAMPLE
		$string = Read-Host -Prompt 'Enter password' -AsSecureString
		$plainText = Convert-SecureStringToText -String $string
	.EXAMPLE
		$PSCred = Get-Credential -UserName $env:USERNAME -Message 'Enter your password'
		$plainText = Convert-SecureStringToText -String $PSCred.Password
	.EXAMPLE
		Convert-SecureStringToText -String (Get-Secret demostring)
		First retrieves a secure string from Secret Vault and then converts to plain text
		Note:  Equivalent to (Get-Secret demostring -AsPlainText)
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Security.SecureString]
		$String
	)

	Begin {}

	Process {
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($String)
		[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
	}

	End {}
}