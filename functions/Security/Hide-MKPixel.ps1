function Hide-MKPixel {
  <#
  .SYNOPSIS
  Hides a message in an image using steganography by manipulating pixel color channels.

  .DESCRIPTION
  Hide-MKPixel implements steganography techniques to conceal messages within image files.
  It works by modifying the Least Significant Bits (LSB) of selected color channels in each pixel.
  The function can use varying numbers of bits per channel, allowing for different capacity/visibility tradeoffs.

  The message is converted to binary and distributed across the image pixels according to the specified
  color channels. A termination sequence is added to mark the end of the hidden message.

  For best results, use PNG files as they use lossless compression. JPEG files will likely corrupt
  the hidden data due to lossy compression.

  .PARAMETER CoverFile
  Path to the original image file that will be used to hide the message.
  This file remains unchanged during the process.

  .PARAMETER StegoFile
  Path where the new image containing the hidden message will be saved.
  Always saved as PNG format to preserve the hidden data.

  .PARAMETER Message
  The text message or binary data to hide within the image.
  Can be plain text or encrypted content from other functions.

  .PARAMETER ColorChannel
  Specifies which color channels to modify (R, G, B, RG, RB, GB, RGB).
  Default is "R" (Red channel only).
  Using multiple channels increases capacity but may affect image quality.

  .PARAMETER BitsPerChannel
  Number of least significant bits to use per color channel for hiding the message.
  Range: 1-8. Default is 1.
  Higher values increase capacity but make changes more detectable visually.

  .EXAMPLE
  Hide-MKPixel -m "SecretMessage" -cf "C:\Images\cover.png" -sf "C:\Images\stego.png"

  Hides the text "SecretMessage" in the image using default settings (Red channel only, 1 bit per channel).

  .EXAMPLE
  Hide-MKPixel -m (Get-Content "C:\Images\MyCopyright.txt" -raw) -cf "C:\Images\cover.png" -sf "C:\Images\stego.png" -cc RB -bpc 4

  Loads text from a file and hides it in the image using both Red and Blue channels with 4 bits per channel.
  This provides higher capacity but may cause more visible changes to the image.

  .EXAMPLE
  $SecretRecipe = (Get-Content "$env:temp\SecretRecipe.txt" -raw) | Protect-MySecret -Passphrase (ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force) -DisplaySecret
  Hide-MKPixel -m $SecretRecipe -cf "C:\Images\cover.png" -sf "$env:temp\stego.png" -cc RGB -bpc 1

  Demonstrates encrypting a message before hiding it in an image for additional security.
  Uses all three color channels with 1 bit per channel.

  .EXAMPLE
  $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
  Protect-MyFile -Certificate $cert -FilePath "$home\Documents\SecretFile.txt" -EncryptionMethod RSA -RSAKeySize 1024 -Base64 -DeleteOriginal
  Hide-MKPixel -m (Get-Content "$home\Documents\SecretFile.enc" -raw) -cf "C:\Images\cover.png" -sf "$home\Documents\stego.png" -cc RGB -bpc 2

  Demonstrates certificate-based encryption of a file before hiding the encrypted content in an image.
  Uses all RGB channels with 2 bits per channel for higher capacity.

  .EXAMPLE
  $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
  Protect-MyFile -Certificate $cert -FilePath "$home\Documents\payload.ps1" -EncryptionMethod RSA -RSAKeySize 1024 -Base64 -DeleteOriginal
  Hide-MKPixel -m (Get-Content "$home\Documents\payload.enc" -raw) -cf "C:\Images\cover.png" -sf "$home\Documents\payload.png" -cc RGB -bpc 2

  Hides an encrypted PowerShell script within an image using certificate-based encryption.
  The script can later be extracted and decrypted using the corresponding private key.

  .NOTES
  - Always use PNG format for steganography as JPEG compression will corrupt the hidden data
  - Larger BitsPerChannel values increase capacity but reduce visual quality
  - The maximum message size depends on image dimensions, color channels used, and bits per channel
  - For maximum security, encrypt sensitive messages before hiding them
  #>
  param(
    [Parameter(Mandatory = $true)]
    [Alias('cf')]
    [string]$CoverFile,

    [Parameter(Mandatory = $true)]
    [Alias('sf')]
    [string]$StegoFile,

    [Parameter(Mandatory = $true)]
    [Alias('m')]
    [string]$Message,

    [Parameter()]
    [ValidateSet('R', 'G', 'B', 'RG', 'RB', 'GB', 'RGB')]
    [Alias('cc')]
    [string]$ColorChannel = 'R',

    [Parameter()]
    [ValidateRange(1, 8)]
    [Alias('bpc')]
    [int]$BitsPerChannel = 1
  )

  # Load the original image
  $bitmap = [System.Drawing.Bitmap]::FromFile($CoverFile)

  $binaryMessage = -join ($Message.ToCharArray() | ForEach-Object {
      [Convert]::ToString([byte]$_, 2).PadLeft(8, '0')
    })

  # Add terminator
  $binaryMessage += '11111111'

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
          'R' { $newR = ($newR -band (-bnot $mask)) -bor $bits }
          'G' { $newG = ($newG -band (-bnot $mask)) -bor $bits }
          'B' { $newB = ($newB -band (-bnot $mask)) -bor $bits }
        }

        $bitIndex += $BitsPerChannel
      }

      # Create the new pixel
      $newPixel = [System.Drawing.Color]::FromArgb($pixel.A, $newR, $newG, $newB)
      $bitmap.SetPixel($x, $y, $newPixel)
    }
  }

  if ($bitIndex -lt $binaryMessage.Length) {
    Write-Warning 'Message too long for image capacity'
  }

  # Save the image with the hidden message
  $bitmap.Save($StegoFile, [System.Drawing.Imaging.ImageFormat]::Png)

  # Dispose of the image to free up resources
  $bitmap.Dispose()
}