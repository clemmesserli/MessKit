function Suspend-MKScreenLock {
  <#
  .SYNOPSIS
  Suspends screen lock due to inactivity by simulating keyboard input.

  .DESCRIPTION
  Suspends screen lock due to inactivity by simulating keyboard input (F15 key) for a specified duration.
  This function runs continuously for the specified time, sending a keystroke at regular intervals.

  This can be useful when:
  - Monitoring log files in a primary window
  - Running long processes where screen locking would be disruptive
  - Presenting content where automatic lock would interrupt

  Progress is reported through verbose output showing remaining time.

  .PARAMETER DurationMinutes
  The duration in minutes to suspend the screen lock. Default is 90 minutes.
  Accepts any positive integer value.

  .PARAMETER IntervalSeconds
  The interval in seconds between simulated key presses. Default is 60 seconds.
  Accepts values between 1 and 3600 (1 hour).

  .EXAMPLE
  Suspend-MKScreenLock

  Runs the function with default values (90 minutes duration, 60-second intervals)

  .EXAMPLE
  Suspend-MKScreenLock -DurationMinutes 180 -Verbose

  Runs for 3 hours with verbose output showing remaining time

  .EXAMPLE
  Suspend-MKScreenLock -DurationMinutes 180 -IntervalSeconds (Get-Random -Minimum 60 -Maximum 180) -Verbose

  Uses a random interval between 1-3 minutes with verbose output for 3 hours

  .EXAMPLE
  Start-Job -ScriptBlock { Suspend-MKScreenLock -DurationMinutes 120 }

  Runs screen lock prevention in the background as a job for 2 hours

  .NOTES
  - This script uses the SendKeys method from System.Windows.Forms to simulate F15 key presses
  - F15 is used because it's typically unused by applications but recognized as activity by Windows
  - The function can be terminated early by pressing Ctrl+C
  - May interfere with active user input in some applications
  - Progress information is only displayed when -Verbose is specified
  - No value is returned by this function
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
      Write-Verbose 'Screen lock suspension started. Press Ctrl+C to exit.'
      while ((Get-Date) -lt $endTime) {
        $remainingTime = $endTime - (Get-Date)
        Write-Verbose "Remaining time: $($remainingTime.ToString('hh\:mm\:ss'))"
        [System.Windows.Forms.SendKeys]::SendWait('{F15}')
        Start-Sleep -Seconds $IntervalSeconds
      }
    } catch {
      Write-Error "An error occurred: $_"
    } finally {
      Write-Verbose 'Screen lock suspension ended.'
    }
  }
}