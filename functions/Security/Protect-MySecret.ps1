function Protect-MySecret {
  <#
  .SYNOPSIS
  Encrypts a secret using a passphrase and saves it to a file.

  .DESCRIPTION
  This function takes a secret string and a secure passphrase, encrypts the secret,
  and saves the encrypted content to a file.

  .PARAMETER Secret
  The secret text to encrypt.

  .PARAMETER Passphrase
  The passphrase used for encryption, as a SecureString.

  .PARAMETER OutputPath
  The path where the encrypted secret will be saved. Defaults to a file named 'secret.txt' in the temp directory.

  .EXAMPLE
  $securePass = ConvertTo-SecureString "My secure passphrase" -AsPlainText -Force
  Protect-MySecret -Secret "My super secret" -Passphrase $securePass

  .EXAMPLE
  $securePass = Read-Host "Enter passphrase" -AsSecureString
  "Another secret" | Protect-MySecret -Passphrase $securePass -OutputPath "C:\Secrets\encrypted.txt"

  .EXAMPLE
  $securePass = ConvertTo-SecureString "Good Boy, Duke!" -AsPlainText -Force
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
  $content | Protect-MySecret -Passphrase $securePass -OutputPath "$env:TEMP\secret.txt"

  .NOTES
  The secret is encrypted using AES encryption with a 256-bit key derived from the passphrase.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$Secret,

    [Parameter(Mandatory = $true)]
    [SecureString]$Passphrase,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "$env:TEMP\secret.txt"
  )

  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Passphrase)
  $unsecurePassphrase = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

  $key = [System.Text.Encoding]::UTF8.GetBytes($unsecurePassphrase.PadRight(32).Substring(0, 32))

  $encryptedSecret = $Secret | ConvertTo-SecureString -AsPlainText -Force |
    ConvertFrom-SecureString -Key $key

  Set-Content -Path $OutputPath -Value $encryptedSecret -NoNewline
  Write-Host "Secret encrypted and saved to: $OutputPath"
}
