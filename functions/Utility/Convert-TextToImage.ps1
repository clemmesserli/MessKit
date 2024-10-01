Function Convert-TextToImage {
	<#
	.SYNOPSIS
		take any text and font, and renders it into a PNG file
	.EXAMPLE
		$file = Convert-TextToImage -Text 'Red Alert!' -Font Stencil -FontSize 60 -Foreground Red -Background Gray
		Invoke-Item -Path $file
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[String]$Text,

		[String]$Font = 'Consolas',

		[ValidateRange(5, 400)]
		[Int]$FontSize = 24,

		[System.Windows.Media.Brush]$Foreground = [System.Windows.Media.Brushes]::Black,

		[System.Windows.Media.Brush]$Background = [System.Windows.Media.Brushes]::White
	)

	Begin {}

	Process {
		$filename = "$env:temp\$(Get-Random).png"

		# Take a simple XAML template with some text
		$xaml = @"
<TextBlock
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">$Text</TextBlock>
"@

		Add-Type -AssemblyName PresentationFramework

		# Turn it into a UIElement
		$reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
		$result = [Windows.Markup.XAMLReader]::Load($reader)

		# Refine its properties
		$result.FontFamily = $Font
		$result.FontSize = $FontSize
		$result.Foreground = $Foreground
		$result.Background = $Background

		# Render it in memory to the desired size
		$result.Measure([System.Windows.Size]::new([Double]::PositiveInfinity, [Double]::PositiveInfinity))
		$result.Arrange([System.Windows.Rect]::new($result.DesiredSize))
		$result.UpdateLayout()

		# Write it to a bitmap and save it as PNG
		$render = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($result.ActualWidth, $result.ActualHeight, 96, 96, [System.Windows.Media.PixelFormats]::Default)
		$render.Render($result)
		Start-Sleep -Seconds 1
		$encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
		$encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($render))
		$filestream = [System.IO.FileStream]::new($filename, [System.IO.FileMode]::Create)
		$encoder.Save($filestream)

		# Clean up
		$reader.Close()
		$reader.Dispose()

		$filestream.Close()
		$filestream.Dispose()

		# Return the file name for the generated image
		$filename
	}

	End {}
}