function Get-LastDayInMonth {
  <#
  .SYNOPSIS
  Finds the last occurrence of a specific day of the week in a given month.

  .DESCRIPTION
  The Get-LastDayInMonth function determines the date of the last occurrence of a specific
  day of the week (e.g., Monday, Saturday) in a given month and year. This is useful for
  scheduling events that occur on the last specific weekday of a month.

  .PARAMETER Month
  The name of the month. Must be a valid English month name.

  .PARAMETER MonthNumber
  The number of the month (1-12).

  .PARAMETER Day
  The day of the week to find the last occurrence of.

  .PARAMETER Year
  The year to check. Defaults to the current year.

  .EXAMPLE
  Get-LastDayInMonth -Day Monday -Month May

  Returns the date of the last Monday in May of the current year.

  .EXAMPLE
  (1..12) | Foreach-Object { Get-LastDayInMonth -Day Saturday -MonthNumber $_ }

  Returns the last Saturday of each month for the current year.

  .EXAMPLE
  (1..12) | Foreach-Object { Get-LastDayInMonth -Day Monday -MonthNumber $_ -Year 2025 }

  Returns the last Monday of each month for the year 2025.

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

    $lastDay = New-Object DateTime($Year, $MonthNumber, [DateTime]::DaysInMonth($Year, $MonthNumber))

    $diff = ([int] [DayOfWeek]::$Day) - ([int] $lastDay.DayOfWeek)

    if ($diff -ge 0) {
      $lastDay.AddDays( - (7 - $diff)).ToString('dddd, MMMM dd, yyyy')
    } else {
      $lastDay.AddDays($diff).ToString('dddd, MMMM dd, yyyy')
    }
  }
}