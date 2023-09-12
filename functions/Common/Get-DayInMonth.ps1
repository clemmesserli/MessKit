Function Get-DayInMonth {
	<#
	.EXAMPLE
		Get-DayInMonth -weeknumber 2 -day Tuesday -month April
	.EXAMPLE
		(1..12) | Foreach-Object { Get-DayInMonth -weeknumber 2 -day Tuesday -monthnumber $_ }
		Get every 2nd Tuesday of 12 months for current year
	.EXAMPLE
		(1..12) | Foreach-Object { Get-DayInMonth -weeknumber 2 -day Tuesday -monthnumber $_ -year 2024 }
		Get every 2nd Tuesday of 12 months for custom year
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ParameterSetName = "Month")]
		[ValidateSet("January", "February", "March", "April", "May", "June", "July", "August", "September", "November", "December")]
		[string]$Month,

		[Parameter(Mandatory, ParameterSetName = "MonthNumber")]
		[ValidateRange(1, 12)]
		[int]$MonthNumber,

		[Parameter(Mandatory)]
		[ValidateSet("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
		[System.DayOfWeek]$Day,

		[Parameter(Mandatory)]
		[ValidateRange(1, 5)]
		[int]$WeekNumber,

		[int]$Year = (Get-Date).Year
	)

	Begin {}

	Process {
		if ( $PsCmdlet.ParameterSetName -eq "Month") {
			$MonthNumber = [array]::indexof([cultureinfo]::CurrentCulture.DateTimeFormat.MonthNames, "$Month") + 1
		}
		$Date = Get-Date -Month $MonthNumber -Year $Year

		$FirstDay = $Date.AddDays(1 - $Date.Day)

		[int]$Shift = $Day + 7 * $WeekNumber - $FirstDay.DayOfWeek

		If ($FirstDay.DayOfWeek -le $Day) {
			$Shift -= 7
		}
		$FirstDay.AddDays($Shift).ToString('dddd, MMMM dd, yyyy')
	}

	End {}
}