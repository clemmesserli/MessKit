Function Get-RDPState {
	<#
	.SYNOPSIS
		Returns RDP status (Active/Disconnected) for the user credential provided
	.DESCRIPTION
		Returns RDP status (Active/Disconnected) for the user credential provided or returns an error if unable to access.
	.EXAMPLE
		Get-RDPState -Credential $Credential -ComputerName server01
		Retrieve RDP info for a single computer
	.EXAMPLE
		Get-RDPState -Credential $Credential -ComputerName server01, server02
		Retrieve RDP info for a multiple computers
	.EXAMPLE
		Get-RDPState -Credential $Credential -ComputerName (Get-RDPLog -StartTime 1/01/2022 -EndTime 1/07/2022)
		Combine with Get-RDPLog to return RDP info for dynamic list of computers based on recent event log info
	#>
	[CmdletBinding()]
	Param (
		[ValidateNotNull()]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		[Alias("RunAs")]
		$Credential,

		[Parameter(ValueFromPipelineByPropertyName)]
		[string[]]$ComputerName
	)

	Begin {}

	Process {
		foreach ($computer in $ComputerName) {
			$dnsName = (Resolve-DnsName -Name $computer).name
			Try {
				Invoke-Command -ComputerName $dnsName -Credential $Credential -ScriptBlock {
					$query = (quser) -ireplace '\s{2,}', ',' 2>&1
					if ($Query -match "ID") {
						$query | ConvertFrom-Csv | Where-Object username -EQ $($using:Credential.userName)
					} else {
						"$($using:dnsName) : No Logged On Users"
					}
				}
			} Catch {
				Write-Error "No Remote RDP Session found or access denied when connecting to $computer."
			}
		}
	}

	End {}
}