Function Convert-MKLatLongToAddress {
  <#
    .SYNOPSIS
        Converts latitude and longitude coordinates into physical addresses.

    .DESCRIPTION
        The Convert-MKLatLongToAddress function resolves geographic coordinates to addresses by:
        - Accepting an array of coordinate hashtables with Lat/Long properties
        - Calling the geocode.xyz web service API for reverse geocoding
        - Implementing rate limiting with a configurable sleep timer between requests
        - Returning detailed location information including address components, timezone, and points of interest
        - Supporting verbose output for monitoring conversion progress

        This function is useful for GIS data processing, location-based analysis,
        and converting raw GPS data into human-readable addresses.

    .PARAMETER coordinateList
        An array of hashtables, each containing Lat and Long keys with coordinate values.
        Format: @( @{Lat = 43.87475; Long = -103.45846}, @{Lat = 36.05137; Long = -112.13094} )

    .PARAMETER sleepTimer
        Number of seconds to wait between API calls to avoid rate limiting.
        Default value is 5 seconds, adjust based on API usage limitations.

    .PARAMETER url
        Base URL for the geocoding service API.
        Default value is "https://geocode.xyz/".

    .EXAMPLE
        PS> Convert-MKLatLongToAddress -coordinateList @(
            @{Long = -103.45846; Lat = 43.87475}
        )

        Returns the address information for Mount Rushmore National Memorial.

    .EXAMPLE
        PS> Convert-MKLatLongToAddress -coordinateList @(
            @{Long = -103.45846; Lat = 43.87475},
            @{Long = -112.13094; Lat = 36.05137}
        ) -sleepTimer 10 -Verbose

        Returns address information for Mount Rushmore and Grand Canyon with increased delay between requests
        and detailed progress information.

    .EXAMPLE
        PS> $coords = Import-Csv -Path "C:\GpsData.csv" | ForEach-Object {
            @{Lat = $_.Latitude; Long = $_.Longitude}
        }
        PS> $locations = Convert-MKLatLongToAddress -coordinateList $coords
        PS> $locations | Export-Csv -Path "C:\Addresses.csv" -NoTypeInformation

        Processes coordinates from a CSV file and exports the resulting addresses to a new file.

    .NOTES
        File Name      : Convert-MKLatLongToAddress.ps1
        Author         : MessKit
        Requires       : PowerShell 5.1 or later
        Version        : 1.0

        API Usage      : This function uses the free geocode.xyz service which has rate limits.
                         Excessive usage may result in temporary IP blocking.
                         Consider using a paid API key for production use.

        Confidence     : The API returns a confidence score for each result.
                         Low confidence scores may indicate imprecise address resolution.

    .LINK
        https://github.com/MyGitHub/MessKit
        https://geocode.xyz/api
    #>
  [cmdletbinding()]
  Param (
    [Parameter(Mandatory, HelpMessage = 'Array of hashtables with Lat and Long keys')]
    [hashtable[]]$coordinateList,

    [Parameter(HelpMessage = 'Seconds to wait between API requests')]
    [int]$sleepTimer = 5,

    [Parameter(HelpMessage = 'Base URL for the geocoding API')]
    [string]$url = 'https://geocode.xyz/'
  )

  Begin {}

  Process {
    Write-Verbose 'Creating a web session'
    if (!($session)) {
      $null = Invoke-RestMethod -Uri $url -SessionVariable session
    }

    $total = $coordinateList.count
    $count = 0
    $coordinateList | ForEach-Object {
      $count++
      if ($count -ne $total) {
        Write-Verbose "Sleeping for $($sleepTimer) seconds..."
        Start-Sleep -Seconds $sleepTimer
      }
      Write-Verbose "Now resolving $_  ($count of $total) `n"
      $coordinate = $_.lat, $_.long -join ','
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