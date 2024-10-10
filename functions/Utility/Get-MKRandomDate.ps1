

function Get-MKRandomDate {
	$start = (Get-Date).AddDays(-14)
	$end = Get-Date
	$range = New-TimeSpan -Start $start -End $end
	$randomSeconds = Get-Random -Minimum 0 -Maximum $range.TotalSeconds
	return $start.AddSeconds($randomSeconds)
}