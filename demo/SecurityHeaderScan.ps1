param (
	[string]$hostname,
	[string]$csvFile,
	[string[]]$domains,
	[string]$folderPath = "."
)

# Validate and create output directory
if (-not (Test-Path $folderPath)) {
	New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
	Write-Host "Created output directory: $folderPath" -ForegroundColor Green
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Determine domain list
$domainList = @()
if ($csvFile) {
	$domainList = Import-Csv $csvFile | Select-Object -ExpandProperty domain
} elseif ($domains) {
	$domainList = $domains
} elseif ($hostname) {
	$domainList = @($hostname)
} else {
	$domainList = @("badssl.com")
}

$allSummaryData = @()
$allTestData = @()

foreach ($domain in $domainList) {
	Write-Host "Scanning $domain..." -ForegroundColor Yellow

	try {
		# Launch scan
		$scanUrl = "https://observatory-api.mdn.mozilla.net/api/v2/scan?host=$domain"
		$Response = Invoke-RestMethod -Method Post -Uri $scanUrl

		# Get detailed results
		$testsUrl = "https://observatory-api.mdn.mozilla.net/api/v2/analyze?host=$domain"
		$TestResults = Invoke-RestMethod -Uri $testsUrl

		# Summary data
		$allSummaryData += [PSCustomObject]@{
			Hostname    = $domain
			Grade       = $Response.grade
			Score       = $Response.score
			'Scan Date' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
			State       = $Response.state
			Route       = $TestResults.tests.redirection.route -join ', '
			Destination = $TestResults.tests.redirection.destination
		}

		# Test results data
		foreach ($test in $TestResults.tests.PSObject.Properties) {
			$allTestData += [PSCustomObject]@{
				Hostname            = $domain
				'Test Name'         = $test.Name -replace '-', ' ' | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }
				'Score Modifier'    = $test.Value.score_modifier
				'Pass'              = $test.Value.pass
				'Result'            = $test.Value.result
				'Score Description' = $test.Value.score_description
			}
		}

		Write-Host "$domain - Grade: $($Response.grade), Score: $($Response.score)" -ForegroundColor Green

	} catch {
		Write-Host "Error scanning $domain : $($_.Exception.Message)" -ForegroundColor Red
	}

	# Rate limiting - wait 1 minute between domains (except last one)
	if ($domain -ne $domainList[-1]) {
		Write-Host "Waiting 60 seconds for rate limiting..." -ForegroundColor Cyan
		Start-Sleep -Seconds 60
	}
}

# Create consolidated Excel dashboard
if (Get-Module -ListAvailable -Name ImportExcel) {
	$excelFile = Join-Path $folderPath "SecurityDashboard_Multi_${timestamp}.xlsx"

	# Export to Excel with formatting
	$allSummaryData | Export-Excel -Path $excelFile -WorksheetName 'Summary' -AutoSize -BoldTopRow
	$allTestData | Export-Excel -Path $excelFile -WorksheetName 'Test Results' -AutoSize -BoldTopRow -ConditionalText @(
		New-ConditionalText -Text 'True' -BackgroundColor LightGreen
		New-ConditionalText -Text 'False' -BackgroundColor LightCoral
	)

	Write-Host "`nConsolidated Excel dashboard created: $excelFile" -ForegroundColor Green
} else {
	Write-Host "`nInstall ImportExcel module for dashboard: Install-Module ImportExcel" -ForegroundColor Yellow

	# Fallback to JSON
	$outputFile = Join-Path $folderPath "SecurityScan_Multi_${timestamp}.json"
	$fullResults = @{
		timestamp      = $timestamp
		summary        = $allSummaryData
		detailed_tests = $allTestData
	}
	$fullResults | ConvertTo-Json -Depth 10 | Out-File $outputFile
	Write-Host "Results exported to: $outputFile" -ForegroundColor Green
}

# Usage examples:
# .\SecurityHeaderScan.ps1 -hostname "example.com"
# .\SecurityHeaderScan.ps1 -domains @("mdn.dev", "mozilla.org", "24hour.trsretire.com")
# .\SecurityHeaderScan.ps1 -csvFile "domains.csv" -folderPath "C:\SecurityReports"

# .\demo\SecurityHeaderScan.ps1 -domains @("badssl.com", "blackkite.com", "bitsight.com", "auditboard.com", "www.g2.com") -folderPath "C:\temp"
