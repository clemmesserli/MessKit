Function Show-BalloonTip {
	[CmdletBinding()]
	Param (
		[Parameter()]
		[string]$Text = (Get-MyParam).'Show-BalloonTip'.Text,

		[Parameter()]
		[string]$Title = (Get-MyParam).'Show-BalloonTip'.Title,

		[Parameter()]
		[ValidateSet("None", "Info", "Warning", "Error")]
		[string]$Icon = (Get-MyParam).'Show-BalloonTip'.Icon,

		[Parameter()]
		[string]$IconLocation = (Get-MyParam).'Show-BalloonTip'.IconLocation
	)

	Begin {}

	Process {
		# Load the required assemblies
		Add-Type -AssemblyName System.Windows.Forms

		# Create the notification object after we first check to see if one may already exist
		if ($null -eq $script:balloonTip) {
			$script:balloonTip = New-Object System.Windows.Forms.NotifyIcon
		}

		# Define the icon for the system tray
		if (Test-Path $IconLocation) {
			# Use custom icon path location
			$balloonTip.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($IconLocation)
		} else {
			# Grab the icon used by calling application
			$balloonTip.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($(Get-Process -Id $pid).Path)
		}

		# Display title of balloon window
		$balloonTip.BalloonTipTitle = $Title
		# Type of balloon icon
		$balloonTip.BalloonTipIcon = $Icon

		# Notification message
		$balloonTip.BalloonTipText = $Text

		# Make balloon tip visible when called
		$balloonTip.Visible = $True

		# Show notification
		$balloonTip.ShowBalloonTip(5000)
	}

	End {}
}