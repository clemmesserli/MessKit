function Get-EventDate {
  <#
  .SYNOPSIS
  Get the date of a specific event based on the event name.

  .DESCRIPTION
  This function takes an event name as input and returns the date of that event for the current year.

  The function handles both fixed dates (like Christmas on December 25th) and variable dates that change
  each year (like Thanksgiving on the fourth Thursday in November or Mother's Day on the second Sunday in May).

  The supported event names include:
  - Christmas (Dec 25)
  - Halloween (Oct 31)
  - Fathers Day (3rd Sunday in June)
  - Fourth of July (July 4)
  - Labor Day (1st Monday in September)
  - Martin Luther King Day (3rd Monday in January)
  - Memorial Day (Last Monday in May)
  - Mothers Day (2nd Sunday in May)
  - Presidents Day (3rd Monday in February)
  - Ragbrai (Last Saturday in July)
  - St Patricks Day (March 17)
  - Thanksgiving (4th Thursday in November)
  - Valentines Day (February 14)
  - Veterans Day (November 11)

  .PARAMETER EventName
  Specifies the name of the event for which the date is to be retrieved. The event name must be one of the supported values
  and is not case-sensitive.

  .EXAMPLE
  Get-EventDate -EventName "christmas"

  Returns the date of Christmas (December 25) for the current year.

  .EXAMPLE
  Get-EventDate -EventName "thanksgiving"

  Returns the date of Thanksgiving (4th Thursday in November) for the current year.

  .EXAMPLE
  Get-EventDate -EventName "memorial day"

  Returns the date of Memorial Day (last Monday in May) for the current year.

  .EXAMPLE
  "mothers day", "fathers day" | ForEach-Object { Get-EventDate -EventName $_ }

  Returns the dates of Mother's Day and Father's Day for the current year.

  .OUTPUTS
  System.String
  Returns a string representation of the date in the format "Month Day, Year" (e.g., "Dec 25, 2025").

  .NOTES
  Author: MessKit Project
  The function automatically uses the current year when calculating dates.
  #>
  [CmdletBinding()]
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
      'christmas' { $eventDate = "Dec 25, $year" }
      'fathers day' { $eventDate = (Get-DayInMonth -weeknumber 3 -day Sunday -month June -year $year) }
      'fourth of july' { $eventDate = "July 4, $year" }
      'halloween' { $eventDate = "October 31, $year" }
      'labor day' { $eventDate = (Get-FirstDayInMonth -day Monday -month September -year $year) }
      'martin luther king day' { $eventDate = (Get-DayInMonth -weeknumber 3 -day Monday -month January -year $year) }
      'memorial day' { $eventDate = (Get-LastDayInMonth -day Monday -month May -year $year) }
      'mothers day' { $eventDate = (Get-DayInMonth -weeknumber 2 -day Sunday -month May -year $year) }
      'ragbrai' { $eventDate = (Get-LastDayInMonth -day Saturday -month July -year $year) }
      'presidents day' { $eventDate = (Get-DayInMonth -weeknumber 3 -day Monday -month February -year $year) }
      'st patricks day' { $eventDate = "March 17, $year" }
      'thanksgiving' { $eventDate = (Get-DayInMonth -weeknumber 4 -day Thursday -month November -year $year) }
      'valentines day' { $eventDate = "February 14, $year" }
      'veterans day' { $eventDate = "November 11, $year" }
    }
    $eventDate
  }
}