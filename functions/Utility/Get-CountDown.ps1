function Get-CountDown {
  <#
  .SYNOPSIS
  Calculates the time remaining until a given date or pre-set event.

  .DESCRIPTION
  Calculates and displays the remaining time until a specified date or pre-set event, providing countdown information in terms of days, hours, and minutes.

  .PARAMETER EventDate
  Specifies the target date for the countdown. Accepts a datetime object or strings that can be converted to dates like '11/28/2025' or 'November 28'.
  Can be provided via pipeline.

  .PARAMETER EventName
  Specifies a pre-defined event from a fixed list. The function will automatically determine the date for the event in the current year.
  Valid values include: christmas, halloween, fathers day, fourth of july, labor day, martin luther king day, memorial day,
  mothers day, presidents day, ragbrai, st patricks day, thanksgiving, valentines day, veterans day.

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

  .OUTPUTS
  String
  Returns a formatted string showing days, hours, and minutes remaining until the specified event or date.

  .NOTES
  This function relies on Get-EventDate when using the EventName parameter to determine the date of pre-defined events.
  #>
  [CmdletBinding(DefaultParameterSetName = 'Date')]
  param (
    [Parameter(ParameterSetName = 'Date', ValueFromPipeline)]
    [datetime]$EventDate,

    [Parameter(ParameterSetName = 'Event')]
    [ValidateSet(
      'christmas', 'halloween', 'fathers day', 'fourth of july', 'labor day',
      'martin luther king day', 'memorial day', 'mothers day', 'presidents day',
      'ragbrai', 'st patricks day', 'thanksgiving', 'valentines day', 'veterans day'
    )]
    [string]$EventName
  )

  process {
    if ($PSCmdlet.ParameterSetName -eq 'Event') {
      $EventDate = Get-EventDate -EventName $EventName
    }

    $ElapsedTime = $(New-TimeSpan -Start $(Get-Date) -End $EventDate)
    Write-Output "Days: $($ElapsedTime.Days) `t Hours: $($ElapsedTime.Hours) `t Minutes: $($ElapsedTime.Minutes)"
  }
}