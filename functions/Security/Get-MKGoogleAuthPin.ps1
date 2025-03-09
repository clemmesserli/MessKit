Function Get-MKGoogleAuthPin {
  <#
    .SYNOPSIS
        Generates a Time-based One-Time Password (TOTP) PIN code from a Google Authenticator secret.

    .DESCRIPTION
        This function calculates the current valid TOTP PIN code from a BASE32 encoded secret key
        (the same type of secret used by Google Authenticator and similar apps). The function
        implements the TOTP algorithm as specified in RFC 6238, using HMAC-SHA1 as the
        underlying algorithm.

        The function returns both the current PIN code (formatted with a space for readability)
        and the number of seconds remaining before the code expires.

    .EXAMPLE
        PS C:\> Get-MKGoogleAuthPin -Secret T5UOE4YLIFYTZQA2

        PinCode          SecondsRemaining
        -------          ---------------
        372 251          14

        # Generates the current PIN code using the default 30-second time window.

    .EXAMPLE
        PS C:\> $secret = (New-MKGoogleAuthSecret).Secret
        PS C:\> Get-MKGoogleAuthPin -Secret $secret

        # Creates a new secret and then generates a PIN code for it.

    .EXAMPLE
        PS C:\> Get-MKGoogleAuthPin -Secret T5UOE4YLIFYTZQA2 -TimeWindow 60

        # Generates a PIN using a 60-second time window (some services use longer windows).

    .PARAMETER Secret
        The BASE32 encoded secret key, typically provided when setting up two-factor authentication.
        Example: 'T5UOE4YLIFYTZQA2'.

    .PARAMETER TimeWindow
        The time window in seconds for which each PIN is valid. The default is 30 seconds,
        which is the standard for most TOTP implementations including Google Authenticator.

    .OUTPUTS
        Returns a PSObject with the following properties:
        - PinCode: The 6-digit PIN code with a space inserted for readability
        - SecondsRemaining: Number of seconds until the current PIN expires

    .NOTES
        This implementation follows the TOTP standard (RFC 6238) and is compatible with
        Google Authenticator and other TOTP apps. The function only supports SHA1 as the
        hash algorithm, which is the default for most TOTP implementations.

        Reference: https://datatracker.ietf.org/doc/html/rfc6238
    #>
  [CmdletBinding()]
  Param (
    # BASE32 encoded Secret e.g. T5UOE4YLIFYTZQA2
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [String]$Secret,

    # OTP time window in seconds
    [Int]$TimeWindow = 30
  )

  Begin {}

  Process {
    [Byte[]]$secretAsBytes = ConvertFrom-Base32 "$secret" -OutBytes -Raw

    $epochTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

    # Convert the time to a big-endian byte array
    $timeBytes = [BitConverter]::GetBytes([Int64][Math]::Floor($epochTime / $TimeWindow))
    if ([BitConverter]::IsLittleEndian) {
      [Array]::Reverse($timeBytes)
    }

    # Do the HMAC calculation with the default SHA1
    # Google Authenticator app does support other hash algorithms, this code doesn't
    $hmacGen = [Security.Cryptography.HMACSHA1]::new($secretAsBytes)
    $hash = $hmacGen.ComputeHash($timeBytes)

    # Take half the last byte
    $offset = $hash[$hash.Length - 1] -band 0xF

    # Use it as an index into the hash bytes and take 4 bytes from there (big-endian needed)
    $fourBytes = $hash[$offset..($offset + 3)]
    if ([BitConverter]::IsLittleEndian) {
      [Array]::Reverse($fourBytes)
    }

    # Remove the most significant bit
    $num = [BitConverter]::ToInt32($fourBytes, 0) -band 0x7FFFFFFF

    # remainder of dividing by 1M
    # pad to 6 digits with leading zero(s)
    # and put a space for nice readability
    $PIN = ($num % 1000000).ToString().PadLeft(6, '0').Insert(3, ' ')

    [PSCustomObject]@{
      'PinCode'          = $PIN
      'SecondsRemaining' = ($TimeWindow - ($epochTime % $TimeWindow))
    }
  }

  End {}
}

Function New-OTPSecret {
  $RNG = [Security.Cryptography.RNGCryptoServiceProvider]::Create()
  [Byte[]]$x = 1
  for ($r = ''; $r.length -lt 64) {
    $RNG.GetBytes($x)
    if ([char]$x[0] -clike '[2-7A-Z]') {
      $r += [char]$x[0]
    }
  }
  $r
}