function Hide-MKPixel {
  <#
  .SYNOPSIS
  Function to hide a message in an image by manipulating pixel color channels.

  .DESCRIPTION
  This function takes a cover image, a message, and parameters to hide the message in the image by modifying one or more Least Significant Bits (LSB) within the cover image.

  .PARAMETER CoverFile
  Path to the original image file.

  .PARAMETER StegoFile
  Path to save the image with the hidden message.

  .PARAMETER Message
  The message to hide in the image.

  .PARAMETER ColorChannel
  Specifies which color channels to modify (R, G, B, RG, RB, GB, RGB).

  .PARAMETER BitsPerChannel
  Number of bits to use per color channel for hiding the message.

  .EXAMPLE
  Hide-MKPixel -m "SecretMessage" -cf "C:\Images\cover.png" -sf "C:\Images\stego.png"

  .EXAMPLE
  Hide-MKPixel -m (Get-Content "C:\Images\MyCopyright.txt" -raw) -cf "C:\Images\cover.png" -sf "C:\Images\stego.png" -cc RB -bpc 4

  .EXAMPLE
  $SecretRecipe = (Get-Content "$env:temp\SecretRecipe.txt" -raw) | Protect-MySecret -Passphrase (ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force) -DisplaySecret
  Hide-MKPixel -m $SecretRecipe -cf "C:\Images\cover.png" -sf "$env:temp\stego.png" -cc RGB -bpc 1

  .EXAMPLE
  $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
  Protect-MyFile -Certificate $cert -FilePath "$home\Documents\SecretFile.txt" -EncryptionMethod RSA -RSAKeySize 1024 -Base64 -DeleteOriginal
  Hide-MKPixel -m (Get-Content "$home\Documents\SecretFile.enc" -raw) -cf "C:\Images\cover.png" -sf "$home\Documents\stego.png" -cc RGB -bpc 2

  .EXAMPLE
  $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
  Protect-MyFile -Certificate $cert -FilePath "$home\Documents\payload.ps1" -EncryptionMethod RSA -RSAKeySize 1024 -Base64 -DeleteOriginal
  Hide-MKPixel -m (Get-Content "$home\Documents\payload.enc" -raw) -cf "C:\Images\cover.png" -sf "$home\Documents\payload.png" -cc RGB -bpc 2
  #>
  param(
    [Parameter(Mandatory = $true)]
    [Alias("cf")]
    [string]$CoverFile,

    [Parameter(Mandatory = $true)]
    [Alias("sf")]
    [string]$StegoFile,

    [Parameter(Mandatory = $true)]
    [Alias("m")]
    [string]$Message,

    [Parameter()]
    [ValidateSet("R", "G", "B", "RG", "RB", "GB", "RGB")]
    [Alias("cc")]
    [string]$ColorChannel = "R",

    [Parameter()]
    [ValidateRange(1, 8)]
    [Alias("bpc")]
    [int]$BitsPerChannel = 1
  )

  # Load the original image
  $bitmap = [System.Drawing.Bitmap]::FromFile($CoverFile)

  $binaryMessage = -join ($Message.ToCharArray() | ForEach-Object {
      [Convert]::ToString([byte]$_, 2).PadLeft(8, '0')
    })

  # Add terminator
  $binaryMessage += "11111111"

  $bitIndex = 0
  $mask = [byte]((1 -shl $BitsPerChannel) - 1)
  $colorChannels = $ColorChannel.ToCharArray()

  for ($y = 0; $y -lt $bitmap.Height; $y++) {
    for ($x = 0; $x -lt $bitmap.Width; $x++) {
      if ($bitIndex -ge $binaryMessage.Length) { break }

      # Get the pixel at the current coordinates
      $pixel = $bitmap.GetPixel($x, $y)
      $newR = $pixel.R
      $newG = $pixel.G
      $newB = $pixel.B

      foreach ($channel in $colorChannels) {
        if ($bitIndex -ge $binaryMessage.Length) { break }

        $bits = [Convert]::ToInt32($binaryMessage.Substring($bitIndex, [Math]::Min($BitsPerChannel, $binaryMessage.Length - $bitIndex)), 2)

        switch ($channel) {
          "R" { $newR = ($newR -band (-bnot $mask)) -bor $bits }
          "G" { $newG = ($newG -band (-bnot $mask)) -bor $bits }
          "B" { $newB = ($newB -band (-bnot $mask)) -bor $bits }
        }

        $bitIndex += $BitsPerChannel
      }

      # Create the new pixel
      $newPixel = [System.Drawing.Color]::FromArgb($pixel.A, $newR, $newG, $newB)
      $bitmap.SetPixel($x, $y, $newPixel)
    }
  }

  if ($bitIndex -lt $binaryMessage.Length) {
    Write-Warning "Message too long for image capacity"
  }

  # Save the image with the hidden message
  $bitmap.Save($StegoFile, [System.Drawing.Imaging.ImageFormat]::Png)

  # Dispose of the image to free up resources
  $bitmap.Dispose()
}