Function ConvertTo-Geocode {
	<#
		.SYNOPSIS
		Translate addresses into latitude and longitude coordinates.

		.DESCRIPTION
		This function calls a free ThirdParty webservice which may throttle results, so a sleep timer has been added to help manage the requests.

		.EXAMPLE
		$GeoData = ConvertTo-Geocode -addressList @(
			'1600 PENNSYLVANIA AVE NW, Washington D.C. 20500',
			'1 Governorate Street, Roma, Italy 00120',
			'1 Liberty Island - Ellis Island, New York, New Jersey 10004',
			'162.123.18.140'
		) -verbose
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[String[]]$AddressList
	)

	Process {
		$total = $AddressList.count
		$count = 0
		$results = [System.Collections.Generic.List[PSObject]]::New()
		$url = "https://geocode.xyz"
		$null = Invoke-RestMethod -Uri $url -SessionVariable geoSession

		$AddressList | ForEach-Object {
			$count++

			try {
				Write-Verbose "Now resolving $_ ($count of $total) `n"

				$encoded = [Net.WebUtility]::UrlEncode($_)
				$response = Invoke-RestMethod -Uri "$($url)/$($encoded)?json=1" -WebSession $geoSession

				$maxAttempts = 5
				$attempt = 0
				while ($response.latt -match 'Throttled' -and $attempt -lt $maxAttempts) {
					Write-Verbose "Request Throttled...Retry [$attempt] of [$maxAttempts] for: [$lat, $lon]"
					Start-Sleep -Seconds (5..30 | Get-Random )
					$response = Invoke-RestMethod -Uri "$($url)/$($encoded)?json=1" -WebSession $geoSession
					$attempt++
				}

				$results.add(
					[PSCustomObject]@{
						Address = $_
						Long    = $response.longt
						Lat     = $response.latt
					}
				)
			} catch {
				Write-Error "Error occurred while invoking the REST method: $_"
			}
		}
		$results
	}
}