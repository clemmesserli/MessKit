function Enable-MKScreenLock {
  <#
  .SYNOPSIS
  Enable a screen and keyboard lock with various customization options like audio, image, message content, opacity, font color, etc.

  .DESCRIPTION
  This function creates a custom screen lock overlay on all screens with specified settings like audio playback,
  image overlay, message content, font color, opacity, blur radius, and more.

  It captures the current screen content, applies blur and overlay effects, then blocks user input and hides
  the cursor for the specified duration. The function displays a countdown timer showing remaining lock time.

  Note: Keyboard blocking requires administrator privileges. Without admin rights, only visual elements will be displayed.

  .PARAMETER AudioPath
  Path to the audio file to be played during the screen lock. The audio will loop until the lock duration expires.
  Must be a valid file path to an audio file supported by Windows Media Player.

  .PARAMETER AudioVolume
  Volume level for the audio playback, ranging from 0 (muted) to 100 (maximum).
  Default is 50.

  .PARAMETER BlurRadius
  Radius of the blur effect applied to the background image, ranging from 0 (no blur) to 100 (maximum blur).
  Higher values create a more obscured background. Default is 25.

  .PARAMETER Duration
  Duration for which the screen lock will be active, specified as a TimeSpan object.
  Default is 20 minutes. For example: [TimeSpan]::FromMinutes(5) or "00:05:00".

  .PARAMETER Opacity
  Opacity level of the screen lock overlay, ranging from 0 (completely transparent) to 100 (completely opaque).
  Controls the darkness of the overlay. Default is 20.

  .PARAMETER FontColor
  Color of the font used for the message content and countdown timer.
  Accepts predefined color names (black, blue, brown, cyan, green, gray, magenta, orange, purple, red, white, yellow).
  Default is green (#00FF00).

  .PARAMETER ImagePath
  Path to a custom image to be displayed as an overlay on the locked screen.
  Must be a valid file path to an image file.

  .PARAMETER ImageOpacity
  Opacity level of the custom image overlay, ranging from 0 (completely transparent) to 100 (completely opaque).
  Default is 40.

  .PARAMETER MessageContent
  Content of the message to be displayed on the screen lock overlay.
  Can be provided via pipeline input.

  .EXAMPLE
  "Locked For Patching" | Enable-MKScreenLock -duration 00:00:15

  Creates a screen lock with the message "Locked For Patching" displayed, lasting for 15 seconds.
  The message content is provided through the pipeline.

  .EXAMPLE
  Enable-MKScreenLock -ImagePath "C:\temp\hacker-07.jpg" -MessageContent "Locked Screen" -ImageOpacity 60 -Opacity 60 -duration 00:00:15 -BlurRadius 60 -AudioPath "C:\temp\StrangerThings.mp3"

  Creates a highly customized screen lock with:
  - Custom background image with 60% opacity
  - Message "Locked Screen" displayed
  - Background overlay with 60% opacity (darker)
  - Heavy blur effect (radius 60)
  - Audio playback from the specified file
  - Duration of 15 seconds

  .EXAMPLE
  $params = @{
    AudioPath = "C:\Temp\SomebodyWatchingMe.mp3"
    ImagePath = "C:\Temp\hacker-10.jpg"
    MessageContent = "Machine self-destruct has been activated."
    Duration = "00:06:00"
    AudioVolume = 25
  }
  Enable-MKScreenLock @params

  Demonstrates using splatting to pass parameters to create a screen lock with:
  - Custom audio at 25% volume
  - Custom background image
  - Custom message
  - 6-minute duration

  .INPUTS
  [System.String]
  You can pipe a string to this function as the MessageContent parameter.

  .OUTPUTS
  None. This function does not generate any output.

  .NOTES
  Requirements:
  - Administrator privileges are required for keyboard blocking functionality
  - Windows operating system with .NET Framework support
  - Multiple monitors are supported (lock appears on all screens)

  Security considerations:
  - This function should be used responsibly
  - While active, users cannot interact with their system
  - An emergency override is not provided by default

  Warning:
  Some parameters are marked with DontShow attribute (AudioVolume, BlurRadius, ImageOpacity)
  as they are considered advanced settings with reasonable defaults.
  #>
  [CmdletBinding()]
  param (
    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$AudioPath,

    [Parameter(DontShow)]
    [ValidateRange(0, 100)]
    [int]$AudioVolume = 50,

    [Parameter(DontShow)]
    [ValidateRange(0, 100)]
    [int]$BlurRadius = 25,

    [Parameter()]
    [TimeSpan]$Duration = [TimeSpan]::FromMinutes(20),

    [Parameter()]
    [ValidateRange(0, 100)]
    [int]$Opacity = 20,

    [Parameter()]
    [ValidateSet('black', 'blue', 'brown', 'cyan', 'green', 'gray', 'magenta', 'orange', 'purple', 'red', 'white', 'yellow')]
    [string]$FontColor = '#00FF00',

    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$ImagePath,

    [Parameter(DontShow)]
    [ValidateRange(0, 100)]
    [int]$ImageOpacity = 40,

    [Parameter(ValueFromPipeline)]
    [string]$MessageContent
  )

  begin {
    $ErrorActionPreference = 'Stop'

    # Load required assemblies
    $assemblies = @(
      'PresentationCore',
      'PresentationFramework',
      'System.Drawing',
      'System.Runtime.InteropServices',
      'System.Windows.Forms'
    )
    foreach ($assembly in $assemblies) {
      Add-Type -AssemblyName $assembly
    }

    # Load required .NET types
    if (-not [System.Management.Automation.PSTypeName]'UserInput'.Type) {
      $code = @'
        using System;
        using System.Runtime.InteropServices;
        public class UserInput {
            [DllImport("user32.dll")] public static extern int ShowCursor(bool bShow);
            [DllImport("user32.dll")] public static extern bool BlockInput(bool fBlockIt);
        }
'@
      Add-Type -TypeDefinition $code -Language CSharp
    }

    function Test-AdminPrivileges {
      ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function ConvertTo-DecimalPercentage {
      param ([int]$Value)
      if ($Value -le 10) { return $Value / 10 } else { return $Value / 100 }
    }

    if (-not (Test-AdminPrivileges)) {
      Write-Warning 'Running without administrator privileges. Keyboard blocking will be disabled.'
    }
  }

  process {
    $opacityDecimal = ConvertTo-DecimalPercentage -Value $Opacity
    $screens = [System.Windows.Forms.Screen]::AllScreens
    $windows = @()

    $customImage = $null
    if ($ImagePath) {
      try {
        $customImage = New-Object System.Windows.Media.Imaging.BitmapImage
        $customImage.BeginInit()
        $customImage.UriSource = New-Object System.Uri($ImagePath, [System.UriKind]::Absolute)
        $customImage.EndInit()
        $customImage.Freeze()
      } catch {
        Write-Warning "Failed to load custom image: $_"
        $customImage = $null
      }
    }

    $audioPlayer = $null
    if ($AudioPath) {
      try {
        $audioPlayer = New-Object -ComObject WMPlayer.OCX
        $audioPlayer.URL = $AudioPath
        $audioPlayer.settings.setMode('loop', $true)
        $audioPlayer.settings.volume = $AudioVolume
      } catch {
        Write-Warning "Failed to initialize audio player: $_"
        $audioPlayer = $null
      }
    }

    foreach ($screen in $screens) {
      $window = New-Object Windows.Window
      $window.WindowStyle = 'None'
      $window.AllowsTransparency = $true
      $window.Background = [System.Windows.Media.Brushes]::Transparent
      $window.Left = $screen.Bounds.Left
      $window.Top = $screen.Bounds.Top
      $window.Width = $screen.Bounds.Width
      $window.Height = $screen.Bounds.Height
      $window.Topmost = $true

      $grid = New-Object System.Windows.Controls.Grid

      $bitmap = New-Object System.Drawing.Bitmap $screen.Bounds.Width, $screen.Bounds.Height
      try {
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($screen.Bounds.Location, [System.Drawing.Point]::Empty, $screen.Bounds.Size)

        $memoryStream = New-Object System.IO.MemoryStream
        $bitmap.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)

        $bitmapImage = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmapImage.BeginInit()
        $bitmapImage.StreamSource = $memoryStream
        $bitmapImage.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmapImage.EndInit()

        $imageBrush = New-Object System.Windows.Media.ImageBrush
        $imageBrush.ImageSource = $bitmapImage

        $background = New-Object System.Windows.Shapes.Rectangle
        $background.Fill = $imageBrush
        $background.Width = $screen.Bounds.Width
        $background.Height = $screen.Bounds.Height

        $blurEffect = New-Object System.Windows.Media.Effects.BlurEffect
        $blurEffect.Radius = $BlurRadius
        $background.Effect = $blurEffect

        $darkOverlay = New-Object System.Windows.Shapes.Rectangle
        $darkOverlay.Fill = [System.Windows.Media.Brushes]::Black
        $darkOverlay.Opacity = $opacityDecimal
        $darkOverlay.Width = $screen.Bounds.Width
        $darkOverlay.Height = $screen.Bounds.Height

        [void]$grid.Children.Add($background)
        [void]$grid.Children.Add($darkOverlay)

        if ($customImage) {
          $imageOverlay = New-Object System.Windows.Controls.Image
          $imageOverlay.Source = $customImage
          # $imageOverlay.Stretch = [System.Windows.Media.Stretch]::Uniform
          $imageOverlay.Stretch = [System.Windows.Media.Stretch]::Fill
          $imageOverlay.HorizontalAlignment = 'Center'
          $imageOverlay.VerticalAlignment = 'Center'
          $imageOverlay.Opacity = (ConvertTo-DecimalPercentage -Value $ImageOpacity)
          [void]$grid.Children.Add($imageOverlay)
        }

        if ($screen.Primary) {
          $stackPanel = New-Object System.Windows.Controls.StackPanel
          $stackPanel.Orientation = 'Vertical'

          # Create TextBlock for MessageContent
          $messageTextBlock = New-Object Windows.Controls.TextBlock
          $messageTextBlock.FontFamily = 'Consolas'
          $messageTextBlock.FontSize = 24
          $messageTextBlock.FontWeight = 'Bold'
          $messageTextBlock.Background = 'Transparent'
          $messageTextBlock.Foreground = $FontColor
          $messageTextBlock.VerticalAlignment = 'Top'
          $messageTextBlock.HorizontalAlignment = 'Center'
          $messageTextBlock.TextWrapping = 'Wrap'
          $messageTextBlock.Text = $MessageContent

          # Create TextBlock for Time Remaining
          $timeTextBlock = New-Object Windows.Controls.TextBlock
          $timeTextBlock.FontFamily = 'Consolas'
          $timeTextBlock.FontSize = 10
          $timeTextBlock.FontWeight = 'Bold'
          $timeTextBlock.Background = 'Transparent'
          $timeTextBlock.Foreground = $FontColor
          $timeTextBlock.VerticalAlignment = 'Bottom'
          $timeTextBlock.HorizontalAlignment = 'Center'
          $timeTextBlock.TextWrapping = 'Wrap'

          # Add TextBlocks to StackPanel
          [void]$stackPanel.Children.Add($messageTextBlock)
          [void]$stackPanel.Children.Add((New-Object Windows.Controls.TextBlock)) # Blank line
          [void]$stackPanel.Children.Add((New-Object Windows.Controls.TextBlock)) # Blank line
          [void]$stackPanel.Children.Add($timeTextBlock)

          # Define the animation
          $animation = New-Object Windows.Media.Animation.DoubleAnimation
          $animation.From = 0.6 # Start from 60% opacity
          $animation.To = 1.0 # Go to 100% opacity
          $animation.Duration = New-Object Windows.Duration([System.TimeSpan]::FromSeconds(8))
          $animation.AutoReverse = $false
          $animation.EasingFunction = New-Object Windows.Media.Animation.ExponentialEase
          $animation.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever

          # Apply the animation to the Opacity property of the textBlock
          $storyboard = New-Object Windows.Media.Animation.Storyboard
          [Windows.Media.Animation.Storyboard]::SetTarget($animation, $messageTextBlock)
          [Windows.Media.Animation.Storyboard]::SetTargetProperty($animation, '(UIElement.Opacity)')
          $storyboard.Children.Add($animation)
          $storyboard.Begin()

          $contentBorder = New-Object System.Windows.Controls.Border
          $contentBorder.Background = [System.Windows.Media.Brushes]::Transparent
          $contentBorder.Width = $screen.Bounds.Width * 0.5
          $contentBorder.Height = $screen.Bounds.Height * 0.2
          $contentBorder.HorizontalAlignment = 'Stretch'
          $contentBorder.VerticalAlignment = 'Stretch'

          $contentBorder.Child = $stackPanel
          [void]$grid.Children.Add($contentBorder)

          # Set the FontSize after the window is loaded
          $window.add_Loaded({
              $messageTextBlock.FontSize = $window.ActualWidth * 0.02
              $timeTextBlock.FontSize = $window.ActualWidth * 0.03
            })
        }

        $window.Content = $grid
        $windows += $window
      } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
      }
    }

    [void][UserInput]::BlockInput($true)
    [void][UserInput]::ShowCursor($false)

    $finishTime = (Get-Date).Add($Duration)

    if ($audioPlayer) {
      $audioPlayer.controls.play()
    }

    try {
      [void]$windows[0].Dispatcher.Invoke({
          foreach ($window in $windows) {
            $window.Show()
          }
          for ($i = $Duration.TotalSeconds; $i -gt 0; $i--) {
            $elapsedTime = New-TimeSpan -Start (Get-Date) -End $finishTime
            $window.Dispatcher.Invoke({
                $timeTextBlock.Text = "Time Remaining: $($elapsedTime.ToString('hh\:mm\:ss'))"
              }, [System.Windows.Threading.DispatcherPriority]::Background)
            Start-Sleep -Seconds 1
          }
        })
    } finally {
      foreach ($window in $windows) {
        $window.Close()
      }

      if ($audioPlayer) {
        $audioPlayer.controls.stop()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($audioPlayer) | Out-Null
        Remove-Variable audioPlayer
      }

      [void][UserInput]::ShowCursor($true)
      [void][UserInput]::BlockInput($false)
    }
  }

  end {}
}