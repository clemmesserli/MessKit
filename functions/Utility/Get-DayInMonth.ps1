function Get-DayInMonth {
  <#
  .SYNOPSIS
  Get the specific day of the week in a given month and year.

  .DESCRIPTION
  The Get-DayInMonth function calculates the date for a specific occurrence (by week number)
  of a day of the week in a given month and year. This is useful for determining dates of
  holidays or events that occur on specific week numbers, like Thanksgiving (4th Thursday
  in November) or Labor Day (1st Monday in September).

  .PARAMETER Month
  Specifies the month for which the day needs to be calculated.
  Accepts month names (e.g., January, February).

  .PARAMETER MonthNumber
  Specifies the month by its number (1-12).
  This parameter is mutually exclusive with the 'Month' parameter.

  .PARAMETER Day
  Specifies the day of the week for which the date needs to be calculated.
  Accepts values such as Sunday, Monday, Tuesday, etc.

  .PARAMETER WeekNumber
  Specifies the week number (1-5) for which the day needs to be calculated.

  .PARAMETER Year
  Specifies the year for which the day needs to be calculated.
  Defaults to the current year if not specified.

  .EXAMPLE
  Get-DayInMonth -weeknumber 1 -day Monday -month September

  Returns the date of Labor Day (1st Monday in September) for the current year.

  .EXAMPLE
  Get-DayInMonth -weeknumber 4 -day Thursday -month November

  Returns the date of Thanksgiving (4th Thursday in November) for the current year.

  .EXAMPLE
  (1..12) | Foreach-Object { Get-DayInMonth -weeknumber 2 -day Tuesday -monthnumber $_ }

  Returns the date of every 2nd Tuesday of each month for the current year.

  .OUTPUTS
  System.DateTime
  Returns a DateTime object representing the calculated date.

  .NOTES
  Author: MessKit Team
  Last Update: March 6, 2025
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ParameterSetName = 'Month')]
    [ValidateSet('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')]
    [string]$Month,

    [Parameter(Mandatory, ParameterSetName = 'MonthNumber')]
    [ValidateRange(1, 12)]
    [int]$MonthNumber,

    [Parameter(Mandatory)]
    [ValidateSet('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')]
    [System.DayOfWeek]$Day,

    [Parameter(Mandatory)]
    [ValidateRange(1, 5)]
    [int]$WeekNumber,

    [int]$Year = (Get-Date).Year
  )

  process {
    if ( $PsCmdlet.ParameterSetName -eq 'Month') {
      $MonthNumber = [Array]::IndexOf([CultureInfo]::CurrentCulture.DateTimeFormat.MonthNames, $Month) + 1
    }

    # Calculate the first day of the month
    $firstDayOfMonth = [datetime]::new($Year, $MonthNumber, 1)

    # Calculate the offset to the target day of the week
    $dayOfWeekOffset = ($Day - $firstDayOfMonth.DayOfWeek + 7) % 7

    # Find the first occurrence of the target day of the week
    $firstOccurrence = $firstDayOfMonth.AddDays($dayOfWeekOffset)

    # Calculate the target date based on the week number
    $targetDate = $firstOccurrence.AddDays(7 * ($WeekNumber - 1))

    #$targetDate.ToString("dddd, MMMM dd, yyyy")
    $targetDate
  }
}