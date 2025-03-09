function Export-MKLabCert {
  <#
  .SYNOPSIS
  Exports certificates (crt) and optionally private key files (pfx) from Windows certificate stores.

  .DESCRIPTION
  Export-MKLabCert exports certificates from Windows certificate stores (LocalMachine or CurrentUser)
  to file system locations as .crt files. When the -IncludeKey parameter is specified, it exports
  certificates with their private keys as .pfx files.

  The function can export multiple certificates in a single operation and supports providing
  custom passwords for PFX encryption or will auto-generate secure passwords when none are provided.

  When exporting with private keys, the function creates a CertInfo.txt file in the export directory
  containing certificate subjects, thumbprints, and passwords for reference.

  .PARAMETER FolderPath
  Destination folder where the certificate files will be exported.
  Default is "C:\MyCerts" - the directory will be created if it doesn't exist.

  .PARAMETER Subject
  Certificate subject name(s) to search for in the certificate store.
  This parameter accepts pipeline input and is required.
  Partial matches are supported - the function will match any certificate where the subject contains this string.

  .PARAMETER CertStore
  Certificate store location to search for certificates.
  Valid options: "LocalMachine" or "CurrentUser"
  Default is "LocalMachine"

  .PARAMETER Password
  SecureString password used to protect the private key when exporting a PFX file.
  If not provided and -IncludeKey is specified, a random password will be generated.

  .PARAMETER IncludeKey
  Switch parameter that when specified exports the certificate with its private key as a PFX file.
  If not specified, only the public certificate is exported as a CRT file.
  Note: The certificate's private key must be marked as exportable.

  .EXAMPLE
  "MyLabRootCA" | Export-MKLabCert -IncludeKey

  Exports the certificate with subject containing "MyLabRootCA2" from LocalMachine store to C:\MyCerts.
  Creates both .crt and .pfx files with an auto-generated password stored in CertInfo.txt.

  .EXAMPLE
  "MyLabRootCA", "MyLabIssuerCA" | Export-MKLabCert -IncludeKey

  Exports two certificates from the LocalMachine store, including their private keys.
  Demonstrates pipeline input with multiple certificate names.

  .EXAMPLE
  Export-MKLabCert -Subject "demo1.mylab.com" -Password (ConvertTo-SecureString "GetABetterPwd" -AsPlainText -Force) -IncludeKey

  Exports a server certificate with a specific password for the PFX file.
  Uses the default LocalMachine store and C:\MyCerts directory.

  .EXAMPLE
  Export-MKLabCert -Subject "MyLabCodeSign" -CertStore "CurrentUser" -FolderPath "C:\MyCerts" -Password (ConvertTo-SecureString "GetABetterPwd" -AsPlainText -Force) -IncludeKey

  Exports a code signing certificate from the CurrentUser store to a custom folder location.
  Specifies a custom password for the PFX file.

  .EXAMPLE
  Export-MKLabCert -Subject "MyLabDocEncryption" -CertStore "CurrentUser" -FolderPath "C:\MyCerts"

  Exports only the public certificate (no private key) for a document encryption certificate
  from the CurrentUser store to a custom folder location.

  .INPUTS
  [System.String[]]
  You can pipe certificate subject names to this function.

  .OUTPUTS
  None. This function creates certificate files in the specified directory but does not return objects to the pipeline.

  .NOTES
  Security Warnings:
  - This function is designed for lab environments ONLY.
  - PFX passwords are stored in plain text in CertInfo.txt, creating a security risk.
  - In production environments, use more secure certificate management practices.

  Requirements:
  - Run with appropriate permissions to access the specified certificate store.
  - When using -IncludeKey, the certificate's private key must be marked as exportable.
  - The ConvertFrom-MKSecureStringToText and New-MKPassword functions must be available.
  #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [string]$FolderPath = 'C:\MyCerts',

    [Parameter(Mandatory, ValueFromPipeline)]
    [Alias('SubjectName')]
    [string[]]$Subject,

    [Parameter()]
    [ValidateSet('LocalMachine', 'CurrentUser')]
    [string]$CertStore = 'LocalMachine',

    [Parameter()]
    [securestring]$Password,

    [Parameter()]
    [switch]$IncludeKey
  )

  begin {
    if (-not(Test-Path -Path $FolderPath)) {
      try {
        New-Item -Path $FolderPath -ItemType Directory -ErrorAction Stop
      } catch {
        Write-Error "Failed to create directory: $FolderPath"
        throw
      }
    }
  }

  process {
    foreach ($sub in $Subject) {
      try {
        $cert = Get-ChildItem -Path "Cert:\$CertStore\My" | Where-Object { $_.Subject -match "$sub" } -ErrorAction Stop
      } catch {
        Write-Error "Certificate with subject $sub not found."
        continue
      }

      if ($IncludeKey) {
        if (-not $Password) {
          # Generate a pseudo-random password
          $Password = ConvertTo-SecureString -String "$(New-MKPassword -PwdLength 18)" -Force -AsPlainText
        }

        try {
          Export-PfxCertificate -Cert "Cert:\$CertStore\My\$($cert.Thumbprint)"  -FilePath "$FolderPath\$Sub.pfx" -Password $Password
          # Convert SecureString to PlainText and add entry to CertInfo file
          Add-Content -Value "$Subject, $($cert.Thumbprint), $(ConvertFrom-MKSecureStringToText -SecureString $Password)" -Path "$FolderPath\CertInfo.txt"
        } catch {
          Write-Error "$sub : Failed to export PFX : $_"
        }
      } else {
        try {
          Export-Certificate -Cert "Cert:\$CertStore\My\$($cert.Thumbprint)" -FilePath "$FolderPath\$sub.crt" -ErrorAction Stop
        } catch {
          Write-Error "$sub : Failed to export CRT : $_"
        }
      }
    }
  }
}