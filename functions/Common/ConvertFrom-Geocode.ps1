Function ConvertFrom-Geocode {
	<#
	.SYNOPSIS
		translate latitude and longitude coordinates into an address
	.DESCRIPTION
		This function calls a free ThirdParty webservice which will throttle results so a sleep timer has been added to help
	.EXAMPLE
		ConvertFrom-Geocode -coordinateList @(
			@{Long = -103.45846; Lat = 43.87475},
			@{Long = -112.13094; Lat = 36.05137}
		) -verbose
	#>
	[CmdletBinding()]
	Param (
		[hashtable[]]$coordinateList,

		[String]$url = "https://geocode.xyz/"
	)

	Begin {}

	Process {
		Write-Verbose "Creating a web session"
		if (!($session)) {
			$null = Invoke-RestMethod -Uri $url -SessionVariable session
		}

		$total = $coordinateList.count
		$count = 0
		$coordinateList | ForEach-Object {
			$count++
			if ($count -ne $total) {
				Write-Verbose "Sleeping for $($sleepTimer) seconds..."
				Start-Sleep -Seconds (10..30 | Get-Random )
			}
			Write-Verbose "Now resolving $_  ($count of $total) `n"
			$coordinate = $_.lat, $_.long -join ","
			$response = Invoke-RestMethod "$url/${coordinate}?geoit=json" -WebSession $session
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
		}
	}

	End {}
}