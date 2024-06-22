function Get-FirstDayInMonth {
  <#
  .EXAMPLE
  Get-FirstDayInMonth -day Monday -month September
  Returns date for Labor Day of current year

  .EXAMPLE
  (1..12) | Foreach-Object { Get-FirstDayInMonth -day Saturday -monthnumber $_ }
  Get the first Saturday of the month for all 12 months for current year

  .EXAMPLE
  (1..12) | Foreach-Object { Get-FirstDayInMonth -day Saturday -monthnumber $_ -year 2025 }
  Get the first Saturday of the month for all 12 months for custom year
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ParameterSetName = "Month")]
    [ValidateSet("January", "February", "March", "April", "May", "June", "July", "August", "September", "November", "December")]
    [string]$Month,

    [Parameter(Mandatory, ParameterSetName = "MonthNumber")]
    [ValidateRange(1, 12)]
    [int]$MonthNumber,

    [Parameter(Mandatory)]
    [ValidateSet("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
    [System.DayOfWeek]$Day,

    [int]$Year = (Get-Date).Year
  )

  process {
    if ( $PsCmdlet.ParameterSetName -eq "Month") {
      $MonthNumber = [array]::indexof([cultureinfo]::CurrentCulture.DateTimeFormat.MonthNames, "$Month") + 1
    }
    $date = Get-Date -Month $MonthNumber -Year $Year

    $firstDay = $date.AddDays(1 - $date.Day)

    [int]$shift = $Day + 7 - $firstDay.DayOfWeek

    if ($firstDay.DayOfWeek -le $Day) {
      $shift -= 7
    }
    $firstDay.AddDays($shift).ToString("dddd, MMMM dd, yyyy")
  }
}