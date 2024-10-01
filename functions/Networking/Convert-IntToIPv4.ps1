Function Convert-IntToIPv4 {
	<#
	.LINK
	https://codeandkeep.com/PowerShell-Get-Subnet-NetworkID/
	#>
	[CmdletBinding()]
	Param (
		[uint32]$Integer
	)

	Begin {}

	Process {
		Try {
			$bytes = [System.BitConverter]::GetBytes($Integer)
			[Array]::Reverse($bytes)
		([IPAddress]($bytes)).ToString()
		} Catch {
			Write-Error -Exception $_.Exception -Category $_.CategoryInfo.Category
		}
	}

	End {}
}