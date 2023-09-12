Function Enable-ScreenLock {
	<#
	.SYNOPSIS
		Enable screen and optional keyboard lock
	.DESCRIPTION
		Enable screen and optional keyboard lock if you need to finish software installs for instance (default 20 min) while disallowing an end-user to cancel or kill the process.
	.EXAMPLE
		Enable-ScreenLock -minutes 20 -verbose
	.NOTES
		Presently the lock only impacts the active monitor so if user has multiple monitors, they will still have mouse and keyboard access to non-active displays
	#>
	[CmdletBinding()]
	Param (
		[Int]$minutes = 20,

		[Switch]$DimScreen
	)

	Begin {}

	Process {
		# When run without administrator privileges, the keyboard will not be blocked!

		# Get access to API functions that block user input blocking of keyboard input requires admin privileges
		$code = @'
    [DllImport("user32.dll")]
    public static extern int ShowCursor(bool bShow);

    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
'@

		$userInput = Add-Type -MemberDefinition $code -Name Blocker -Namespace UserInput -PassThru

		# Get access to UI functionality
		Add-Type -AssemblyName PresentationFramework
		Add-Type -AssemblyName PresentationCore

		# Set window opacity
		$opacity = 1
		if ($DimScreen) { $opacity = 200 }

		# Create a message label
		$label = New-Object -TypeName Windows.Controls.Label
		$label.FontSize = 60
		$label.FontFamily = 'Consolas'
		$label.FontWeight = 'Bold'
		$label.Background = 'Transparent'
		$label.Foreground = 'Blue'
		$label.VerticalAlignment = 'Center'
		$label.HorizontalAlignment = 'Center'

		# Create a window
		$window = New-Object -TypeName Windows.Window
		$window.WindowStyle = 'None'
		$window.AllowsTransparency = $true
		$color = [Windows.Media.Color]::FromArgb($opacity, 0, 0, 0)
		$window.Background = [Windows.Media.SolidColorBrush]::new($color)
		$window.Opacity = 0.8
		$window.Left = $window.Top = 0
		$window.WindowState = 'Maximized'
		$window.Topmost = $true
		$window.Content = $label

		# Block user input
		$null = $userInput::BlockInput($true)
		$null = $userInput::ShowCursor($false)

		# Calculate end-time based upon user input (Default: 20 min)
		$finishTime = $(Get-Date).AddMinutes($minutes)

		# Show window and display message
		$null = $window.Dispatcher.Invoke{
			$window.Show()
			$($minutes * 60)..1 | ForEach-Object {
				# Create timespan to display countdown to user
				$elapsedTime = New-TimeSpan -Start $(Get-Date) -End $finishTime
				$label.Content = "Time Remaining: $($elapsedTime.ToString("hh\:mm\:ss"))"
				$label.Dispatcher.Invoke([Action] {}, 'Background')
				Start-Sleep -Seconds 1
			}
			$window.Close()
		}

		# Unblock user input
		$null = $userInput::ShowCursor($true)
		$null = $userInput::BlockInput($false)
	}

	End {}
}