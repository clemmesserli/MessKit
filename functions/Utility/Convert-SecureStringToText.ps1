function Convert-SecureStringToText {
	<#
	.EXAMPLE
		$password = Read-Host -Prompt 'Enter password' -AsSecureString
		$plain = Convert-SecureStringToText -Password $password

	.EXAMPLE
		$cred = Get-Credential -UserName $env:USERNAME -Message 'Enter your password'
		$plain = Convert-SecureStringToText -Password $cred.Password

	.EXAMPLE
		$cred = Get-Credential -UserName $env:USERNAME -Message 'Enter your password'
		$plain = $cred.GetNetworkCredential().Password
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Security.SecureString]
		$Password
	)

	Begin {}

	Process {
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
		[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
	}

	End {}
}