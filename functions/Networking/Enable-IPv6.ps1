function Enable-IPv6 {
	<#
	.SYNOPSIS
		Enable the IPv6 protocol
	.DESCRIPTION
		Enable the IPv6 protocol
	.EXAMPLE
		Enable-IPv6
	.EXAMPLE
		Enable-IPv6 -Name "Wi-Fi"
	.EXAMPLE
		Enable-IPv6 -AdapterName "Local Area Connection"
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
				Enable-NetAdapterBinding -Name * -ComponentID ms_tcpip6 -PassThru
			} catch {
				Throw "Unable to update all NetAdapterBindings"
			}
		} else {
			$Name | ForEach-Object {
				try {
					Enable-NetAdapterBinding -Name $_ -ComponentID "ms_tcpip6" -PassThru
				} catch {
					Throw "Unable to update $_ NetAdapterBinding"
				}
			}
		}
		Get-NetAdapterBinding -Name * -ComponentID "ms_tcpip6"
	}
}