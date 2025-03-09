Function Convert-AddressToLatLong {
  <#
    .SYNOPSIS
        Translates addresses into latitude and longitude coordinates.
    .DESCRIPTION
        This function converts street addresses, landmarks, or IP addresses into geographic coordinates (latitude and longitude)
        using the geocode.xyz API service. Since this is a free third-party webservice, it implements rate limiting to avoid
        being throttled. The function automatically adds a delay between requests.
    .PARAMETER addressList
        An array of strings containing addresses to geocode. These can be street addresses, landmark descriptions, or IP addresses.
    .PARAMETER sleepTimer
        The number of seconds to wait between API calls to avoid rate limiting.
        Default is 5 seconds.
    .PARAMETER url
        The base URL of the geocoding service.
        Default is "https://geocode.xyz/".
    .EXAMPLE
        Convert-AddressToLatLong -addressList @(
            '13000 SD-244, Keystone, SD 57751',
            'Grand Canyon National Park, P.O. Box 129, Grand Canyon, AZ 86023',
            '8.8.8.8'
        ) -verbose

        Converts three different types of addresses (a street address, a landmark, and an IP address)
        into geographic coordinates while displaying verbose progress information.
    .EXAMPLE
        $addresses = Get-Content -Path .\addresses.txt
        Convert-AddressToLatLong -addressList $addresses -sleepTimer 10

        Reads addresses from a text file and increases the delay between requests to 10 seconds.
    .OUTPUTS
        Returns PSCustomObjects with the following properties:
        - Address: The original address string
        - Long: Longitude coordinate
        - Lat: Latitude coordinate
    .NOTES
        The geocode.xyz service has usage limitations for free access. Excessive requests may result in
        temporary blocks or errors. Consider increasing the sleepTimer value if you encounter issues.
    .LINK
        https://geocode.xyz/
    #>
  [cmdletbinding()]
  param(
    [string[]]$addressList,

    [int]$sleepTimer = 5,

    [string]$url = 'https://geocode.xyz/'
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