Function Export-LabCert {
  <#
    .SYNOPSIS
    Exports crt and optionally pfx files from computer certificate store.

    .DESCRIPTION
    Function to export existing Windows certificates including private keys where 'Exportable=True'.
    Option to provide a password or auto-generate one.

    .EXAMPLE
    "MyLabRootCA2" | Export-LabCert -IncludeKey

    .EXAMPLE
    "MyLabRootCA", "MyLabIssuerCA" | Export-LabCert -IncludeKey

    .EXAMPLE
    Export-LabCert -Subject "demo1.mylab.com" -Password (ConvertTo-SecureString "GetABetterPwd" -AsPlainText -Force) -IncludeKey

    .EXAMPLE
    Export-LabCert -Subject "MyLabCodeSign" -CertStore "CurrentUser" -FolderPath "C:\MyCerts" -Password (ConvertTo-SecureString "GetABetterPwd" -AsPlainText -Force) -IncludeKey

    .EXAMPLE
    Export-LabCert -Subject "MyLabDocEncryption" -CertStore "CurrentUser"  -FolderPath "C:\MyCerts" -Password (ConvertTo-SecureString "GetABetterPwd" -AsPlainText -Force)

    .NOTES
    WARNING: Use in lab environments only. Potential risk of storing certificate passwords in plain text.
	#>
  [CmdletBinding()]
  param(
    [Parameter()]
    [string]$FolderPath = "C:\Certs",

    [Parameter(Mandatory, ValueFromPipeline)]
    [Alias("SubjectName")]
    [string[]]$Subject,

    [Parameter()]
    [ValidateSet("LocalMachine", "CurrentUser")]
    [string]$CertStore = "LocalMachine",

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
          $Password = ConvertTo-SecureString -String "$(New-Password -PwdLength 18)" -Force -AsPlainText
        }

        try {
          Export-PfxCertificate -Cert "Cert:\$CertStore\My\$($cert.Thumbprint)"  -FilePath "$FolderPath\$Sub.pfx" -Password $Password
          # Convert SecureString to PlainText and add entry to CertInfo file
          Add-Content -Value "$Subject, $($cert.Thumbprint), $(ConvertFrom-SecureStringToText -SecureString $Password)" -Path "$FolderPath\CertInfo.txt"
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