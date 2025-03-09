function Close-MKRDP {
  <#
  .SYNOPSIS
    Closes one or more Remote Desktop Protocol (RDP) sessions.

  .DESCRIPTION
    The Close-MKRDP function terminates RDP sessions by:
    - Logging off remote user sessions using the specified credentials
    - Closing local RDP client processes connected to the target machines
    - Cleaning up stored credentials from Windows Credential Manager

    The list of computers can be dynamically queried from local machine event log
    or statically provided as input parameters.

  .PARAMETER Credential
    The PowerShell credential object used for authentication when logging off remote sessions.
    Must contain a valid username and password with permissions to terminate sessions.

  .PARAMETER ComputerName
    An array of computer names where RDP sessions should be terminated.
    Accepts pipeline input for integration with other commands like Get-MKRDPLog.

  .EXAMPLE
    PS> Close-MKRDP -Credential $Credential -ComputerName server01
    Closes any RDP session for the specified user on server01.

  .EXAMPLE
    PS> Close-MKRDP -Credential $Credential -ComputerName (Get-MKRDPLog -StartTime "1/01/2022" -EndTime "1/08/2022")
    Closes any active or disconnected RDP sessions on computers found in the local machine
    event log between the specified dates.

  .EXAMPLE
    PS> Close-MKRDP -Credential $Credential -ComputerName (Get-Content ./private/servers.txt)
    Closes RDP sessions on all servers listed in the servers.txt file.

  .EXAMPLE
    PS> $param = @{
          Credential = $Credential
          ComputerName = @(
            "L4PC1001",
            "L4PC1101"
          )
          Verbose = $true
        }
    PS> Close-MKRDP @param
    Closes RDP sessions on the specified computers using splatted parameters with verbose output.

  .NOTES
    File Name      : Close-MKRDP.ps1
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
    $Credential,

    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string[]]$ComputerName
  )

  begin {
    $scriptBlock = {
      $rdp = quser 2>&1
      if ($rdp -match 'ID') {
        $user = $rdp -replace '\s{2,}', ',' | ConvertFrom-Csv |
          Where-Object { $_.USERNAME -eq $using:Credential.UserName }
        if ($user) {
          $result = logoff $user.ID 2>&1
          [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Action       = 'Logged off'
            Message      = $result
          }
        } else {
          [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Action       = 'No action'
            Message      = 'User not found in active sessions'
          }
        }
      } else {
        [PSCustomObject]@{
          ComputerName = $env:COMPUTERNAME
          Action       = 'No action'
          Message      = 'No logged on users'
        }
      }
    }
  }

  process {
    foreach ($computer in $ComputerName) {
      try {
        # Close local RDP client process
        Get-Process |
          Where-Object { $_.MainWindowTitle -match [regex]::Escape($computer.Split('.')[0]) } |
            Stop-Process -Force -ErrorAction SilentlyContinue

        # Remote logoff
        $params = @{
          ComputerName = $computer
          Credential   = $Credential
          ScriptBlock  = $scriptBlock
          ErrorAction  = 'Stop'
        }
        $remoteResult = Invoke-Command @params

        # Clean up stored credentials
        $cmdkeyResult = cmdkey.exe /delete:$computer

        [PSCustomObject]@{
          ComputerName  = $computer
          RemoteAction  = $remoteResult.Action
          RemoteMessage = $remoteResult.Message
          LocalCleanup  = $cmdkeyResult -replace '^CMDKEY: '
        }
      } catch {
        [PSCustomObject]@{
          ComputerName = $computer
          Error        = $_.Exception.Message
        }
      }
    }
  }
}
