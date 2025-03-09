function Get-MKRandomDate {
  <#
    .SYNOPSIS
        Generates a random date between two dates.

    .DESCRIPTION
        The Get-MKRandomDate function generates a random date between a specified start date
        and end date. By default, it returns a random date between 14 days ago and the current date.

        The function can generate multiple random dates at once and supports filtering for workdays only.
        It can also return just the date portion without the time component.

    .PARAMETER StartDate
        The earliest possible date to return. If not specified, defaults to 14 days before the current date.

    .PARAMETER EndDate
        The latest possible date to return. If not specified, defaults to the current date.

    .PARAMETER Count
        The number of random dates to generate. Defaults to 1.

    .PARAMETER DateOnly
        If specified, only the date part of the DateTime will be returned (time will be set to 00:00:00).

    .PARAMETER WorkdayOnly
        If specified, only workdays (Monday to Friday) will be returned, excluding weekends.

    .EXAMPLE
        Get-MKRandomDate

        Returns a random date between 14 days ago and now, including the time component.

    .EXAMPLE
        Get-MKRandomDate -StartDate (Get-Date).AddMonths(-1) -EndDate (Get-Date)

        Returns a random date between one month ago and now, including the time component.

    .EXAMPLE
        Get-MKRandomDate -StartDate "2023-01-01" -EndDate "2023-12-31"

        Returns a random date from the year 2023, including the time component.

    .EXAMPLE
        Get-MKRandomDate -Count 5

        Returns five random dates between 14 days ago and now.

    .EXAMPLE
        Get-MKRandomDate -DateOnly

        Returns a random date between 14 days ago and now with the time component set to 00:00:00.

    .EXAMPLE
        Get-MKRandomDate -WorkdayOnly

        Returns a random date between 14 days ago and now, ensuring it falls on a Monday through Friday.

    .EXAMPLE
        Get-MKRandomDate -StartDate "2023-01-01" -EndDate "2023-01-31" -Count 10 -DateOnly -WorkdayOnly

        Returns 10 random dates from January 2023, each falling on a workday (Mon-Fri) with no time component.

    .OUTPUTS
        System.DateTime

    .NOTES
        Function Name : Get-MKRandomDate
        Part of       : MessKit Module

        When using the WorkdayOnly parameter with a small date range, ensure the range contains at least
        one workday or the function might run indefinitely.
    #>
  [CmdletBinding()]
  param (
    [Parameter(Position = 0)]
    [DateTime]$StartDate = (Get-Date).AddDays(-14),

    [Parameter(Position = 1)]
    [DateTime]$EndDate = (Get-Date),

    [Parameter()]
    [int]$Count = 1,

    [Parameter()]
    [switch]$DateOnly,

    [Parameter()]
    [switch]$WorkdayOnly,

    [Parameter(DontShow)]
    [int]$MaxAttempts = 10000
  )

  if ($StartDate -gt $EndDate) {
    throw 'StartDate must be earlier than EndDate'
  }

  # Check for workdays in range if WorkdayOnly is specified
  if ($WorkdayOnly) {
    $hasWorkday = $false
    $checkDate = $StartDate.Date
    while ($checkDate -le $EndDate.Date) {
      if ($checkDate.DayOfWeek -ne 'Saturday' -and $checkDate.DayOfWeek -ne 'Sunday') {
        $hasWorkday = $true
        break
      }
      $checkDate = $checkDate.AddDays(1)
    }

    if (-not $hasWorkday) {
      throw 'The specified date range does not contain any workdays (Monday-Friday).'
    }
  }

  $range = New-TimeSpan -Start $StartDate -End $EndDate
  $generatedCount = 0
  $attempts = 0

  while ($generatedCount -lt $Count) {
    $attempts++
    if ($attempts -gt $MaxAttempts) {
      throw 'Maximum attempts reached. The specified date range may not contain enough workdays.'
    }

    $randomSeconds = Get-Random -Minimum 0 -Maximum $range.TotalSeconds
    $randomDate = $StartDate.AddSeconds($randomSeconds)

    # Skip if not a workday and WorkdayOnly is specified
    if ($WorkdayOnly -and ($randomDate.DayOfWeek -eq 'Saturday' -or $randomDate.DayOfWeek -eq 'Sunday')) {
      continue
    }

    if ($DateOnly) {
      $randomDate = $randomDate.Date
    }

    $randomDate
    $generatedCount++
  }
}