function Open-MKRDP {
  <#
  .SYNOPSIS
    Opens one or more Remote Desktop Protocol (RDP) sessions.

  .DESCRIPTION
    The Open-MKRDP function establishes RDP connections by:
    - Using PowerShell credentials to authenticate RDP sessions
    - Temporarily storing credentials in Windows Credential Manager
    - Launching Microsoft Terminal Services Client (mstsc.exe)
    - Cleaning up stored credentials after launching sessions
    - Supporting sequential launches with configurable delays

    This function simplifies connecting to multiple systems by handling authentication
    and providing options for display modes.

  .PARAMETER Credential
    The PowerShell credential object used for authentication when establishing RDP connections.
    Must contain a valid username and password for the target machines.

  .PARAMETER ComputerName
    An array of computer names to connect to via RDP.
    Accepts pipeline input for integration with other commands like Get-MKRDPLog.

  .PARAMETER FullScreen
    Switch to launch RDP sessions in full-screen mode.
    Default is windowed mode if not specified.

  .PARAMETER DelaySeconds
    The number of seconds to wait between launching RDP sessions.
    Default value is 5 seconds, which helps prevent overwhelming the local system.

  .EXAMPLE
    PS> Open-MKRDP -Credential $Credential -ComputerName "L1PC1001" -Verbose
    Opens a single RDP connection to L1PC1001 with verbose output.

  .EXAMPLE
    PS> $params = @{
          Credential = $Credential
          ComputerName = @("L1PC1001", "L2PC1101")
          Verbose = $true
        }
    PS> Open-MKRDP @params
    Opens multiple RDP connections using parameter splatting.

  .EXAMPLE
    PS> Open-MKRDP -Credential $Credential -ComputerName (Get-MKRDPLog -StartTime (Get-Date).AddDays(-1)) -FullScreen -DelaySeconds 3
    Opens full-screen RDP connections to all computers accessed in the past day with reduced delay between launches.

  .NOTES
    File Name      : Open-MKRDP.ps1
    Author         : MessKit
    Requires       : PowerShell 5.1 or later
    Version        : 1.0

    If your default RDP profile has 'Always ask for credentials' checked,
    you will still need to input the appropriate password when prompted as each RDP window is launched.

    This function temporarily stores credentials in Windows Credential Manager but removes them
    after launching the RDP sessions.

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
    [string[]]$ComputerName,

    [Parameter()]
    [switch]$FullScreen,

    [Parameter()]
    [int]$DelaySeconds = 5
  )

  begin {
    $userName = $Credential.UserName
    # Avoid exposing the password as plain text
    $securePassword = $Credential.Password
  }

  process {
    foreach ($computer in $ComputerName) {
      try {
        # Create a RDP credential using the PSCredential param input
        $cmdkeyResult = cmdkey.exe /generic:$computer /user:$userName /pass:(ConvertFrom-SecureString -SecureString $securePassword -AsPlainText)
        Write-Verbose "$computer : $cmdkeyResult"

        # Prepare mstsc arguments
        $mstscArgs = @("/v:$computer")
        if ($FullScreen) {
          $mstscArgs += '/f'
        }

        # Launch RDP window using Microsoft Terminal Services Client
        Start-Process -FilePath 'mstsc.exe' -ArgumentList $mstscArgs

        # Add delay to allow user to interact with the RDP window upon first launch
        Start-Sleep -Seconds $DelaySeconds

        [PSCustomObject]@{
          ComputerName = $computer
          Action       = 'RDP session initiated'
          Message      = 'Credentials stored and RDP window launched'
        }
      } catch {
        [PSCustomObject]@{
          ComputerName = $computer
          Action       = 'Failed to initiate RDP session'
          Error        = $_.Exception.Message
        }
      }
    }
  }

  end {
    # Clean up stored credentials after all connections are attempted
    foreach ($computer in $ComputerName) {
      $cleanupResult = cmdkey.exe /delete:$computer
      Write-Verbose "$computer : $cleanupResult"
    }
  }
}