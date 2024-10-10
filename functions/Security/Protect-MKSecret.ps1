function Protect-MKSecret {
  <#
  .SYNOPSIS
  Encrypts a secret using a key input in the form of a SecureString and saves it to a file.

  .DESCRIPTION
  This function takes plain text content and a Key in the form of a SecureString which is then used to encrypt the content.
  The output can then be saved to a file or displayed on screen.

  .PARAMETER Secret
  The secret text to encrypt.

  .PARAMETER Key
  The key value used for encryption, as a SecureString.

  .PARAMETER OutputPath
  The path where the encrypted secret will be saved. Defaults to a file named 'secret.txt' in the temp directory.

  .EXAMPLE
  $PassPhrase = Read-Host "Enter passphrase" -AsSecureString
  "Another secret" | Protect-MKSecret -Passphrase $PassPhrase -FilePath "$env:tmp\encrypted.txt"
  Get-Content "$env:tmp\encrypted.txt"

  .EXAMPLE
  $PassPhrase = ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force
  Protect-MKSecret -Secret "My super secret" -Passphrase $PassPhrase -DisplaySecret

  .EXAMPLE
  $PassPhrase = ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force
  $content = @"
  Bush Baked Beans Secret Family Recipe
  Ingredients:
  * 2 (16 ounce) cans baked beans with pork
  * ¼ cup molasses
  * ¼ cup chopped onions
  * 4 tablespoons brown sugar
  Instructions:
  1. Preheat oven to 350 degrees
  2. Pray as you are still missing ingredients :)
"@
  $content | Protect-MKSecret -Passphrase $PassPhrase -FilePath "$env:TEMP\secret.txt"
  $content | Protect-MKSecret -Passphrase $PassPhrase -DisplaySecret

  .NOTES
  The secret is encrypted using AES encryption with a 256-bit key derived from the passphrase.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]$Secret,

    [Parameter(Mandatory)]
    [SecureString]$Passphrase,

    [Parameter()]
    [string]$FilePath,

    [Parameter()]
    [switch]$DisplaySecret
  )

  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Passphrase)
  $unsecurePassphrase = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

  $key = [System.Text.Encoding]::UTF8.GetBytes($unsecurePassphrase.PadRight(32).Substring(0, 32))

  $encryptedSecret = $Secret | ConvertTo-SecureString -AsPlainText -Force |
    ConvertFrom-SecureString -Key $key

  if ($DisplaySecret) {
    return $encryptedSecret
  } elseif ($FilePath) {
    Set-Content -Path $FilePath -Value $encryptedSecret -NoNewline
    Write-Host "Secret encrypted and saved to: $FilePath"
  } else {
    Write-Host "Use -DisplaySecret to display on screen or -FilePath to save to a file."
  }
}
