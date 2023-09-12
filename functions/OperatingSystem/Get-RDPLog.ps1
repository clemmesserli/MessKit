Function Get-RDPLog {
	<#
	.SYNOPSIS
		Retrieves a list of unique computers from RDPClient event log
	.DESCRIPTION
		Retrieves a list of unique computers from RDPClient event log based upon date range provided (Default: Last (7) Days)
	.EXAMPLE
		Get-RDPLog
		List unique RDP connections logged for past 7 days from current time of script run
	.EXAMPLE
		Get-RDPLog -StartTime "01/01/2022"
		List unique RDP connections logged from start date through current datetime
	.EXAMPLE
		Get-RDPLog -StartTime "01/01/2022" -EndTime "01/02/2022"
		List unique RDP connections logged between Midnight to Midnight for dates provided
	.EXAMPLE
		Get-RDPLog -StartTime "01/01/2022 08:00:00 AM" -EndTime "01/01/2022 05:00:00 PM"
		List unique RDP connections logged between 8-5 using 12-hr notation
	.EXAMPLE
		Get-RDPLog -StartTime "01/01/2022 08:00:00" -EndTime "01/01/2022 17:00:00"
		List unique RDP connections logged between 8-5 using 24-hr notation
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipelineByPropertyName)]
		[datetime]$StartTime = ((Get-Date).AddDays(-7)),

		[Parameter(ValueFromPipelineByPropertyName)]
		[datetime]$EndTime = (Get-Date)
	)

	Begin {}

	Process {
		Try {
			$Logs = Get-WinEvent -FilterHashtable @{
				LogName   = "Microsoft-Windows-TerminalServices-RDPClient/Operational"
				ID        = 1024
				StartTime = "$($StartTime)"
				EndTime   = "$($EndTime)"
			} -ErrorAction Stop

			$Regex = [Regex]::new("(?<=\()(.*)(?=\))")
			$ComputerName = @()
			foreach ($log in $logs) {
				$computer = $Regex.Match($Log.Message).Value.tolower()
				Try {
					$ComputerName += [System.Net.Dns]::GetHostByName("$computer").HostName
				} Catch {
					Write-Debug "Unable to resolve $computer"
				}
			}
			$ComputerName | Sort-Object -Unique
		} Catch {
			Write-Error "No computers found for Date Range provide `nStartTime: $starttime `nEndTime: $endtime"
		}
	}

	End {}
}