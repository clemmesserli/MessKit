Function Get-PatchTuesday {
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
		Get-PatchTuesday
		Description: Return the 2nd Tuesday of current month and year
	.EXAMPLE
		Get-PatchTuesday -Month 'August' -Year ((Get-Date).Year + 1)
		Description: Return the 2nd Tuesday for January of the following year.
	.EXAMPLE
		(1..12) | Get-PatchTuesday
		Description: Return 2nd Tuesday of each month of current year
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline)]
		[object]$Month = (Get-Date).ToString('MMMM'),

		[Parameter()]
		[ValidateRange(2024, 2034)]
		[int]$Year = (Get-Date).Year
	)

	Process {
		# Check if user input Month Name which we then need to convert to Month Number
		if ($Month -as [int]) {
			$MonthNumber = [int]$Month
		} else {
			$MonthNumber = [datetime]::ParseExact($Month, 'MMMM', $null).Month
		}

		$StartOfMonth = (Get-Date -Month $MonthNumber -Day 1 -Year $Year)
		Switch ( $StartOfMonth.DayOfWeek ) {
			'Sunday' { $PatchTuesday = $StartOfMonth.AddDays(9) }
			'Monday' { $PatchTuesday = $StartOfMonth.AddDays(8) }
			'Tuesday' { $PatchTuesday = $StartOfMonth.AddDays(7) }
			'Wednesday' { $PatchTuesday = $StartOfMonth.AddDays(13) }
			'Thursday' { $PatchTuesday = $StartOfMonth.AddDays(12) }
			'Friday' { $PatchTuesday = $StartOfMonth.AddDays(11) }
			'Saturday' { $PatchTuesday = $StartOfMonth.AddDays(10) }
		}
		$PatchTuesday.ToString("dddd, MMMM dd, yyyy")
	}
}
