Function Convert-IPtoAddress {
	<#
	.SYNOPSIS
		translate IP address to physical address
	.DESCRIPTION
		This function calls a free ThirdParty webservice which will throttle results so a sleep timer has been added to help
	.EXAMPLE
		Convert-IPtoAddress -addressList @(
			'8.8.8.8'
		) -verbose
	#>
	[cmdletbinding()]
	param(
		[string[]]$addressList,

		[int]$sleepTimer = 5,

		[string]$url = "https://geocode.xyz"
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
			Write-Verbose "Now resolving $_  ($count of $total) `n"
			$address = $_
			$encoded = [Net.WebUtility]::UrlEncode($address)
			$response = Invoke-RestMethod "$url/${encoded}?json=1" -WebSession $session
			$response | ForEach-Object {
				[PSCustomObject]@{
					Address          = $("$($response.stnumber) $($response.staddress)")
					City             = $response.city
					State            = $response.state
					ZipCode          = $response.postal
					Province         = $response.prov
					Country          = $response.country
					Latitude         = $response.latt
					Longitude        = $response.longt
					Timezone         = $response.timezone
					Elevation        = $response.elevation
					County           = $response.adminareas.admin6.alt_name
					Population       = $response.adminareas.admin6.population
					Confidence       = $response.confidence
					PointsOfInterest = $response.poi
				}
			}
			Write-Verbose "Sleeping for $sleepTimer seconds..."
			Start-Sleep -Seconds $sleepTimer
		}
	}

	End {}
}