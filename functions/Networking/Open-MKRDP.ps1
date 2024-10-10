function Open-MKRDP {
  <#
  .SYNOPSIS
  Open one or more RDP sessions

  .DESCRIPTION
  Open one or more RDP sessions using PowerShell PSCredential for authentication.

  .EXAMPLE
  Open-MKRDP Credential $Credential ComputerName "L1PC1001" -Verbose

  .EXAMPLE
  $params = @{
    Credential = $Credential
    ComputerName = @(
      "L1PC1001",
      "L2PC1101"
    )
    Verbose = $true
  }
  Open-MKRDP @params

  .NOTES
  If your default RDP profile has 'Always ask for credentials' checked,
  you will still need to input the appropriate password when prompted as each RDP window is launched.
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
          $mstscArgs += "/f"
        }

        # Launch RDP window using Microsoft Terminal Services Client
        Start-Process -FilePath "mstsc.exe" -ArgumentList $mstscArgs

        # Add delay to allow user to interact with the RDP window upon first launch
        Start-Sleep -Seconds $DelaySeconds

        [PSCustomObject]@{
          ComputerName = $computer
          Action       = "RDP session initiated"
          Message      = "Credentials stored and RDP window launched"
        }
      } catch {
        [PSCustomObject]@{
          ComputerName = $computer
          Action       = "Failed to initiate RDP session"
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