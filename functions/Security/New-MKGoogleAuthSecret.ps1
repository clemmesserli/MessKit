Function New-MKGoogleAuthSecret {
  <#
    .SYNOPSIS
        Generate an 80-bit key, BASE32 encoded, secret for TOTP authentication
        and a URL to Google Charts which will show it as a QR code.

    .DESCRIPTION
        Creates a Time-based One-Time Password (TOTP) secret that can be used with
        Google Authenticator or other compatible authentication apps. The function
        generates a cryptographically secure random secret, encodes it in BASE32,
        and provides a QR code URL that can be scanned by authentication apps.

        The function can also use an existing secret code and update its associated
        metadata like name and issuer.

    .EXAMPLE
        PS C:\> New-MKGoogleAuthSecret

        Secret           QrCodeUri
        ------           ---------
        5WYYADYB5DK2BIOV http://chart.apis.google[..]

        # Generates a new secret with default parameters and returns the secret and QR code URL.

    .EXAMPLE
        PS C:\> New-MKGoogleAuthSecret -UseThisSecretCode "HP44SIFI2GFDZHT6" -Online

        # Uses an existing secret code and opens a web browser showing the QR code.
        # The function will update pre-existing entry in Google Authenticator if found.

    .EXAMPLE
        $param = @{
            Name = "charlie.brown@peanuts.com"
            Issuer = "WorkToken"
            Online = $true
        }
        New-MKGoogleAuthSecret @param | Format-List *

        # Generates a new secret with custom name and issuer, opens the QR code in a browser,
        # and displays all properties of the returned object.

    .OUTPUTS
        Returns a custom object with the following properties:
        - Secret: The BASE32 encoded secret key
        - KeyUri: The otpauth:// URI containing all parameters
        - QrCodeUri: URL to a Google Charts QR code image for the secret

    .NOTES
        The default secret length is 15 bytes (120 bits), which provides strong security
        for TOTP authentication. The secret is encoded in BASE32 as required by the
        Google Authenticator specification.
    #>
  [CmdletBinding()]
  Param (
    # Secret length in bytes, must be a multiple of 5 bits for neat BASE32 encoding
    [ValidateScript( { ($_ * 8) % 5 -eq 0 })]
    [Int]$SecretLength = 15,

    # Use an existing secret code, don't generate a new one, just update it with new text
    [String]$UseThisSecretCode,

    # Launches a web browser to show a QR Code
    [Switch]$Online = $false,

    # Name is text that will appear within ()
    [String]$Name = 'charlie.brown@peanuts.com',

    # Issuer is text that will appear left of the () in Google Authenticator app
    [String]$Issuer = 'WorkToken'
  )

  Begin {
    $Script:Base32Charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
  }

  Process {
    # If there's a secret provided then use it, otherwise we need to generate one
    if ($PSBoundParameters.ContainsKey('UseThisSecretCode')) {
      $Base32Secret = $UseThisSecretCode
    } else {
      # Generate random bytes for the secret
      $byteArrayForSecret = [byte[]]::new($SecretLength)
      [Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($byteArrayForSecret, 0, $SecretLength)

      # BASE32 encode the bytes
      # 5 bits per character doesn't align with 8-bits per byte input,
      # and needs careful code to take some bits from separate bytes.
      # Because we're in a scripting language let's dodge that work.
      # Instead, convert the bytes to a 10100011 style string:
      $byteArrayAsBinaryString = -join $byteArrayForSecret.ForEach{
        [Convert]::ToString($_, 2).PadLeft(8, '0')
      }

      # then use regex to get groups of 5 bits
      # -> convert those to integer
      # -> lookup that as an index into the BASE32 character set
      # -> result string
      $Base32Secret = [regex]::Replace($byteArrayAsBinaryString, '.{5}', {
          param($Match)
          $Script:Base32Charset[[Convert]::ToInt32($Match.Value, 2)]
        })
    }

    # Generate the URI which needs to go to the Google Authenticator App.
    # URI escape each component so the name and issuer can have punctiation characters.
    $otpUri = 'otpauth://totp/{0}?secret={1}&issuer={2}' -f @(
      [Uri]::EscapeDataString($Name),
      $Base32Secret
      [Uri]::EscapeDataString($Issuer)
    )

    # Double-encode because we're going to embed this into a Google Charts URI,
    # and these need to still be encoded in the QR code after Charts webserver has decoded once.
    $encodedUri = [Uri]::EscapeDataString($otpUri)

    # Tidy output, with a link to Google Chart API to make a QR code
    $keyDetails = [PSCustomObject]@{
      Secret    = $Base32Secret
      KeyUri    = $otpUri
      QrCodeUri = "https://chart.apis.google.com/chart?cht=qr&chs=200x200&chl=${encodedUri}"
    }

    # Online switch launches a system WebBrowser.
    if ($Online) {
      Start-Process $keyDetails.QrCodeUri
    }

    $keyDetails
  }

  End {}
}