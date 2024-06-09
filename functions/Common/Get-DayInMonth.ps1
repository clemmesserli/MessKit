Function Get-DayInMonth {
	<#
	.EXAMPLE
		Get-DayInMonth -weeknumber 1 -day Monday -month September
		Description: Labor Day
	.EXAMPLE
		Get-DayInMonth -weeknumber 4 -day Thursday -month November
		Description: Thanksgiving
	.EXAMPLE
		(1..12) | Foreach-Object { Get-DayInMonth -weeknumber 2 -day Tuesday -monthnumber $_ }
		Description: Get every 2nd Tuesday of 12 months for current year

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

	Process {
		if ( $PsCmdlet.ParameterSetName -eq "Month") {
			$MonthNumber = [Array]::IndexOf([CultureInfo]::CurrentCulture.DateTimeFormat.MonthNames, $Month) + 1
		}
		$Date = Get-Date -Month $MonthNumber -Year $Year

		$FirstDay = $Date.AddDays(1 - $Date.Day)

		[int]$Shift = $Day + 7 * $WeekNumber - $FirstDay.DayOfWeek

		if ($FirstDay.DayOfWeek -le $Day) {
			$Shift -= 7
		}
		$FirstDay.AddDays($Shift).ToString("dddd, MMMM dd, yyyy")
	}
}