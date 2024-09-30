function Suspend-ScreenLock {
  <#
  .SYNOPSIS
  Suspends screen lock due to inactivity by simulating keyboard input.

  .DESCRIPTION
  Suspends screen lock due to inactivity by simulating keyboard input for a specified duration (default is 90 minutes).
  This can be useful when running in a secondary terminal while monitoring log files in a primary window.

  .PARAMETER DurationMinutes
  The duration in minutes to suspend the screen lock. Default is 90 minutes.

  .PARAMETER IntervalSeconds
  The interval in seconds between simulated key presses. Default is 60 seconds.

  .EXAMPLE
  Suspend-ScreenLock -DurationMinutes 180 -Verbose

  .EXAMPLE
  Suspend-ScreenLock -DurationMinutes 180 -IntervalSeconds (Get-Random -Minimum 60 -Maximum 180) -Verbose

  .NOTES
  This script uses the SendKeys method, which may interfere with active user input.
  Use with caution when running alongside other interactive processes.
  #>
  [CmdletBinding()]
  param (
    [Parameter()]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$DurationMinutes = 90,

    [Parameter()]
    [ValidateRange(1, 3600)]
    [int]$IntervalSeconds = 60
  )

  begin {
    Add-Type -AssemblyName System.Windows.Forms
    $endTime = (Get-Date).AddMinutes($DurationMinutes)
  }

  process {
    try {
      Write-Verbose "Screen lock suspension started. Press Ctrl+C to exit."
      while ((Get-Date) -lt $endTime) {
        $remainingTime = $endTime - (Get-Date)
        Write-Verbose "Remaining time: $($remainingTime.ToString('hh\:mm\:ss'))"
        [System.Windows.Forms.SendKeys]::SendWait('{F15}')
        Start-Sleep -Seconds $IntervalSeconds
      }
    } catch {
      Write-Error "An error occurred: $_"
    } finally {
      Write-Verbose "Screen lock suspension ended."
    }
  }
}