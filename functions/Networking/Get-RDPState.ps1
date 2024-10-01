function Get-RDPState {
  <#
  .SYNOPSIS
  Returns RDP status (Active/Disconnected) for the user credential provided

  .DESCRIPTION
  Returns RDP status (Active/Disconnected) for the user credential provided or returns an error if unable to access.

  .EXAMPLE
  Get-RDPState -Credential $Credential -ComputerName L1PC1001
  Retrieve RDP info for a single computer

  .EXAMPLE
  Get-RDPState -Credential $Credential -ComputerName L1PC1001, L2PC1101
  Retrieve RDP info for a multiple computers

  .EXAMPLE
  Get-RDPState -Credential $Credential -ComputerName (Get-RDPLog -StartTime (Get-Date).AddDays(-7)) -ThrottleLimt 12
  Combine with Get-RDPLog to return RDP info for dynamic list of computers based on recent event log info
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential,

    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string[]]$ComputerName,

    [int]$ThrottleLimt = 5
  )

  begin {
    $scriptBlock = {
      $query = quser.exe 2>&1
      if ($query -match "ID") {
        $query -replace '\s{2,}', ',' | ConvertFrom-Csv |
          Where-Object { $_.USERNAME -eq $using:Credential.UserName } |
            Select-Object @{N = 'ComputerName'; E = { $env:COMPUTERNAME } }, *
      } else {
        [PSCustomObject]@{
          ComputerName = $env:COMPUTERNAME
          Message      = "No logged on users"
        }
      }
    }
  }

  process {
    foreach ($computer in $ComputerName) {
      try {
        $params = @{
          ComputerName = $computer
          Credential   = $Credential
          ScriptBlock  = $scriptBlock
          ErrorAction  = 'Stop'
        }
        Invoke-Command @params -ThrottleLimit $ThrottleLimt
      } catch {
        [PSCustomObject]@{
          ComputerName = $computer
          Error        = $_.Exception.Message
        }
      }
    }
  }
}