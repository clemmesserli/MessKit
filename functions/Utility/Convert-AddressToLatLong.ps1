Function Convert-AddressToLatLong {
	<#
	.SYNOPSIS
		translate addresses into latitude and longitude coordinates
	.DESCRIPTION
		This function calls a free ThirdParty webservice which will throttle results so a sleep timer has been added to help
	.EXAMPLE
		Convert-AddressToLatLong -addressList @(
			'13000 SD-244, Keystone, SD 57751',
			'Grand Canyon National Park, P.O. Box 129, Grand Canyon, AZ 86023',
			'8.8.8.8'
		) -verbose
	#>
	[cmdletbinding()]
	param(
		[string[]]$addressList,

		[int]$sleepTimer = 5,

		[string]$url = "https://geocode.xyz/"
	)

	Begin {}

	Process {
		Write-Verbose "Creating a web session"
		if (!($session)) {
			$null = Invoke-RestMethod -Uri $url -SessionVariable session
		}

		$total = $addressList.count
		$count = 0
		$addressList | ForEach-Object {
			$count++
			if ($count -ne $total) {
				Write-Verbose "Sleeping for $($sleepTimer) seconds..."
				Start-Sleep -Seconds $sleepTimer
			}
			Write-Verbose "Now resolving $_  ($count of $total) `n"
			$address = $_
			$encoded = [Net.WebUtility]::UrlEncode($address)
			$response = Invoke-RestMethod "$url/${encoded}?json=1" -WebSession $session
			$response | ForEach-Object {
				[PSCustomObject]@{
					Address = $address
					Long    = $_.longt
					Lat     = $_.latt
				}
			}
		}
	}

	End {}
}