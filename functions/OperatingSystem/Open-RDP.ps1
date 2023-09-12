Function Open-RDP {
	<#
	.SYNOPSIS
		Open one or more RDP sessions
	.DESCRIPTION
		Open one or more RDP sessions using PowerShell PSCredential for authentication.
	.EXAMPLE
		Open-RDP Credential $Credential ComputerName "server01"
	.EXAMPLE
		$params = @{
			Credential = $Credential
			ComputerName = @("server01", "server02", "server03")
			Verbose = $true
		}
		Open-RDP @params
	.NOTES
		If your default RDP profile has 'Always ask for credentials' checked,
		you will still need to input the appropriate password when prompted as each RDP window is launched.
	#>
	[CmdletBinding()]
	Param (
		[ValidateNotNull()]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		[Alias("RunAs")]
		$Credential,

		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[string[]]$ComputerName
	)

	Begin {}

	Process {
		$userName = $Credential.GetNetworkCredential().UserName
		$password = $Credential.GetNetworkCredential().Password

		foreach ($computer in $ComputerName) {
			# Resolve fqdn to avoid issues connecting to boxes in alternate domains
			$dnsName = (Resolve-DnsName -Name $computer).name

			# Create a RDP credential using the PSCredential param input
			$results = cmdkey.exe /generic:$dnsName /user:$userName /pass:$password
			Write-Verbose "$dnsName : $results"

			# Launch RDP window using Microsoft Terminal Services Client
			mstsc.exe /v:$dnsName /f

			# Add delay simply to allow user to click the 'OK' inside each RDP terminal upon first launch
			Start-Sleep -Seconds 10
		}
	}

	End {}
}