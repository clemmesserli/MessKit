Function Get-EventDate {
	<#
		.SYNOPSIS
		Function to get the date of a specific event based on the event name.

		.DESCRIPTION
		This function takes an event name as input and returns the date of that event for the current year.
		The supported event names include Christmas, Halloween, Fathers Day, Fourth of July, Labor Day, Martin Luther King Day,
		Memorial Day, Mothers Day, Presidents Day, Ragbrai, St Patricks Day, Thanksgiving, Valentines Day, and Veterans Day.

		.PARAMETER EventName
		Specifies the name of the event for which the date is to be retrieved. The event name must be one of the supported values.

		.EXAMPLE
		Get-EventDate -EventName "christmas"
		Returns the date of Christmas for the current year.

		.NOTES
		Enhanced by Codiumate
	#>
	[cmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[ValidateSet(
			'christmas', 'halloween', 'fathers day', 'fourth of july', 'labor day',
			'martin luther king day', 'memorial day', 'mothers day', 'presidents day',
			'ragbrai', 'st patricks day', 'thanksgiving', 'valentines day', 'veterans day'
		)]
		[string]$EventName
	)

	process {
		$year = (Get-Date).Year
		switch ($EventName) {
			'christmas' { $EventDate = "Dec 25, $year" }
			'fathers day' { $EventDate = (Get-DayInMonth -weeknumber 3 -day Sunday -month June -year $year) }
			'fourth of july' { $EventDate = "July 4, $year" }
			'halloween' { $EventDate = "October 31, $year" }
			'labor day' { $EventDate = (Get-FirstDayInMonth -day Monday -month September -year $year) }
			'martin luther king day' { $EventDate = (Get-DayInMonth -weeknumber 3 -day Monday -month January -year $year) }
			'memorial day' { $EventDate = (Get-LastDayInMonth -day Monday -month May -year $year) }
			'mothers day' { $EventDate = (Get-DayInMonth -weeknumber 2 -day Sunday -month May -year $year) }
			'ragbrai' { $EventDate = (Get-LastDayInMonth -day Saturday -month July -year $year) }
			'presidents day' { $EventDate = (Get-DayInMonth -weeknumber 3 -day Monday -month February -year $year) }
			'st patricks day' { $EventDate = "March 17, $year" }
			'thanksgiving' { $EventDate = (Get-DayInMonth -weeknumber 4 -day Thursday -month November -year $year) }
			'valentines day' { $EventDate = "February 14, $year" }
			'veterans day' { $EventDate = "November 11, $year" }
		}
		$EventDate
	}
}