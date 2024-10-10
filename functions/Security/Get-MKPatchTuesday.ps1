function Get-MKPatchTuesday {
  <#
  .SYNOPSIS
  Calculates the date of the second Tuesday of a specified month and year.

  .DESCRIPTION
  This function calculates the date of the second Tuesday of a specified month and year. If no month or year is provided, it defaults to the current month and year.

  .PARAMETER Month
  The month for which to find the second Tuesday. Defaults to the current month.

  .PARAMETER Year
  The year for which to find the second Tuesday. Defaults to the current year.

  .EXAMPLE
  Get-MKPatchTuesday
  Description: Return the 2nd Tuesday of current month and year

  .EXAMPLE
  Get-MKPatchTuesday -Month 'August' -Year ((Get-Date).Year + 1)
  Description: Return the 2nd Tuesday for January of the following year.

  .EXAMPLE
  (1..12) | Get-MKPatchTuesday
  Description: Return 2nd Tuesday of each month of current year
  #>
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline)]
    [object]$Month = (Get-Date).ToString('MMMM'),

    [Parameter()]
    [ValidateRange(2024, 2034)]
    [int]$Year = (Get-Date).Year
  )

  process {
    # Check if user input Month Name which we then need to convert to Month Number
    if ($Month -as [int]) {
      $monthNumber = [int]$Month
    } else {
      $monthNumber = [datetime]::ParseExact($Month, 'MMMM', $null).Month
    }

    $startOfMonth = (Get-Date -Month $monthNumber -Day 1 -Year $Year)

    switch ( $startOfMonth.DayOfWeek.ToString() ) {
      'Sunday' { $patchTuesday = $startOfMonth.AddDays(9) }
      'Monday' { $patchTuesday = $startOfMonth.AddDays(8) }
      'Tuesday' { $patchTuesday = $startOfMonth.AddDays(7) }
      'Wednesday' { $patchTuesday = $startOfMonth.AddDays(13) }
      'Thursday' { $patchTuesday = $startOfMonth.AddDays(12) }
      'Friday' { $patchTuesday = $startOfMonth.AddDays(11) }
      'Saturday' { $patchTuesday = $startOfMonth.AddDays(10) }
    }
    $patchTuesday.ToString("dddd, MMMM dd, yyyy")
  }
}
