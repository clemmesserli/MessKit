function Get-MKPatchTuesday {
  <#
  .SYNOPSIS
  Calculates the date of the second Tuesday of a specified month and year.

  .DESCRIPTION
  This function calculates and returns the date of Patch Tuesday (the second Tuesday)
  of a specified month and year. Patch Tuesday is Microsoft's designated day for
  releasing security updates and patches.

  The function accepts both numeric months (1-12) and month names as input, and can
  process multiple months when provided through the pipeline. If no month or year is
  provided, the function defaults to the current month and year.

  .PARAMETER Month
  The month for which to find Patch Tuesday.

  Accepts:
  - Month number (1-12)
  - Month name (e.g., 'January', 'February')
  - Pipeline input of month numbers or names

  Defaults to the current month if not specified.

  .PARAMETER Year
  The year for which to find Patch Tuesday.

  Must be between 2024 and 2034.
  Defaults to the current year if not specified.

  .EXAMPLE
  Get-MKPatchTuesday

  Returns the Patch Tuesday date for the current month and year.

  .EXAMPLE
  Get-MKPatchTuesday -Month 'January' -Year ((Get-Date).Year + 1)

  Returns the Patch Tuesday date for January of the next year.

  .EXAMPLE
  (1..12) | Get-MKPatchTuesday

  Returns the Patch Tuesday dates for all twelve months of the current year
  by piping the month numbers to the function.

  .EXAMPLE
  Get-MKPatchTuesday -Month 7 -Year 2025

  Returns the Patch Tuesday date for July 2025.

  .EXAMPLE
  'March', 'April', 'May' | Get-MKPatchTuesday -Year 2026

  Returns the Patch Tuesday dates for March, April, and May of 2026
  by piping the month names to the function.

  .INPUTS
  [System.Object]
  You can pipe month numbers (1-12) or month names to this function.

  .OUTPUTS
  [System.String]
  Returns a formatted date string representing Patch Tuesday in the format: "dddd, MMMM dd, yyyy".

  .NOTES
  Patch Tuesday is Microsoft's scheduled release day for software updates, occurring on the second Tuesday of each month.

  This function handles leap years and varying month lengths automatically.

  The Year parameter is validated to be between 2024 and 2034, but can be modified if needed for a broader range.
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
    $patchTuesday.ToString('dddd, MMMM dd, yyyy')
  }
}
