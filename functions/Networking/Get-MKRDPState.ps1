function Get-MKRDPState {
  <#
  .SYNOPSIS
    Returns RDP session status for a specific user across one or more computers.

  .DESCRIPTION
    The Get-MKRDPState function queries remote computers to determine RDP session status by:
    - Checking for active or disconnected RDP sessions for the provided credentials
    - Executing the quser command remotely on each target computer
    - Returning custom objects with session details including state and idle time
    - Supporting parallel execution with throttling to improve performance

    Results include status (Active/Disconnected) or error messages if the session or
    computer cannot be accessed.

  .PARAMETER Credential
    The PowerShell credential object used for authentication when querying remote systems.
    Must contain a valid username and password with permissions to access the target computers.

  .PARAMETER ComputerName
    An array of computer names to query for RDP session status.
    Accepts pipeline input for integration with other commands like Get-MKRDPLog.

  .PARAMETER ThrottleLimit
    Maximum number of concurrent queries to execute simultaneously.
    Default value is 5, which provides a balance of performance and system load.

  .EXAMPLE
    PS> Get-MKRDPState -Credential $Credential -ComputerName L1PC1001
    Retrieves RDP session status for the specified user on a single computer.

  .EXAMPLE
    PS> Get-MKRDPState -Credential $Credential -ComputerName L1PC1001, L2PC1101
    Retrieves RDP session status for the specified user on multiple computers.

  .EXAMPLE
    PS> Get-MKRDPState -Credential $Credential -ComputerName (Get-MKRDPLog -StartTime (Get-Date).AddDays(-7)) -ThrottleLimit 12
    Combines with Get-MKRDPLog to check RDP status on computers accessed within the past week,
    using increased parallelism for faster results.

  .NOTES
    File Name      : Get-MKRDPState.ps1
    Author         : MessKit
    Requires       : PowerShell 5.1 or later
    Version        : 1.0

  .LINK
    https://github.com/MyGitHub/MessKit
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

    [int]$ThrottleLimit = 5
  )

  begin {
    $scriptBlock = {
      $query = quser.exe 2>&1
      if ($query -match 'ID') {
        $query -replace '\s{2,}', ',' | ConvertFrom-Csv |
          Where-Object { $_.USERNAME -eq $using:Credential.UserName } |
            Select-Object @{N = 'ComputerName'; E = { $env:COMPUTERNAME } }, *
      } else {
        [PSCustomObject]@{
          ComputerName = $env:COMPUTERNAME
          Message      = 'No logged on users'
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
        Invoke-Command @params -ThrottleLimit $ThrottleLimit
      } catch {
        [PSCustomObject]@{
          ComputerName = $computer
          Error        = $_.Exception.Message
        }
      }
    }
  }
}