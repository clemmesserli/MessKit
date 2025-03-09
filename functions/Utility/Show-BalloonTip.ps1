<#
.SYNOPSIS
    Displays a balloon notification in the Windows system tray.

.DESCRIPTION
    The Show-BalloonTip function displays a customizable notification balloon in the Windows system tray.
    You can specify the text content, title, icon type, and optionally a custom icon.
    The notification will display for 5 seconds by default.

.PARAMETER Text
    The message content to display in the notification balloon.
    If not specified, the value is taken from Get-MyParam configuration.

.PARAMETER Title
    The title of the notification balloon.
    If not specified, the value is taken from Get-MyParam configuration.

.PARAMETER Icon
    The icon type to display in the notification. Must be one of: "None", "Info", "Warning", or "Error".
    If not specified, the value is taken from Get-MyParam configuration.

.PARAMETER IconLocation
    The file path to a custom icon to use in the system tray.
    If not specified, the value is taken from Get-MyParam configuration.
    If the specified path is invalid, the icon of the calling process will be used.

.EXAMPLE
    Show-BalloonTip -Text "Task completed" -Title "Notification" -Icon "Info"

    Displays an information notification with the title "Notification" and message "Task completed".

.EXAMPLE
    Show-BalloonTip -Text "Warning: Low disk space" -Title "System Warning" -Icon "Warning"

    Displays a warning notification about low disk space.

.EXAMPLE
    Show-BalloonTip -Text "Process failed" -Title "Error" -Icon "Error" -IconLocation "C:\Icons\error.ico"

    Displays an error notification using a custom icon from the specified location.

.NOTES
    The notification balloon will appear for approximately 5 seconds before automatically closing.
    This function requires Windows Forms assembly to be loaded.
#>
Function Show-BalloonTip {
  [CmdletBinding()]
  Param (
    [Parameter()]
    [string]$Text = (Get-MyParam).'Show-BalloonTip'.Text,

    [Parameter()]
    [string]$Title = (Get-MyParam).'Show-BalloonTip'.Title,

    [Parameter()]
    [ValidateSet('None', 'Info', 'Warning', 'Error')]
    [string]$Icon = (Get-MyParam).'Show-BalloonTip'.Icon,

    [Parameter()]
    [string]$IconLocation = (Get-MyParam).'Show-BalloonTip'.IconLocation
  )

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
}