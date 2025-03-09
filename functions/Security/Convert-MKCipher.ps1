function Convert-MKCipher {
  <#
  .SYNOPSIS
  Returns SSL Cipher name equivalent between IANA and OpenSSL

  .DESCRIPTION
  Returns SSL Cipher name equivalent between IANA and OpenSSL using openssl.exe

  .PARAMETER Cipher
  The cipher name to convert (IANA or OpenSSL format)

  .PARAMETER ExePath
  The path to the openssl.exe file. If not provided, a default path will be used.

  .EXAMPLE
  Convert-MKCipher -Cipher 'AES256-SHA256'
  Returns the IANA equivalent string

  .EXAMPLE
  Convert-MKCipher -Cipher 'TLS_RSA_WITH_AES_256_CBC_SHA256'
  Returns the OpenSSL equivalent string

  .EXAMPLE
  Convert-MKCipher -Cipher 'TLS_RSA_WITH_AES_256_CBC_SHA256' -ExePath 'C:\Program Files\Git\mingw64\bin\openssl.exe'

  .NOTES
  Requires OpenSSL version 1.1.1 or higher.
  If you have the latest version of Git, it should include a recent version of openssl.exe.
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string]$Cipher,

    [Parameter()]
    [ValidateScript({
        if (Test-Path $_ -PathType Leaf) {
          $opensslVersion = & $_ version
          if ($opensslVersion -notlike 'OpenSSL 1.1.1*') {
            throw 'Invalid OpenSSL version. Please provide a path to OpenSSL version 1.1.1 or higher.'
          }
          return $true
        }
        throw 'The specified path does not exist or is not a file.'
      })]
    #[string]$ExePath = (Get-MyParam).'Convert-MKCipher'.exePath
    [string]$ExePath = 'C:\Program Files\Git\mingw64\bin\openssl.exe'  # Default path if not provided
  )

  begin {
    # Initialize cache
    if (-not $script:CipherCache) {
      $script:CipherCache = @{}
    }
  }

  process {
    # Check cache first
    if ($script:CipherCache.ContainsKey($Cipher)) {
      Write-Verbose "Returning cached result for $Cipher"
      return $script:CipherCache[$Cipher]
    }

    try {
      $result = $null
      Write-Verbose "Executing OpenSSL command: $ExePath ciphers -stdname"
      $opensslOutput = & "$ExePath" ciphers -stdname 2>&1

      if ($LASTEXITCODE -ne 0) {
        throw "OpenSSL command failed with exit code $LASTEXITCODE"
        return
      }

      #OpenSSL to IANA
      $ianaMatch = $opensslOutput | Select-String "\s$Cipher\s" | Select-Object -First 1
      if ($ianaMatch) {
        $result = $ianaMatch.Line.split(' ')[0]
        Write-Verbose "Found IANA match: $result"
      }

      if (-not $result) {
        #IANA to OpenSSL
        $opensslMatch = $opensslOutput | Select-String "^$Cipher\s" | Select-Object -First 1
        if ($opensslMatch) {
          $result = $opensslMatch.Line.Split(' ')[2]
          Write-Verbose "Found OpenSSL match: $result"
        }
      }

      if ($result) {
        $script:CipherCache[$Cipher] = $result
        return $result
      } else {
        Write-Warning "No matching cipher found for [$Cipher]"
      }
    } catch {
      Write-Error "An error occurred: $_"
    }
  }
}