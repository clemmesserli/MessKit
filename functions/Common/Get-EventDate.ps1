function Get-EventDate {
  <#
  .SYNOPSIS
  Get the date of a specific event based on the event name.

  .DESCRIPTION
  This function takes an event name as input and returns the date of that event for the current year.
  The supported event names include Christmas, Halloween, Fathers Day, Fourth of July, Labor Day, Martin Luther King Day,
  Memorial Day, Mothers Day, Presidents Day, Ragbrai, St Patricks Day, Thanksgiving, Valentines Day, and Veterans Day.

  .PARAMETER EventName
  Specifies the name of the event for which the date is to be retrieved. The event name must be one of the supported values.

  .EXAMPLE
  Get-EventDate -EventName "christmas"
  Returns the date of Christmas for the current year.
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