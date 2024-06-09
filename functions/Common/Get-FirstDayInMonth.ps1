Function Get-FirstDayInMonth {
	<#
	.EXAMPLE
		Get-FirstDayInMonth -day Monday -month September
		Returns date for Labor Day of current year
	.EXAMPLE
		(1..12) | % { Get-FirstDayInMonth -day Saturday -monthnumber $_ }
		Get the first Saturday of the month for all 12 months for current year
	.EXAMPLE
		(1..12) | % { Get-FirstDayInMonth -day Saturday -monthnumber $_ -year 2025 }
		Get the first Saturday of the month for all 12 months for custom year
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

		[int]$Year = (Get-Date).Year
	)

	Process {
		if ( $PsCmdlet.ParameterSetName -eq "Month") {
			$MonthNumber = [array]::indexof([cultureinfo]::CurrentCulture.DateTimeFormat.MonthNames, "$Month") + 1
		}
		$Date = Get-Date -Month $MonthNumber -Year $Year

		$FirstDay = $Date.AddDays(1 - $Date.Day)

		[int]$Shift = $Day + 7 - $FirstDay.DayOfWeek

		If ($FirstDay.DayOfWeek -le $Day) {
			$Shift -= 7
		}
		$FirstDay.AddDays($Shift).ToString("dddd, MMMM dd, yyyy")
	}
}