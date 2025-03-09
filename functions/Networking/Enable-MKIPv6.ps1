function Enable-MKIPv6 {
  <#
  .SYNOPSIS
  Enable the IPv6 protocol on network adapters.

  .DESCRIPTION
  The Enable-MKIPv6 function enables the IPv6 protocol on specified network adapters or all adapters if no specific adapter is provided.
  This function requires administrative privileges to run as it modifies network adapter settings.

  .PARAMETER Name
  Specifies the name(s) of the network adapter(s) on which to enable IPv6. Multiple adapter names can be specified as an array.
  If "all" is specified (the default), IPv6 will be enabled on all network adapters.

  .EXAMPLE
  Enable-MKIPv6

  Enables IPv6 on all network adapters.

  .EXAMPLE
  Enable-MKIPv6 -Name "Wi-Fi"

  Enables IPv6 on the Wi-Fi network adapter.

  .EXAMPLE
  Enable-MKIPv6 -Name "Ethernet", "Wi-Fi"

  Enables IPv6 on both the Ethernet and Wi-Fi network adapters.

  .NOTES
  This function requires administrative privileges.
  The NetAdapter module is required.

  .OUTPUTS
  Microsoft.Management.Infrastructure.CimInstance
  Returns the network adapter binding information after enabling IPv6.
  #>
  [CmdletBinding()]
  param (
    [Alias('AdapterName')]
    [ValidateNotNullOrEmpty()]
    [string[]] $Name = 'all'
  )

  begin {
    function Test-Administrator {
      $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
      $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
      return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (-not (Test-Administrator)) {
      Write-Error -Message 'This script must be executed as Administrator.'
      return
    }

    if (-not (Get-Module -Name 'NetAdapter' -ErrorAction SilentlyContinue)) {
      try {
        Import-Module -Name 'NetAdapter' -ErrorAction Stop
      } catch {
        Write-Error -Message 'Unable to load the NetAdapter module.'
        return
      }
    }
  }

  process {
    try {
      if ($Name.ToLower() -eq 'all') {
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