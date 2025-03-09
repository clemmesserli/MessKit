function Get-MKSecretSantaList {
  <#
  .SYNOPSIS
    Generates a unique list of gift givers and gift receivers for Secret Santa exchanges.

  .DESCRIPTION
    The Get-MKSecretSantaList function creates a randomized Secret Santa assignment list by:
    - Taking a list of participant names as input
    - Randomly shuffling the names to create giver/receiver pairs
    - Ensuring no one is assigned to give a gift to themselves
    - Returning a collection of custom objects with Giver and Receiver properties

    This function is useful for organizing holiday gift exchanges, team building activities,
    or any scenario where random pairings are needed.

  .PARAMETER Name
    An array of participant names to include in the Secret Santa exchange.
    A minimum of 2 names must be provided.
    Names can be provided directly or piped from a file or another command.

  .EXAMPLE
    PS> Get-MKSecretSantaList -Name 'Charlie Brown', 'Snoopy', 'Woodstock', 'Lucy', 'Linus'
    Creates a Secret Santa list with 5 participants from the Peanuts gang.

  .EXAMPLE
    PS> Get-MKSecretSantaList -Name (Get-Content C:\temp\names.txt)
    Creates a Secret Santa list using names from an external text file.

  .EXAMPLE
    PS> $team = Get-ADGroupMember -Identity 'Marketing Team' | Select-Object -ExpandProperty Name
    PS> Get-MKSecretSantaList -Name $team | Export-Csv -Path 'C:\temp\SecretSanta.csv'
    Creates a Secret Santa list for an Active Directory group and exports the results to CSV.

  .EXAMPLE
    PS> Get-MKSecretSantaList -Name $employees | ForEach-Object {
          Send-MailMessage -To $_.Giver -Subject 'Your Secret Santa Assignment' -Body "You will be giving a gift to: $($_.Receiver)"
        }
    Creates assignments and emails each participant their assigned gift recipient.

  .NOTES
    File Name      : Get-MKSecretSantaList.ps1
    Author         : MessKit
    Requires       : PowerShell 5.1 or later
    Version        : 1.0

  .LINK
    https://github.com/MyGitHub/MessKit
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateCount(2, [int]::MaxValue)]
    [string[]]$Name
  )

  # Shuffle the list of names
  $shuffledNames = $Name | Get-Random -Count $Name.Count

  # Initialize the Secret Santa list
  $secretSantaList = [System.Collections.ArrayList]::new()

  # Assign each person a Secret Santa
  for ($i = 0; $i -lt $shuffledNames.Count; $i++) {
    $giver = $shuffledNames[$i]
    $receiver = $shuffledNames[($i + 1) % $shuffledNames.Count]

    # Ensure no one is assigned their own name
    if ($giver -eq $receiver) {
      # Swap with the next person in the shuffled list
      $nextIndex = ($i + 1) % $shuffledNames.Count
      $temp = $shuffledNames[$i]
      $shuffledNames[$i] = $shuffledNames[$nextIndex]
      $shuffledNames[$nextIndex] = $temp
      $receiver = $shuffledNames[$i]
    }

    # Add PSCustomObject to the ArrayList
    $null = $secretSantaList.Add([PSCustomObject]@{
        Giver    = $giver
        Receiver = $receiver
      })
  }
  $secretSantaList
}