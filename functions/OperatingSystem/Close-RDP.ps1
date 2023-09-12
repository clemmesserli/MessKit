Function Close-RDP {
	<#
	.SYNOPSIS
		Close one or more RDP sessions
	.DESCRIPTION
		Close one or more RDP sessions using PowerShell PSCredential for authentication.
		The list of computers can be dynamically queried from local machine event log or statically provided.
	.EXAMPLE
		Close-RDP -Credential $Credential -ComputerName server01
	.EXAMPLE
		Close-RDP -Credential $Credential -ComputerName (Get-RDPLog -StartTime 1/01/2022 -EndTime 1/08/2022)
		Close any active or disconnected RDP sessions as found in local machine event log between the dates entered
	.EXAMPLE
		Close-RDP -Credential $Credential -ComputerName (Get-Content ./private/servers.txt)
	.EXAMPLE
		$param = @{
			Credential = $Credential
			ComputerName = @(
				"server01",
				"server02",
				"server03"
			)
			Verbose = $true
		}
		Close-RDP @param
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
		foreach ($computer in $ComputerName) {
			$dnsName = (Resolve-DnsName -Name $computer).name
			Try {
				# Find current RDP process and close on local machine
				Get-Process | Where-Object { $_.MainWindowTitle -match $dnsName.split('.')[0] } | Stop-Process

				# Issue remote command to logoff (not disconnect) user if session is found
				Invoke-Command -ComputerName $dnsName -Credential $Credential -ScriptBlock {
					$rdp = (quser) -ireplace '\s{2,}', ',' | ConvertFrom-Csv | Where-Object username -EQ $($using:Credential.userName)
					logoff $rdp.sessionname
				} -ErrorAction SilentlyContinue

				# Clean up and credentials that may have been stored for this RDP session
				$results = cmdkey.exe /delete:$computer
				$msg = $results.replace("CMDKEY: ")
				Write-Verbose "msg: $msg"
			} Catch {
				Write-Verbose "No Remote RDP Session found or access denied for $computer."
			}
		}
	}

	End {}
}
