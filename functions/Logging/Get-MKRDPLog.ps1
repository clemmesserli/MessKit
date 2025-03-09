function Get-MKRDPLog {
  <#
  .SYNOPSIS
    Retrieves a list of unique computers from RDPClient event log.

  .DESCRIPTION
    The Get-MKRDPLog function extracts RDP connection information by:
    - Querying the Windows Terminal Services RDPClient Operational event log
    - Filtering for successful connection events (Event ID 1024)
    - Extracting target computer names from event message data
    - Resolving hostnames to FQDN where possible
    - Removing duplicate entries to provide a unique computer list
    - Supporting custom date ranges for targeted queries

    This function is useful for auditing RDP connection history, security analysis,
    and providing input to other MessKit RDP management functions.

  .PARAMETER StartTime
    The beginning of the time period to search for RDP connections.
    Default is 7 days before the current time if not specified.
    Accepts pipeline input by property name for integration with date range objects.

  .PARAMETER EndTime
    The end of the time period to search for RDP connections.
    Default is the current time if not specified.
    Accepts pipeline input by property name for integration with date range objects.

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

  .NOTES
    File Name      : Get-MKRDPLog.ps1
    Author         : MessKit
    Requires       : PowerShell 5.1 or later
    Version        : 1.0

    This function requires access to the Microsoft-Windows-TerminalServices-RDPClient/Operational
    event log, which may require administrative privileges.

  .LINK
    https://github.com/MyGitHub/MessKit
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
    $regex = [regex]::new('(?<=\()(?:[^()]+)(?=\))', [System.Text.RegularExpressions.RegexOptions]::Compiled)
  }

  process {
    try {
      # Fetch logs within the specified date range
      $logs = Get-WinEvent -FilterHashtable @{
        LogName   = 'Microsoft-Windows-TerminalServices-RDPClient/Operational'
        ID        = 1024
        StartTime = $StartTime
        EndTime   = $EndTime
      } -ErrorAction Stop

      $totalLogs = $logs.Count
      $processedLogs = 0

      foreach ($log in $logs) {
        $processedLogs++
        $percentComplete = ($processedLogs / $totalLogs) * 100

        Write-Progress -Activity 'Processing RDP Logs' -Status "Processing log $processedLogs of $totalLogs" -PercentComplete $percentComplete

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

      Write-Progress -Activity 'Processing RDP Logs' -Completed

      $computerNames | Sort-Object
    } catch {
      if ($_.Exception.GetType().Name -eq 'NoMatchingEventsException') {
        Write-Warning 'No events found for the specified date range.'
      } else {
        Write-Error -Exception $_.Exception -Message 'An error occurred while retrieving logs.'
      }
    }
  }
}