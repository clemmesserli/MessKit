function Close-MKRDP {
  <#
  .SYNOPSIS
  Close one or more RDP sessions

  .DESCRIPTION
  Close one or more RDP sessions using PowerShell PSCredential for authentication.
  The list of computers can be dynamically queried from local machine event log or statically provided.

  .EXAMPLE
  Close-MKRDP -Credential $Credential -ComputerName server01

  .EXAMPLE
  Close-MKRDP -Credential $Credential -ComputerName (Get-RDPLog -StartTime 1/01/2022 -EndTime 1/08/2022)
  Close any active or disconnected RDP sessions as found in local machine event log between the dates entered

  .EXAMPLE
  Close-MKRDP -Credential $Credential -ComputerName (Get-Content ./private/servers.txt)

  .EXAMPLE
  $param = @{
    Credential = $Credential
    ComputerName = @(
      "L4PC1001",
      "L4PC1101"
    )
    Verbose = $true
  }
  Close-MKRDP @param
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
      if ($rdp -match "ID") {
        $user = $rdp -replace '\s{2,}', ',' | ConvertFrom-Csv |
          Where-Object { $_.USERNAME -eq $using:Credential.UserName }
        if ($user) {
          $result = logoff $user.ID 2>&1
          [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Action       = "Logged off"
            Message      = $result
          }
        } else {
          [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            Action       = "No action"
            Message      = "User not found in active sessions"
          }
        }
      } else {
        [PSCustomObject]@{
          ComputerName = $env:COMPUTERNAME
          Action       = "No action"
          Message      = "No logged on users"
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
