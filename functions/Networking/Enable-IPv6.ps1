function Enable-IPv6 {
  <#
  .SYNOPSIS
  Enable the IPv6 protocol.

  .DESCRIPTION
  Enable the IPv6 protocol on specified network adapters or all adapters if no specific adapter is provided.

  .EXAMPLE
  Enable-IPv6

  .EXAMPLE
  Enable-IPv6 -Name "Wi-Fi"

  .EXAMPLE
  Enable-IPv6 -Name "Local Area Connection"
  #>
  [CmdletBinding()]
  param (
    [Alias("AdapterName")]
    [ValidateNotNullOrEmpty()]
    [string[]] $Name = "all"
  )

  begin {
    function Test-Administrator {
      $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
      $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
      return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (-not (Test-Administrator)) {
      Write-Error -Message "This script must be executed as Administrator."
      return
    }

    if (-not (Get-Module -Name "NetAdapter" -ErrorAction SilentlyContinue)) {
      try {
        Import-Module -Name "NetAdapter" -ErrorAction Stop
      } catch {
        Write-Error -Message "Unable to load the NetAdapter module."
        return
      }
    }
  }

  process {
    try {
      if ($Name.ToLower() -eq "all") {
        Enable-NetAdapterBinding -Name * -ComponentID ms_tcpip6 -PassThru -Confirm:$false -ErrorAction Stop
      } else {
        foreach ($adapter in $Name) {
          Enable-NetAdapterBinding -Name $adapter -ComponentID ms_tcpip6 -PassThru -Confirm:$false -ErrorAction Stop
        }
      }
    } catch {
      Write-Error -Message "An error occurred while enabling IPv6: $_"
      return
    }

    try {
      Get-NetAdapterBinding -Name * -ComponentID ms_tcpip6
    } catch {
      Write-Error -Message "An error occurred while retrieving NetAdapterBindings: $_"
    }
  }
}