Function Get-CountDown {
	<#
		.SYNOPSIS
		Function to calculate the time remaining until a given date or pre-set event.

		.DESCRIPTION
		Function to calculate and display the remaining time until a specified date or pre-set event, providing countdown information in terms of days, hours, and minutes.

		.EXAMPLE
		Get-CountDown -eventname 'Thanksgiving'
		Returns time remaining based on a pre-defined list of events within the current year.

		.EXAMPLE
		Get-CountDown -eventdate 'November 28'
		Returns time remaining before Thanksgiving within the current year.

		.EXAMPLE
		Get-CountDown -eventdate '11/28/2025'
		Returns time remaining before Thanksgiving within the specified year.

		.EXAMPLE
		(Get-DayInMonth -weeknumber 3 -day Sunday -month June -year 2024) | Get-Countdown -eventdate
		Combines with another function to return time remaining before the 3rd Sunday of June within a specified year.

		.NOTES
		Enhanced by Codiumate
	#>
	[cmdletBinding(DefaultParameterSetName = "Date")]
	Param(
		[Parameter(ParameterSetName = "Date", ValueFromPipeline)]
		[datetime]$EventDate,

		[Parameter(ParameterSetName = "Event")]
		[ValidateSet(
			'christmas', 'halloween', 'fathers day', 'fourth of july', 'labor day',
			'martin luther king day', 'memorial day', 'mothers day', 'presidents day',
			'ragbrai', 'st patricks day', 'thanksgiving', 'valentines day', 'veterans day'
		)]
		[string]$EventName
	)

	Process {
		if ($PSCmdlet.ParameterSetName -eq 'Event') {
			$EventDate = Get-EventDate -EventName $EventName
		}

		$ElapsedTime = $(New-TimeSpan -Start $(Get-Date) -End $EventDate)
		Write-Output "Days: $($ElapsedTime.Days) `t Hours: $($ElapsedTime.Hours) `t Minutes: $($ElapsedTime.Minutes)"
	}
}