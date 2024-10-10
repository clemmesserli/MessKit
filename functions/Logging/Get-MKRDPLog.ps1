function Get-MKRDPLog {
  <#
  .SYNOPSIS
  Retrieves a list of unique computers from RDPClient event log.

  .DESCRIPTION
  Retrieves a list of unique computers from RDPClient event log based on the date range provided (Default: Last 7 Days).

  .EXAMPLE
  Get-MKRDPLog
  List unique RDP connections logged for the past 7 days from the current time of script run.

  .EXAMPLE
  Get-MKRDPLog -StartTime (Get-Date).AddDays(-14)
  List unique RDP connections logged from the start date through the current datetime.

  .EXAMPLE
  Get-MKRDPLog -StartTime "01/01/2024" -EndTime "06/23/2024"
  List unique RDP connections logged between Midnight to Midnight for the dates provided.

  .EXAMPLE
  Get-MKRDPLog -StartTime (Get-Date -Year (Get-Date).Year -Month 6 -Day 1) -EndTime (Get-Date -Year (Get-Date).Year -Month 7 -Day 1)
  List unique RDP connections logged between June 01 - July 01 of current year.

  .EXAMPLE
  Get-MKRDPLog -StartTime (Get-Date).Date -EndTime (Get-Date).Date.AddHours(8)
  List unique RDP connections logged between Midnight and 8am using 24-hr notation.

  .EXAMPLE
  $dateRange = [PSCustomObject]@{StartTime = '06/22/2024 01:00:00'; EndTime = '06/22/2024 06:00:00'}
  $dateRange | Get-MKRDPLog
  List unique RDP connections logged between 1am - 6am using a date range object piped into the function.
  #>
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [datetime]$StartTime = ((Get-Date).AddDays(-7)),

    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [datetime]$EndTime = (Get-Date)
  )

  begin {
    $computerNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $regex = [regex]::new("(?<=\()(?:[^()]+)(?=\))", [System.Text.RegularExpressions.RegexOptions]::Compiled)
  }

  process {
    try {
      # Fetch logs within the specified date range
      $logs = Get-WinEvent -FilterHashtable @{
        LogName   = "Microsoft-Windows-TerminalServices-RDPClient/Operational"
        ID        = 1024
        StartTime = $StartTime
        EndTime   = $EndTime
      } -ErrorAction Stop

      $totalLogs = $logs.Count
      $processedLogs = 0

      foreach ($log in $logs) {
        $processedLogs++
        $percentComplete = ($processedLogs / $totalLogs) * 100

        Write-Progress -Activity "Processing RDP Logs" -Status "Processing log $processedLogs of $totalLogs" -PercentComplete $percentComplete

        $computer = $regex.Match($log.Message).Value
        if ($computer) {
          try {
            $resolvedName = [System.Net.Dns]::GetHostByName($computer).HostName
            if ($resolvedName) {
              [void]$computerNames.Add($resolvedName)
            }
          } catch {
            Write-Verbose "Unable to resolve $computer"
          }
        }
      }

      Write-Progress -Activity "Processing RDP Logs" -Completed

      $computerNames | Sort-Object
    } catch {
      if ($_.Exception.GetType().Name -eq 'NoMatchingEventsException') {
        Write-Warning "No events found for the specified date range."
      } else {
        Write-Error -Exception $_.Exception -Message "An error occurred while retrieving logs."
      }
    }
  }
}