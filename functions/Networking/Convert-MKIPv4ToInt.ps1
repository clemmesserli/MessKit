Function Convert-MKIPv4ToInt {
	<#
	.LINK
	https://codeandkeep.com/PowerShell-Get-Subnet-NetworkID/
	#>
	[CmdletBinding()]
	Param (
		[String]$IPv4Address
	)

	Begin {}

	Process {
		Try {
			$ipAddress = [IPAddress]::Parse($IPv4Address)

			$bytes = $ipAddress.GetAddressBytes()
			[Array]::Reverse($bytes)

			[System.BitConverter]::ToUInt32($bytes, 0)
		} Catch {
			Write-Error -Exception $_.Exception -Category $_.CategoryInfo.Category
		}
	}

	End {}
}
