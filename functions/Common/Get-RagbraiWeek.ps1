Function Get-RagbraiWeek {
	<#
	.SYNOPSIS
		This function will return time remaining the start and end dates for Ragbrai.
		Ragbrai is a cycling event that occurs the last full week of July in which riders cycle across the state of Iowa.
	.EXAMPLE
		Get-RagbraiWeek
		Returns Ragbrai Week for the present year.
	.EXAMPLE
		Get-RagbraiWeek -year 2024
		Returns Ragbrai Week for a custom year.
	.EXAMPLE
		(Get-RagbraiWeek -Year 2024) -replace('-.* ', ', ') | Get-CountDown
		Returns how many hours/days/minutes until the start of Ragbrai 2024
	#>
	[CmdletBinding()]
	Param (
		[int]$Year = (Get-Date).Year
	)

	Begin {}

	Process {
		# Ride is always the month of July so need need to ask for user input.
		$MonthNumber = '07'

		# Find the last day of the Month as the offset to then find the duration.
		$lastDay = New-Object DateTime($Year, $MonthNumber, [DateTime]::DaysInMonth($Year, $MonthNumber))

		# Return the preceding Saturday of the last full work week (Mon-Fri)
		switch ([int] $lastDay.DayOfWeek) {
			0 { [DateTime]$ragbrai = $lastDay.AddDays(-8) }
			1 { [DateTime]$ragbrai = $lastDay.AddDays(-9) }
			2 { [DateTime]$ragbrai = $lastDay.AddDays(-10) }
			3 { [DateTime]$ragbrai = $lastDay.AddDays(-11) }
			4 { [DateTime]$ragbrai = $lastDay.AddDays(-12) }
			5 { [DateTime]$ragbrai = $lastDay.AddDays(-6) }
			6 { [DateTime]$ragbrai = $lastDay.AddDays(-7) }
		}
		"$((Get-Culture).DateTimeFormat.GetMonthName((Get-Date $ragbrai).Month)) $($ragbrai.ToString("dd"))-$($ragbrai.AddDays(6).ToString("dd")), $($ragbrai.ToString("yyyy"))"
	}

	End {}
}