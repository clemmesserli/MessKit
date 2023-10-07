Function Get-PatchTuesday {
	<#
	.EXAMPLE
		Get-PatchTuesday
	.EXAMPLE
		Get-PatchTuesday -Date '10/01/2023'
	.EXAMPLE
		(1..12) | ForEach-Object { Get-PatchTuesday -Date "$_/01/2023" }
	#>
	[CmdletBinding()]
	Param (
		[int]$Year = (Get-Date).Year,

		[datetime]$Date = (Get-Date)
	)

	Begin {}

	Process {
		$StartOfMonth = (Get-Date -Date $Date -Day 1)
		Switch ( $StartOfMonth.DayOfWeek ) {
			'Sunday' { $PatchTuesday = $StartOfMonth.AddDays(9) }
			'Monday' { $PatchTuesday = $StartOfMonth.AddDays(8) }
			'Tuesday' { $PatchTuesday = $StartOfMonth.AddDays(7) }
			'Wednesday' { $PatchTuesday = $StartOfMonth.AddDays(13) }
			'Thursday' { $PatchTuesday = $StartOfMonth.AddDays(12) }
			'Friday' { $PatchTuesday = $StartOfMonth.AddDays(11) }
			'Saturday' { $PatchTuesday = $StartOfMonth.AddDays(10) }
		}
		$PatchTuesday.ToString('dddd, MMMM dd, yyyy')
	}

	End {}
}
