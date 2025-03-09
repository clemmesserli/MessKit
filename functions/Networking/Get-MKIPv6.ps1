function Get-MKIPv6 {
  <#
  .SYNOPSIS
  Get the IPv6 protocol status on network adapters.

  .DESCRIPTION
  The Get-MKIPv6 function returns the status of the IPv6 protocol on specified network adapters
  or all adapters if no specific adapter is provided.

  .PARAMETER Name
  Specifies the name(s) of the network adapter(s) for which to get IPv6 status. Multiple adapter names
  can be specified as an array. If "all" is specified (the default), IPv6 status will be retrieved for
  all network adapters.

  .EXAMPLE
  Get-MKIPv6

  Returns IPv6 status for all network adapters.

  .EXAMPLE
  Get-MKIPv6 -Name "Wi-Fi"

  Returns IPv6 status for the Wi-Fi network adapter.

  .EXAMPLE
  Get-MKIPv6 -Name "Ethernet", "Wi-Fi"

  Returns IPv6 status for both the Ethernet and Wi-Fi network adapters.

  .EXAMPLE
  Get-MKIPv6 | Where-Object { $_.Enabled -eq $true }

  Returns only the network adapters that have IPv6 enabled.

  .NOTES
  The NetAdapter module is required.

  .OUTPUTS
  Microsoft.Management.Infrastructure.CimInstance
  Returns the network adapter binding information showing the IPv6 status.
  #>
  [CmdletBinding()]
  param (
    [Alias('AdapterName')]
    [ValidateNotNullOrEmpty()]
    [string[]] $Name = 'all'
  )

  begin {
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
        Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction Stop
      } else {
        foreach ($adapter in $Name) {
          Get-NetAdapterBinding -Name $adapter -ComponentID ms_tcpip6 -ErrorAction Stop
        }
      }
    } catch {
      Write-Error -Message "An error occurred while retrieving IPv6 status: $_"
    }
  }
}