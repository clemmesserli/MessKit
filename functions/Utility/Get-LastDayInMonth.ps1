function Get-LastDayInMonth {
  <#
  .EXAMPLE
  Get-LastDayInMonth -day Monday -month May

  .EXAMPLE
  (1..12) | Foreach-Object { Get-LastDayInMonth -day Saturday -monthnumber $_ }
  Get the last Saturday of the month for all 12 months for current year

  .EXAMPLE
  (1..12) | Foreach-Object { Get-LastDayInMonth -day Monday -monthnumber $_ -year 2025 }
  Get the last Saturday of the month for all 12 months for custom year
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

    $lastDay = New-Object DateTime($Year, $MonthNumber, [DateTime]::DaysInMonth($Year, $MonthNumber))

    $diff = ([int] [DayOfWeek]::$Day) - ([int] $lastDay.DayOfWeek)

    if ($diff -ge 0) {
      $lastDay.AddDays( - (7 - $diff)).ToString("dddd, MMMM dd, yyyy")
    } else {
      $lastDay.AddDays($diff).ToString("dddd, MMMM dd, yyyy")
    }
  }
}