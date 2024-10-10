function Invoke-RestMethodWithThrottle {
  param (
    [string]$Uri,
    [hashtable]$Headers = @{},
    [int]$MaxRetries = 3,
    [int]$MinSleepSeconds = 1,
    [int]$MaxSleepSeconds = 10
  )

  # # Example usage
  # $uri = "https://example.com/api/endpoint"
  # $response = Invoke-RestMethodWithThrottle -Uri $uri -MaxRetries 5 -MinSleepSeconds 5 -MaxSleepSeconds 15

  # if ($response) {
  # 	Write-Output "Response received: $response"
  # } else {
  # 	Write-Output "Failed to get a valid response after retries."
  # }

  $retryCount = 0

  while ($retryCount -lt $MaxRetries) {
    try {
      $response = Invoke-RestMethod -Uri $Uri -Headers $Headers -ErrorAction Stop

      # Check for throttling response
      if ($response.ResponseCode -eq "006") {
        Write-Host "Request throttled. Waiting before retrying..."
        $sleepTime = Get-Random -Minimum $MinSleepSeconds -Maximum $MaxSleepSeconds
        Start-Sleep -Seconds $sleepTime
        $retryCount++
      } else {
        return $response
      }
    } catch {
      Write-Host "Error: $_"
      return $null
    }
  }

  Write-Host "Max retries reached. Exiting..."
  return $null
}
