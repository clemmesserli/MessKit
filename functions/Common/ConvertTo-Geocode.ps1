Function ConvertTo-Geocode {
	<#
	.SYNOPSIS
		translate addresses into latitude and longitude coordinates
	.DESCRIPTION
		This function calls a free ThirdParty webservice which will throttle results so a sleep timer has been added to help
	.EXAMPLE
		ConvertTo-Geocode -addressList @(
			'1 Elliott Dr, Iowa City, IA 52242',
			'1060 W Addison St, Chicago, IL 60613',
			'162.123.18.140'
		) -verbose
	#>
	[CmdletBinding()]
	Param (
		[String[]]$addressList,

		[String]$url = "https://geocode.xyz/"
	)

	Begin {}

	Process {
		Write-Verbose "Creating a web session"
		if (!($session)) {
			$null = Invoke-RestMethod -Uri $url -SessionVariable session
		}

		$total = $addressList.count
		$count = 0
		$Results = [System.Collections.Generic.List[PSObject]]::New()
		$addressList | ForEach-Object {
			$count++

			Write-Verbose "Now resolving $_ ($count of $total) `n"

			$encoded = [Net.WebUtility]::UrlEncode($_)
			$response = Invoke-RestMethod "$($url)/$($encoded)?json=1" -WebSession $session

			Write-Verbose "Response = $response"

			$Results.add(
				[pscustomobject]@{
					Address = $_
					Long    = $response.longt
					Lat     = $response.latt
				}
			)

			if ($count -ne $total) {
				$sleepTimer = (10..30 | Get-Random )
				Write-Verbose "Sleeping for $($sleepTimer) seconds..."
				Start-Sleep -Seconds $sleepTimer
			}
		}
		$Results
	}

	End {}
}