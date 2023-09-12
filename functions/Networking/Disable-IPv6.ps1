function Disable-IPv6 {
	<#
	.SYNOPSIS
		Disable the IPv6 protocol
	.DESCRIPTION
		Disable the IPv6 protocol
	.EXAMPLE
		Disable-IPv6
	.EXAMPLE
		Disable-IPv6 -Name "Wi-Fi"
	.EXAMPLE
		Disable-IPv6 -AdapterName "Local Area Connection"
	#>
	[CmdletBinding()]
	param (
		[Alias("AdapterName")]
		[string[]] $Name = "all"
	)

	begin {
		if (-not (Test-Administrator)) {
			Write-Error "This script must be executed as Administrator."
			Break
		}

		if (-not(Get-Module -Name "netadapter")) {
			try {
				Get-ModuleDependency -name "netadapter"
			} catch {
				Throw "Unable to load dependent module"
				Break
			}
		}
	}

	process {
		if ($Name.tolower() -eq "all") {
			try {
				Disable-NetAdapterBinding -Name * -ComponentID ms_tcpip6 -PassThru
			} catch {
				Throw "Unable to update all NetAdapterBindings"
			}
		} else {
			$Name | ForEach-Object {
				try {
					Disable-NetAdapterBinding -Name $_ -ComponentID "ms_tcpip6" -PassThru
				} catch {
					Throw "Unable to update $_ NetAdapterBinding"
				}
			}
		}
		Get-NetAdapterBinding -Name * -ComponentID "ms_tcpip6"
	}
}
