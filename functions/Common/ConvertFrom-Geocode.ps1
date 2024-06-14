Function ConvertFrom-Geocode {
	<#
		.SYNOPSIS
		Translate latitude and longitude coordinates into an address.

		.DESCRIPTION
		This function calls a free ThirdParty webservice which may throttle results, so a sleep timer has been added to help manage the requests.

		.EXAMPLE
		$GeoData = ConvertFrom-Geocode -Coordinates @(
			@{Lat = 40.24695; Lon = -89.77191},
			@{Lat = 41.90313; Lon = 12.45384},
			@{Lat = 40.6892; Lon = -74.0445}
		) -verbose
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[hashtable[]]$Coordinates
	)

	Process {
		$total = $Coordinates.count
		$count = 0
		$results = [System.Collections.Generic.List[PSObject]]::New()
		$url = "https://geocode.xyz"
		$null = Invoke-RestMethod -Uri $url -SessionVariable geoSession

		$Coordinates | ForEach-Object {
			$count++
			$lat = $_.lat
			$lon = $_.lon

			# Validate latitude and longitude
			if ($lat -ge -90 -and $lat -le 90 -and $lon -ge -180 -and $lon -le 180) {
				Write-Verbose "Now resolving Lat=$lat, Lon=$lon ($count of $total) `n"
			} else {
				Write-Warning "Invalid coordinates: Lat=$lat, Lon=$lon"
			}

			try {
				$response = Invoke-RestMethod -Uri "$url/$lat,$lon?json=1&moreinfo=1" -WebSession $geoSession

				$maxAttempts = 5
				$attempt = 0
				while ($response.latt -match 'Throttled' -and $attempt -lt $maxAttempts) {
					Write-Verbose "Request Throttled...Retry [$attempt] of [$maxAttempts] for: [$lat, $lon]"
					Start-Sleep -Seconds (5..30 | Get-Random )
					$response = Invoke-RestMethod -Uri "$url/$lat,$lon?json=1&moreinfo=1" -WebSession $geoSession
					$attempt++
				}

				$results.Add(
					[PSCustomObject]@{
						Address          = "$($response.stnumber) $($response.staddress)"
						City             = $response.city
						State            = $response.statename
						StateCode        = $response.state
						ZipCode          = $response.postal
						Country          = $response.country
						CountryCode      = $response.prov
						Latitude         = $response.latt
						Longitude        = $response.longt
						Timezone         = $response.timezone
						Elevation        = $response.elevation
						Confidence       = $response.confidence
						PointsOfInterest = $response.poi
					}
				)
			} catch {
				Write-Error "Error occurred while invoking the REST method: $_"
			}
		}
		$results
	}
}
