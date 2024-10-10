Add-Type -AssemblyName System.Windows.Forms

function Get-MKClipboardContent {
	[System.Windows.Forms.Clipboard]::GetText()
}

# Store initial clipboard value
$lastClipboardValue = Get-MKClipboardContent

# Polling loop to monitor clipboard changes
while ($true) {
	Start-Sleep -Seconds 2

	$currentClipboardValue = Get-MKClipboardContent

	if ($currentClipboardValue -ne $lastClipboardValue) {
		Write-Host "Clipboard changed!  New Content: $currentClipboardValue"
		$lastClipboardValue = $currentClipboardValue
	}
}