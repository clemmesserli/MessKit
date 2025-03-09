function Show-MKPixel {
  <#
  .SYNOPSIS
  Extracts hidden messages from image files using steganography techniques.

  .DESCRIPTION
  This function extracts a hidden message from an image file by analyzing pixels and extracting bits from
  specified color channels. It works by:
  - Reading each pixel in the image sequentially
  - Extracting the least significant bits from the specified color channels
  - Collecting these bits until finding the terminator pattern (11111111)
  - Converting the binary data back to text using UTF-8 encoding

  The process must match the embedding process used to hide the data initially.

  .PARAMETER StegoFile
  The path to the image file containing the hidden message. Must be a readable image format.
  Alias: sf

  .PARAMETER ColorChannel
  The color channel(s) to extract bits from (R, G, B, RG, RB, GB, RGB).
  This must match the channels used during embedding.
  Default: R (Red channel only)
  Alias: cc

  .PARAMETER BitsPerChannel
  The number of bits to extract per color channel (1 to 8).
  Higher values extract more data per pixel but may be more noticeable visually.
  This must match the setting used during embedding.
  Default: 1 bit per channel
  Alias: bpc

  .EXAMPLE
  Show-MKPixel -StegoFile "C:\Images\stego.png"

  Extracts a hidden message from "stego.png" using only the Red channel and 1 bit per pixel.

  .EXAMPLE
  Show-MKPixel -StegoFile "C:\Images\stego.png" -cc RB -bpc 4

  Extracts a hidden message using both Red and Blue channels with 4 bits per channel,
  which allows for more data to be extracted but requires the same settings used during embedding.

  .EXAMPLE
  $SecretRecipe = Show-MKPixel -sf "$env:temp\stego.png" -cc RGB -bpc 1
  $SecretRecipe | UnProtect-MySecret -Passphrase (ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force)

  Extracts encrypted data from an image and pipes it to UnProtect-MySecret for decryption using a passphrase.

  .EXAMPLE
  Show-MKPixel -sf "$home\Documents\stego.png" -cc RGB -bpc 2 | Out-File "$home\Documents\stego.enc"
  $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
  UnProtect-MyFile -Certificate $cert -FilePath "$home\Documents\stego.enc" -Base64 -EncryptionMethod RSA

  Extracts hidden data from an image, saves it to a file, and decrypts it using RSA certificate-based encryption.

  .EXAMPLE
  Show-MKPixel -sf "$home\Documents\payload.png" -cc RGB -bpc 2 | Out-File "$home\Documents\payload.enc"
  $cert = Get-Item Cert:\CurrentUser\My\833ED9148FD08F577D2AD743BAF71295AFEF345C
  Get-Content (UnProtect-MyFile -Certificate $cert -FilePath "$home\Documents\payload.enc" -Base64 -EncryptionMethod RSA -FileExtension ps1)

  Extracts, decrypts and executes a hidden PowerShell script from an image file.

  .NOTES
  Requires System.Drawing assembly to be available.
  For successful extraction, you must use the same ColorChannel and BitsPerChannel values that were used during embedding.
  The extraction stops when the terminator pattern "11111111" is found.

  .LINK
  Hide-MKPixel
  UnProtect-MySecret
  UnProtect-MyFile
  #>
  param(
    [Parameter(Mandatory = $true)]
    [Alias('sf')]
    [System.IO.FileInfo]$StegoFile,

    [Parameter()]
    [ValidateSet('R', 'G', 'B', 'RG', 'RB', 'GB', 'RGB')]
    [Alias('cc')]
    [string]$ColorChannel = 'R',

    [Parameter()]
    [ValidateRange(1, 8)]
    [Alias('bpc')]
    [int]$BitsPerChannel = 1
  )

  # Load the hidden image
  try {
    $image = [System.Drawing.Image]::FromFile($StegoFile)
  } catch {
    Write-Error $_.Exception.Message
    return
  }

  $x = 0
  $y = 0

  # Initialize an empty string to hold the bits
  $binaryMessage = ''

  # Create a mask based on BitsPerChannel
  $mask = [byte]((1 -shl $BitsPerChannel) - 1)

  # Iterate over each pixel
  :outer for ($y = 0; $y -lt $image.Height; $y++) {
    for ($x = 0; $x -lt $image.Width; $x++) {
      # Get the pixel at the current coordinates
      $pixel = $image.GetPixel($x, $y)

      # Extract bits from each specified color channel
      foreach ($channel in $ColorChannel.ToCharArray()) {
        $bits = switch ($channel) {
          'R' { $pixel.R -band $mask }
          'G' { $pixel.G -band $mask }
          'B' { $pixel.B -band $mask }
        }

        # Add the bits to our binary message
        $binaryMessage += [Convert]::ToString($bits, 2).PadLeft($BitsPerChannel, '0')

        # Check for terminator every 8 bits
        if ($binaryMessage.Length % 8 -eq 0 -and $binaryMessage.EndsWith('11111111')) {
          $binaryMessage = $binaryMessage.Substring(0, $binaryMessage.Length - 8)
          break outer
        }
      }
    }
  }

  # Convert binary to text
  $byteArray = New-Object byte[] ($binaryMessage.Length / 8)
  for ($i = 0; $i -lt $binaryMessage.Length; $i += 8) {
    $byteArray[$i / 8] = [Convert]::ToByte($binaryMessage.Substring($i, 8), 2)
  }
  $message = [System.Text.Encoding]::UTF8.GetString($byteArray)

  # Dispose of the image to free up resources
  $image.Dispose()

  return $message
}