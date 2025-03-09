function Get-RagbraiWeek {
  <#
  .SYNOPSIS
  This function calculates and returns the start and end dates of Ragbrai Week for a given year.

  .DESCRIPTION
  Ragbrai (Register's Annual Great Bicycle Ride Across Iowa) is a cycling event that takes place during the last full week of July in Iowa.
  This function determines the exact dates by finding the last full work week (Mon-Fri) of July and returning the Saturday-to-Saturday range that includes this week.
  The output is formatted as a string in the form "Month day-day, year" (e.g., "July 20-26, 2025").

  .PARAMETER Year
  An integer input representing the year for which Ragbrai Week is to be calculated.
  It defaults to the current year and must be between 2025 and 2100.

  .OUTPUTS
  System.String. Returns a formatted string with the start and end dates of Ragbrai Week.

  .EXAMPLE
  Get-RagbraiWeek
  Returns Ragbrai Week for the present year.

  .EXAMPLE
  Get-RagbraiWeek -Year 2026
  Returns Ragbrai Week for a custom year.

  .EXAMPLE
  (Get-RagbraiWeek -Year 2025) -replace('-.* ', ', ') | Get-CountDown
  Returns how many hours/days/minutes until the start of Ragbrai 2025.

  .NOTES
  The calculation finds the Saturday before the last full work week of July, through the Saturday after.
  #>
  [CmdletBinding()]
  param (
    [ValidateRange(2025, 2100)]
    [int]$Year = (Get-Date).Year
  )

  process {
    # Ride is always in July so no need to ask for user input as it will always be 7th month of the year.
    $monthNumber = '07'

    # Find the last day of the Month as the offset to then find the duration.
    $lastDay = [datetime]::new($Year, $monthNumber, [DateTime]::DaysInMonth($Year, $monthNumber))

    # Return the preceding Saturday of the last full work week (Mon-Fri)
    switch ([int] $lastDay.DayOfWeek) {
      0 { [DateTime]$ragbrai = $lastDay.AddDays(-8) }
      1 { [DateTime]$ragbrai = $lastDay.AddDays(-9) }
      2 { [DateTime]$ragbrai = $lastDay.AddDays(-10) }
      3 { [DateTime]$ragbrai = $lastDay.AddDays(-11) }
      4 { [DateTime]$ragbrai = $lastDay.AddDays(-12) }
      5 { [DateTime]$ragbrai = $lastDay.AddDays(-6) }
      6 { [DateTime]$ragbrai = $lastDay.AddDays(-7) }
    }

    $startDate = $ragbrai.ToString('MMMM dd')
    $endDate = $ragbrai.AddDays(6).ToString('dd, yyyy')
    Write-Output "$startDate-$endDate"
  }
}