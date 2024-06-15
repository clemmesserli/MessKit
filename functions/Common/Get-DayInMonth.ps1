Function Get-DayInMonth {
	<#
		.SYNOPSIS
		Get the specific day of the week in a given month and year.

		.DESCRIPTION
		This function calculates and returns the date of a specific day of the week in a given month and year.
		It takes parameters such as the month (either by name or number), day of the week, week number, and year.

		.PARAMETER Month
		Specifies the month for which the day needs to be calculated.
		Accepts month names (e.g., January, February) or month numbers (1-12).

		.PARAMETER MonthNumber
		Specifies the month by its number (1-12).
		This parameter is mutually exclusive with the 'Month' parameter.

		.PARAMETER Day
		Specifies the day of the week for which the date needs to be calculated.
		Accepts values such as Sunday, Monday, Tuesday, etc.

		.PARAMETER WeekNumber
		Specifies the week number (1-5) for which the day needs to be calculated.

		.PARAMETER Year
		Specifies the year for which the day needs to be calculated.
		Defaults to the current year if not specified.

		.EXAMPLE
		Get-DayInMonth -weeknumber 1 -day Monday -month September
		Description: Labor Day

		.EXAMPLE
		Get-DayInMonth -weeknumber 4 -day Thursday -month November
		Description: Thanksgiving

		.EXAMPLE
		(1..12) | Foreach-Object { Get-DayInMonth -weeknumber 2 -day Tuesday -monthnumber $_ }
		Description: Get every 2nd Tuesday of 12 months for the current year

		.NOTES
		Enhanced by ChatGPT-4o
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ParameterSetName = "Month")]
		[ValidateSet("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")]
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

		# Calculate the first day of the month
		$FirstDayOfMonth = [datetime]::new($Year, $MonthNumber, 1)

		# Calculate the offset to the target day of the week
		$DayOfWeekOffset = ($Day - $FirstDayOfMonth.DayOfWeek + 7) % 7

		# Find the first occurrence of the target day of the week
		$FirstOccurrence = $FirstDayOfMonth.AddDays($DayOfWeekOffset)

		# Calculate the target date based on the week number
		$TargetDate = $FirstOccurrence.AddDays(7 * ($WeekNumber - 1))

		#$TargetDate.ToString("dddd, MMMM dd, yyyy")
		$TargetDate
	}
}