Function Convert-MKIPtoAddress {
  <#
    .SYNOPSIS
        Converts IP addresses to physical geographic locations.

    .DESCRIPTION
        The Convert-MKIPtoAddress function resolves IP addresses to physical locations by:
        - Accepting an array of IP addresses as input
        - Calling the geocode.xyz web service API for IP geolocation
        - Implementing rate limiting with a configurable sleep timer between requests
        - Returning detailed location information including address components, coordinates, and points of interest
        - Supporting verbose output for monitoring resolution progress

        This function is useful for network analysis, security investigations, visitor tracking,
        and mapping the geographic distribution of network traffic.

    .PARAMETER addressList
        An array of IP address strings to convert to physical locations.
        Example: @('8.8.8.8', '1.1.1.1')

    .PARAMETER sleepTimer
        Number of seconds to wait between API calls to avoid rate limiting.
        Default value is 5 seconds, adjust based on API usage limitations.

    .PARAMETER url
        Base URL for the geocoding service API.
        Default value is "https://geocode.xyz".

    .EXAMPLE
        PS> Convert-MKIPtoAddress -addressList @('8.8.8.8') -Verbose
        Resolves Google's public DNS IP address to its physical location with verbose progress output.

    .EXAMPLE
        PS> Convert-MKIPtoAddress -addressList @('8.8.8.8', '1.1.1.1') -sleepTimer 10
        Resolves multiple IP addresses with increased delay between requests to avoid API throttling.

    .EXAMPLE
        PS> Get-Content -Path "C:\IPs.txt" | Convert-MKIPtoAddress
        Reads IP addresses from a text file and resolves each to a physical location.

    .EXAMPLE
        PS> Convert-MKIPtoAddress -addressList (Get-MKSuspiciousIPs) -url "https://alternate-geocode.xyz"
        Uses a different geocoding service URL and IP addresses from another function.

    .NOTES
        File Name      : Convert-MKIPtoAddress.ps1
        Author         : MessKit
        Requires       : PowerShell 5.1 or later
        Version        : 1.0

        API Usage      : This function uses the free geocode.xyz service which has rate limits.
                       Excessive usage may result in temporary IP blocking.
                       Consider using a paid API key for production use.

        Accuracy       : Geolocation from IP addresses provides approximate locations,
                       typically accurate to the city/region level, not exact addresses.

    .LINK
        https://github.com/MyGitHub/MessKit
        https://geocode.xyz/api
    #>
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true,
      HelpMessage = 'Array of IP addresses to resolve')]
    [string[]]$addressList,

    [Parameter(HelpMessage = 'Seconds to wait between API requests')]
    [int]$sleepTimer = 5,

    [Parameter(HelpMessage = 'Base URL for the geocoding API')]
    [string]$url = 'https://geocode.xyz'
  )

  Begin {}

  Process {
    Write-Verbose 'Creating a web session'
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