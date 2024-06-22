function New-SimplePassword {
  <#
  .SYNOPSIS
  Random Password Generator

  .DESCRIPTION
  Random Password Generator

  .EXAMPLE
  New-SimplePassword

  .EXAMPLE
  New-SimplePassword -length 12
  #>
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateRange(6, 48)]
    [int]$Length = 18
  )

  process {
    -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789!@#$%^&*()_+-='.ToCharArray() | Get-Random -Count $Length)
  }
}