Function Get-CountDown {
	<#
	.SYNOPSIS
		This function will return time remaining until a given date or pre-set event
	.EXAMPLE
		Get-CountDown -eventname 'Thanksgiving'
		Returns time remaining based upone pre-defined list of events within the current year
	.EXAMPLE
		Get-CountDown -eventdate 'November 23'
		Returns time remaining before Thanksgiving within the current year.
	.EXAMPLE
		Get-CountDown -eventdate '11/28/2024'
		Returns time remaining before Thanksgiving within the specified year.
	.EXAMPLE
		(Get-DayInMonth -weeknumber 4 -day Thursday -month November -year 2024) | Get-Countdown
		Combines with another function to return time remaining before the 4th Thursday of November (Thanksgiving) within a specified year.
	#>
	[cmdletBinding(DefaultParameterSetName = "Date")]
	Param(
		[Parameter(Position = 0, ParameterSetName = "Date", ValueFromPipeline)]
		[datetime]$EventDate,

		[Parameter(Position = 0, ParameterSetName = "Event")]
		[ValidateSet(
			'christmas',
			'halloween',
			'fathers day',
			'fourth of july',
			'labor day',
			'martin luther king day',
			'memorial day',
			'mothers day',
			'presidents day',
			'ragbrai',
			'st patricks day',
			'thanksgiving',
			'valentines day',
			'veterans day'
		)]
		[string]$EventName
	)

	Begin {}

	Process {
		switch ($EventName) {
			'christmas' { $EventDate = 'Dec 25' }
			'fathers day' { $EventDate = (Get-DayInMonth -weeknumber 3 -day Sunday -month June) }
			'fourth of july' { $EventDate = 'July 4' }
			'halloween' { $EventDate = 'October 31' }
			'labor day' { $EventDate = (Get-FirstDayInMonth -day Monday -month September) }
			'martin luther king day' { $EventDate = (Get-DayInMonth -weeknumber 3 -day Monday -month January) }
			'memorial day' { $EventDate = (Get-LastDayInMonth -day Monday -month May) }
			'mothers day' { $EventDate = (Get-DayInMonth -weeknumber 2 -day Sunday -month May) }
			'ragbrai' { $EventDate = (Get-LastDayInMonth -day Saturday -month July) }
			'presidents day' { $EventDate = (Get-DayInMonth -weeknumber 3 -day Monday -month February) }
			'st patricks day' { $EventDate = 'March 17' }
			'thanksgiving' { $EventDate = (Get-DayInMonth -weeknumber 4 -day Thursday -month November) }
			'valentines day' { $EventDate = 'February 14' }
			'veterans day' { $EventDate = 'November 11' }
		}
		$ElapsedTime = $(New-TimeSpan -Start $(Get-Date) -End $EventDate)
		Write-Host "Days: $($ElapsedTime.Days) `t Hours: $($ElapsedTime.Hours) `t Minutes: $($ElapsedTime.Minutes)" -ForegroundColor Yellow
	}

	End {}
}