function Get-FirstDayInMonth {
  <#
  .SYNOPSIS
  Finds the first occurrence of a specific day of the week in a given month.

  .DESCRIPTION
  The Get-FirstDayInMonth function determines the date of the first occurrence of a specific
  day of the week (e.g., Monday, Saturday) in a given month and year. This is useful for
  scheduling events that occur on the first specific weekday of a month.

  .PARAMETER Month
  The name of the month. Must be a valid English month name.

  .PARAMETER MonthNumber
  The number of the month (1-12).

  .PARAMETER Day
  The day of the week to find the first occurrence of.

  .PARAMETER Year
  The year to check. Defaults to the current year.

  .EXAMPLE
  Get-FirstDayInMonth -Day Monday -Month September

  Returns date for Labor Day of current year.

  .EXAMPLE
  (1..12) | Foreach-Object { Get-FirstDayInMonth -Day Saturday -MonthNumber $_ }

  Get the first Saturday of the month for all 12 months for current year.

  .EXAMPLE
  (1..12) | Foreach-Object { Get-FirstDayInMonth -Day Saturday -MonthNumber $_ -Year 2025 }

  Get the first Saturday of the month for all 12 months for custom year.

  .OUTPUTS
  System.String
  Returns a string representing the date in the format "dddd, MMMM dd, yyyy".

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

    [int]$Year = (Get-Date).Year
  )

  process {
    if ( $PsCmdlet.ParameterSetName -eq 'Month') {
      $MonthNumber = [array]::indexof([cultureinfo]::CurrentCulture.DateTimeFormat.MonthNames, "$Month") + 1
    }
    $date = Get-Date -Month $MonthNumber -Year $Year

    $firstDay = $date.AddDays(1 - $date.Day)

    [int]$shift = $Day + 7 - $firstDay.DayOfWeek

    if ($firstDay.DayOfWeek -le $Day) {
      $shift -= 7
    }
    $firstDay.AddDays($shift).ToString('dddd, MMMM dd, yyyy')
  }
}