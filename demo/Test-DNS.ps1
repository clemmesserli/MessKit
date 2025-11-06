<#
.SYNOPSIS
    Performs DNS queries against multiple domains and nameservers at specified intervals with comprehensive reporting.

.DESCRIPTION
    This script tests DNS resolution for domains against multiple nameservers at regular intervals.
    Features include real-time progress tracking, error logging, performance statistics, summary reports,
    and optional Excel output with charts. Results are exported to CSV files and displayed in GridView.

.PARAMETER IntervalMinutes
    The interval in minutes between DNS query cycles. Default is 5 minutes. Range: 1-1440.

.PARAMETER DurationMinutes
    The total duration in minutes to run the test. Default is 60 minutes. Range: 1-10080.

.PARAMETER FolderPath
    The folder path where output files will be saved. Default is 'C:\mygithub\messkit'.

.PARAMETER DomainList
    Array of domain names to test. If not specified, uses default list.

.PARAMETER NameServerList
    Array of DNS server IP addresses to test against. If not specified, uses default list.

.PARAMETER CreateExcelReport
    Creates a comprehensive Excel report with multiple worksheets (Results, Errors, Performance, Summary)
    and performance charts. Requires ImportExcel module (Install-Module ImportExcel).

.OUTPUTS
    CSV Files:
    - DNS_Results_[timestamp].csv - All DNS query results
    - DNS_ErrorLog_[timestamp].csv - Error details (if errors occur)
    - DNS_Summary_[timestamp].csv - Test statistics and summary

    Excel File (if -CreateExcelReport used):
    - DNS_Report_[timestamp].xlsx - Multi-worksheet report with charts

.EXAMPLES
    .EXAMPLE
    .\Test-AWS.ps1
    Runs DNS queries every 5 minutes for 60 minutes (default settings).

    .EXAMPLE
    .\Test-AWS.ps1 -IntervalMinutes 1 -DurationMinutes 30
    Runs DNS queries every 1 minute for 30 minutes.

    .EXAMPLE
    .\Test-AWS.ps1 -IntervalMinutes 10 -DurationMinutes 120
    Runs DNS queries every 10 minutes for 2 hours.

    .EXAMPLE
    .\Test-AWS.ps1 -IntervalMinutes 2 -DurationMinutes 30 -FolderPath 'C:\temp'
    Runs DNS queries every 2 minutes for 30 minutes, saving output to C:\temp.

    .EXAMPLE
    .\Test-AWS.ps1 -DomainList @('google.com','microsoft.com') -NameServerList @('8.8.8.8','1.1.1.1')
    Tests custom domains against custom nameservers using default timing.

    .EXAMPLE
    .\Test-AWS.ps1 -CreateExcelReport
    Runs default test and creates comprehensive Excel report with charts.

    .EXAMPLE
    .\Test-AWS.ps1 -IntervalMinutes 1 -DurationMinutes 10 -CreateExcelReport -FolderPath 'C:\temp'
    Quick 10-minute test with 1-minute intervals, Excel report saved to C:\temp.

.NOTES
    The script provides real-time feedback with color-coded progress messages:
    - Green: All queries successful
    - Yellow: Some queries failed

    Performance metrics tracked include success rates, query times, and error patterns.
    Excel reports require the ImportExcel PowerShell module.
#>

param(
	[ValidateRange(1, 1440)][int]$IntervalMinutes = 5,
	[ValidateRange(1, 10080)][int]$DurationMinutes = 60,
	[ValidateScript({ Test-Path $_ -IsValid })][string]$FolderPath = 'C:\mygithub\messkit',
	[string[]]$DomainList,
	[string[]]$NameServerList,
	[switch]$CreateExcelReport
)

# Validate parameters
if ($IntervalMinutes -gt $DurationMinutes) {
	throw "IntervalMinutes ($IntervalMinutes) cannot be greater than DurationMinutes ($DurationMinutes)"
}

# Validate write permissions
try {
	if (!(Test-Path $FolderPath)) {
		New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
	}
	$testFile = Join-Path $FolderPath "test_write.tmp"
	"test" | Out-File -FilePath $testFile -Force
	Remove-Item $testFile -Force
} catch {
	throw "Cannot write to folder: $FolderPath. Error: $($_.Exception.Message)"
}

# Use default domain list if not provided
if (-not $DomainList) {
	$DomainList = @(
		'www.google.com'
		'www.amazon.com'
		'portal.azure.com'
		'cloud.google.com'
	)
}

# Use default nameserver list if not provided
if (-not $NameServerList) {
	$NameServerList = @(
		'8.8.8.8'
		'8.8.4.4'
		'1.1.1.1'
		'1.0.0.1'
		'208.67.222.222'
		'208.67.220.220'
	)
}

$allResults = @()
$errorLog = @()
$performanceStats = @()
$startTime = Get-Date
$endTime = (Get-Date).AddMinutes($DurationMinutes)
$iteration = 0
$totalIterations = [math]::Floor($DurationMinutes / $IntervalMinutes) + 1
$intervalSeconds = $IntervalMinutes * 60

Write-Host "=== DNS Test Configuration ===" -ForegroundColor Cyan
Write-Host "Test Duration: $DurationMinutes minutes"
Write-Host "Query Interval: $IntervalMinutes minutes"
Write-Host "Total Iterations: $totalIterations"
Write-Host "Domains: $($DomainList -join ', ')"
Write-Host "Name Servers: $($NameServerList -join ', ')"
Write-Host "Output Folder: $FolderPath"
Write-Host "Start Time: $startTime"
Write-Host ""

do {
	$iteration++
	$progressPercent = [math]::Round(($iteration / $totalIterations) * 100, 1)
	Write-Host "Starting DNS queries ($iteration of $totalIterations - $progressPercent%) at $(Get-Date)"

	$results = foreach ($domain in $DomainList) {
		foreach ($nameServer in $NameServerList) {
			$params = @{
				type             = 'A'
				name             = $domain
				server           = $nameServer
				NoRecursion      = $false
				NoHostsFile      = $true
				CacheOnly        = $false
				LlmnrNetbiosOnly = $false
			}

			try {
				$queryTime = Measure-Command { $result = Resolve-DnsName @params }
				$cname = ($result | Where-Object { $_.Type -eq 'CNAME' }).NameHost
				$ips = ($result | Where-Object { $_.IPAddress }).IPAddress -join ', '
				$timestamp = (Get-Date).ToUniversalTime().ToString('ddd MMM d HH:mm:ss UTC yyyy')

				# Consider query failed if no CNAME or IP4Address is null/empty
				if (-not $cname -or [string]::IsNullOrEmpty($ips)) {
					throw "Query failed: No CNAME returned or IP4Address is null"
				}

				$nameHost = $cname

				[PSCustomObject]@{
					TimeStamp  = $timestamp
					FQDN       = $domain
					NameServer = $nameServer
					QueryType  = 'A'
					NameHost   = $nameHost
					IP4Address = $ips
					QueryTime  = [math]::Round($queryTime.TotalMilliseconds)
				}
			} catch {
				$timestamp = (Get-Date).ToUniversalTime().ToString('ddd MMM d HH:mm:ss UTC yyyy')

				# Log error details
				$errorLog += [PSCustomObject]@{
					TimeStamp  = $timestamp
					Domain     = $domain
					NameServer = $nameServer
					Error      = $_.Exception.Message
				}

				[PSCustomObject]@{
					TimeStamp  = $timestamp
					FQDN       = $domain
					NameServer = $nameServer
					QueryType  = 'A'
					NameHost   = 'ERROR'
					IP4Address = $_.Exception.Message
					QueryTime  = 0
				}
			}
		}
	}

	$allResults += $results
	$successCount = ($results | Where-Object { $_.NameHost -ne 'ERROR' }).Count
	$errorCount = ($results | Where-Object { $_.NameHost -eq 'ERROR' }).Count
	$validQueries = $results | Where-Object { $_.QueryTime -gt 0 }
	$avgQueryTime = if ($validQueries.Count -gt 0) {
		($validQueries | Measure-Object -Property QueryTime -Average).Average
	} else {
		0
 }

	$performanceStats += [PSCustomObject]@{
		Iteration    = $iteration
		TimeStamp    = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
		SuccessCount = $successCount
		ErrorCount   = $errorCount
		AvgQueryTime = [math]::Round($avgQueryTime, 2)
	}

	Write-Host "Completed $(($results | Measure-Object).Count) queries - Success: $successCount, Errors: $errorCount, Avg Time: $([math]::Round($avgQueryTime, 2))ms" -ForegroundColor $(if ($errorCount -gt 0) {
			'Yellow'
		} else {
			'Green'
		})

	if ((Get-Date) -lt $endTime) {
		Write-Host "Waiting $IntervalMinutes minutes..."
		Start-Sleep -Seconds $intervalSeconds
	}
} while ((Get-Date) -lt $endTime)

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$testDuration = (Get-Date) - $startTime

# Generate enhanced summary statistics with safe calculations
$totalQueries = $allResults.Count
$successfulQueries = ($allResults | Where-Object { $_.NameHost -ne 'ERROR' }).Count
$failedQueries = ($allResults | Where-Object { $_.NameHost -eq 'ERROR' }).Count
$successRate = if ($totalQueries -gt 0) {
 [math]::Round(($successfulQueries / $totalQueries) * 100, 2)
} else {
 0
}
$validQueryTimes = $allResults | Where-Object { $_.QueryTime -gt 0 }
$avgQueryTime = if ($validQueryTimes.Count -gt 0) {
 [math]::Round(($validQueryTimes | Measure-Object -Property QueryTime -Average).Average, 2)
} else {
 0
}
$maxQueryTime = if ($allResults.Count -gt 0) {
 ($allResults | Measure-Object -Property QueryTime -Maximum).Maximum
} else {
 0
}
$minQueryTime = if ($validQueryTimes.Count -gt 0) {
 ($validQueryTimes | Measure-Object -Property QueryTime -Minimum).Minimum
} else {
 0
}

# Executive Summary with SLA indicators
$slaThreshold = 95.0  # 95% success rate threshold
$performanceThreshold = 1000  # 1000ms response time threshold
$slaStatus = if ($successRate -ge $slaThreshold) {
 "✅ PASS"
} else {
 "❌ FAIL"
}
$performanceStatus = if ($avgQueryTime -le $performanceThreshold) {
 "✅ GOOD"
} else {
 "⚠️ SLOW"
}

$summary = [PSCustomObject]@{
	'Test Duration'       = "$([math]::Round($testDuration.TotalMinutes, 1)) minutes"
	'Total Queries'       = $totalQueries
	'Successful Queries'  = $successfulQueries
	'Failed Queries'      = $failedQueries
	'Success Rate %'      = $successRate
	'SLA Status'          = $slaStatus
	'Avg Query Time (ms)' = $avgQueryTime
	'Performance Status'  = $performanceStatus
	'Max Query Time (ms)' = $maxQueryTime
	'Min Query Time (ms)' = $minQueryTime
}

$executiveSummary = [PSCustomObject]@{
	'Test Configuration' = "Domains: $($DomainList.Count) | Name Servers: $($NameServerList.Count) | Duration: $([math]::Round($testDuration.TotalMinutes, 1))min"
	'Overall Health'     = if ($successRate -ge $slaThreshold -and $avgQueryTime -le $performanceThreshold) {
		"🟢 HEALTHY"
 } elseif ($successRate -ge 90) {
		"🟡 WARNING"
 } else {
		"🔴 CRITICAL"
 }
	'Success Rate'       = "$successRate% ($slaStatus)"
	'Performance'        = "$avgQueryTime ms ($performanceStatus)"
	'Key Issues'         = if ($failedQueries -gt 0) {
		"$failedQueries failed queries detected"
 } else {
		"No issues detected"
 }
	'Recommendation'     = if ($successRate -lt $slaThreshold) {
		"Investigate DNS infrastructure"
 } elseif ($avgQueryTime -gt $performanceThreshold) {
		"Review DNS server performance"
 } else {
		"System operating within acceptable parameters"
 }
}

# Export standard files with error handling
try {
	$allResults | Export-Csv -Path "$FolderPath\DNS_Results_$timestamp.csv" -NoTypeInformation
	Write-Host "Results exported to: DNS_Results_$timestamp.csv" -ForegroundColor Green
} catch {
	Write-Warning "Failed to export results CSV: $($_.Exception.Message)"
}

if ($errorLog.Count -gt 0) {
	try {
		$errorLog | Export-Csv -Path "$FolderPath\DNS_ErrorLog_$timestamp.csv" -NoTypeInformation
		Write-Host "Error log exported to: DNS_ErrorLog_$timestamp.csv" -ForegroundColor Yellow
	} catch {
		Write-Warning "Failed to export error log CSV: $($_.Exception.Message)"
	}
}

try {
	$summary | Export-Csv -Path "$FolderPath\DNS_Summary_$timestamp.csv" -NoTypeInformation
	Write-Host "Summary exported to: DNS_Summary_$timestamp.csv" -ForegroundColor Green
} catch {
	Write-Warning "Failed to export summary CSV: $($_.Exception.Message)"
}

# Create Excel report if requested
if ($CreateExcelReport) {
	try {
		if (Get-Module -ListAvailable -Name ImportExcel) {
			Import-Module ImportExcel
			$excelPath = "$FolderPath\DNS_Report_$timestamp.xlsx"

			# Generate analytics data with safe calculations
			$domainStats = $allResults | Group-Object FQDN | ForEach-Object {
				$successCount = ($_.Group | Where-Object { $_.NameHost -ne 'ERROR' }).Count
				$totalCount = $_.Count
				$validTimes = $_.Group | Where-Object { $_.QueryTime -gt 0 }
				$avgTime = if ($validTimes.Count -gt 0) {
					[math]::Round(($validTimes | Measure-Object -Property QueryTime -Average).Average, 1)
    } else {
					0
    }

				[PSCustomObject]@{
					Domain           = $_.Name
					'Total Queries'  = $totalCount
					'Successful'     = $successCount
					'Failed'         = $totalCount - $successCount
					'Success Rate %' = if ($totalCount -gt 0) {
						[math]::Round(($successCount / $totalCount) * 100, 1)
     } else {
						0
     }
					'Avg Query Time' = $avgTime
					'Status'         = if (($successCount / $totalCount) -ge 0.95) {
						"✅ GOOD"
     } else {
						"❌ POOR"
     }
				}
			}

			$nameServerStats = $allResults | Group-Object NameServer | ForEach-Object {
				$successCount = ($_.Group | Where-Object { $_.NameHost -ne 'ERROR' }).Count
				$totalCount = $_.Count
				$validTimes = $_.Group | Where-Object { $_.QueryTime -gt 0 }
				$avgTime = if ($validTimes.Count -gt 0) {
					[math]::Round(($validTimes | Measure-Object -Property QueryTime -Average).Average, 1)
    } else {
					0
    }

				[PSCustomObject]@{
					'Name Server'    = $_.Name
					'Total Queries'  = $totalCount
					'Successful'     = $successCount
					'Failed'         = $totalCount - $successCount
					'Success Rate %' = if ($totalCount -gt 0) {
						[math]::Round(($successCount / $totalCount) * 100, 1)
     } else {
						0
     }
					'Avg Query Time' = $avgTime
					'Status'         = if (($successCount / $totalCount) -ge 0.95) {
						"✅ GOOD"
     } else {
						"❌ POOR"
     }
				}
			}

			# Combine executive and detailed summary into single worksheet
			$combinedSummary = @()
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Test Configuration'; 'Value' = "Domains: $($DomainList.Count) | Name Servers: $($NameServerList.Count) | Duration: $([math]::Round($testDuration.TotalMinutes, 1))min" }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Overall Health'; 'Value' = if ($successRate -ge $slaThreshold -and $avgQueryTime -le $performanceThreshold) {
					"🟢 HEALTHY"
				} elseif ($successRate -ge 90) {
					"🟡 WARNING"
				} else {
					"🔴 CRITICAL"
				}
   }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Success Rate'; 'Value' = "$successRate% ($slaStatus)" }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Performance'; 'Value' = "$avgQueryTime ms ($performanceStatus)" }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Total Queries'; 'Value' = $totalQueries }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Successful Queries'; 'Value' = $successfulQueries }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Failed Queries'; 'Value' = $failedQueries }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Max Query Time (ms)'; 'Value' = $maxQueryTime }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Min Query Time (ms)'; 'Value' = $minQueryTime }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Key Issues'; 'Value' = if ($failedQueries -gt 0) {
					"$failedQueries failed queries detected"
				} else {
					"No issues detected"
				}
   }
			$combinedSummary += [PSCustomObject]@{ 'Metric' = 'Recommendation'; 'Value' = if ($successRate -lt $slaThreshold) {
					"Investigate DNS infrastructure"
				} elseif ($avgQueryTime -gt $performanceThreshold) {
					"Review DNS server performance"
				} else {
					"System operating within acceptable parameters"
				}
   }

			# Export worksheets in specified order
			$combinedSummary | Export-Excel -Path $excelPath -WorksheetName "Summary" -AutoSize -BoldTopRow -CellStyleSB {
				param($workSheet)
				$workSheet.Cells["B:B"].Style.HorizontalAlignment = 'left'
			}


			$performanceStats | Export-Excel -Path $excelPath -WorksheetName "Performance" -AutoSize -AutoFilter -FreezeTopRow
			$domainStats | Export-Excel -Path $excelPath -WorksheetName "Domain_Stats" -AutoSize -AutoFilter -FreezeTopRow
			$nameServerStats | Export-Excel -Path $excelPath -WorksheetName "NameServer_Stats" -AutoSize -AutoFilter -FreezeTopRow
			$allResults | Export-Excel -Path $excelPath -WorksheetName "Query_Results" -AutoSize -AutoFilter -FreezeTopRow -BoldTopRow -TableStyle Medium2
			if ($errorLog.Count -gt 0) {
				$errorLog | Export-Excel -Path $excelPath -WorksheetName "Errors" -AutoSize -AutoFilter -FreezeTopRow
			}

			# Export data without problematic chart creation
			Write-Host "Excel report created with data tables and executive summary" -ForegroundColor Green

			Write-Host "Excel dashboard report created: $excelPath" -ForegroundColor Green
		} else {
			Write-Warning "ImportExcel module not found. Install with: Install-Module ImportExcel"
		}
	} catch {
		Write-Warning "Failed to create Excel report: $($_.Exception.Message)"
	}
}

Write-Host "`n=== Executive Summary ===" -ForegroundColor Cyan
$executiveSummary | Format-List

Write-Host "`n=== Detailed Summary ===" -ForegroundColor Cyan
$summary | Format-List

$allResults | Out-GridView -Title "DNS Query Results - $DurationMinutes Minute Test"