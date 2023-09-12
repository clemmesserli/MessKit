Function New-LabCert {
    <#
	.SYNOPSIS
		Create various certs that may be used as part of a lab
	.DESCRIPTION
		This function can be used to create Root, Issuer, Web, CodeSigning, and Document Encryption certificates
	.EXAMPLE
		New-LabCert -CertType 'Root' -CertStore 'CurrentUser' -Subject 'MyRootCA' -Days '365'
	.EXAMPLE
		New-LabCert -CertType 'Intermediate' -CertStore 'CurrentUser' -Subject 'MyIntermediateCA' -Days '365' -Issuer 'MyRootCA'
	.EXAMPLE
		New-LabCert -CertType 'DocumentEncryption' -CertStore 'CurrentUser' -Subject 'MyCryptoCert' -Days '365' -Issuer 'MyIntermediateCA'
	.EXAMPLE
		New-LabCert -CertType 'Web' -CertStore 'CurrentUser' -Subject 'demo1.mylab.com' -Days '365' -Issuer 'MyIntermediateCA'
 	.EXAMPLE
		New-LabCert -CertType 'ClientAuth' -CertStore 'CurrentUser' -Subject 'CN=HelpDeskUser,OU=Users,DC=mylab,DC=com' -UPN 'HelpDeskUser@mylab.com' -Days '30' -TargetDomain 'demo1.mylab.com'
	#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Aliast("SubjectName")]
        [String]$Subject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet("LocalMachine", "CurrentUser")]
        [String]$CertStore = "CurrentUser",

        [Parameter(ValueFromPipelineByPropertyName)]
        [String[]]$SubjectAltName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("UPN")]
        [String[]]$UserPrincipalName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [String[]]$GUID = (New-Guid).Guid,

        [Parameter(ValueFromPipelineByPropertyName)]
        [String[]]$TargetDomain,

        [Parameter(ValueFromPipelineByPropertyName)]
        [String]$Issuer,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet("Root", "Intermediate", "Web", "CodeSigning", "DocumentEncryption", "ClientAuth")]
        [String]$CertType,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Int]$Days = 365
    )

    Begin {}

    Process {
        $NotAfter = (Get-Date).AddDays($Days)
        $DnsName = @([Array]$Subject + [Array]$SubjectAltName) | Sort-Object -Unique

        Switch ($CertType) {
            "Root" {
                $CertParams = @{
                    CertStoreLocation = $(Join-Path "Cert:\$CertStore" "My")
                    HashAlgorithm     = "sha256"
                    KeyAlgorithm      = "RSA"
                    KeyExportPolicy   = "Exportable"
                    KeyLength         = 2048
                    KeySpec           = "Signature"
                    KeyUsage          = @(
                        "CRLSign",
                        "CertSign",
                        "DataEncipherment",
                        "DigitalSignature",
                        "KeyAgreement",
                        "KeyEncipherment"
                    )
                    KeyUsageProperty  = "Sign"
                    Provider          = "Microsoft Strong Cryptographic Provider"
                    Subject           = "$Subject"
                    TextExtension     = @(
                        "2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2,1.3.6.1.5.5.7.3.3,1.3.6.1.5.5.7.3.4,1.3.6.1.5.5.7.3.8,1.3.6.1.4.1.311.10.3.4,1.3.6.1.4.1.311.10.3.12",
                        "2.5.29.19={critical}{text}cA=true&pathLength=1"
                    )
                    Type              = "Custom"
                    DnsName           = "$Subject"
                    NotAfter          = $NotAfter
                }
                New-SelfSignedCertificate @CertParams
            }
            "Intermediate" {
                $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "My") | Where-Object Subject -EQ "CN=$Issuer" )

                $CertParams = @{
                    CertStoreLocation = $(Join-Path "Cert:\$CertStore" "My")
                    HashAlgorithm     = "sha256"
                    KeyAlgorithm      = "RSA"
                    KeyExportPolicy   = "Exportable"
                    KeyLength         = 2048
                    KeySpec           = "Signature"
                    KeyUsage          = @(
                        "CRLSign",
                        "CertSign",
                        "DataEncipherment",
                        "DigitalSignature",
                        "KeyAgreement",
                        "KeyEncipherment"
                    )
                    KeyUsageProperty  = "Sign"
                    Provider          = "Microsoft Strong Cryptographic Provider"
                    Subject           = "$Subject"
                    TextExtension     = @(
                        "2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2,1.3.6.1.5.5.7.3.3,1.3.6.1.5.5.7.3.4,1.3.6.1.5.5.7.3.8,1.3.6.1.4.1.311.10.3.4,1.3.6.1.4.1.311.10.3.12",
                        "2.5.29.19={critical}{text}cA=true&pathLength=0"
                    )
                    Type              = "Custom"
                    DnsName           = "$Subject"
                    NotAfter          = $NotAfter
                    Signer            = $Signer
                }
                New-SelfSignedCertificate @CertParams
            }
            "Web" {
                $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "CA") | Where-Object Subject -EQ "CN=$Issuer" )

                $CertParams = @{
                    CertStoreLocation = $(Join-Path "Cert:\$CertStore" "My")
                    HashAlgorithm     = "sha256"
                    KeyAlgorithm      = "RSA"
                    KeyExportPolicy   = "Exportable"
                    KeyLength         = 2048
                    Provider          = "Microsoft Strong Cryptographic Provider"
                    Subject           = "$Subject"
                    TextExtension     = @(
                        "2.5.29.37={text}1.3.6.1.5.5.7.3.1,1.3.6.1.5.5.7.3.2",
                        "2.5.29.19={text}cA=false"
                    )
                    DnsName           = $DnsName
                    FriendlyName      = "$($Subject)_$($NotAfter.ToString('yyyyMMdd'))"
                    NotAfter          = $NotAfter
                    Signer            = $Signer
                }
                New-SelfSignedCertificate @CertParams
            }
            "ClientAuth" {
                $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "CA") | Where-Object Subject -EQ "CN=$Issuer" )

                $CertParams = @{
                    Type              = "Custom"
                    CertStoreLocation = $(Join-Path "Cert:\$CertStore" "My")
                    HashAlgorithm     = "sha256"
                    KeyAlgorithm      = "RSA"
                    KeyExportPolicy   = "NonExportable"
                    KeyLength         = 2048
                    KeyUsage          = "DigitalSignature"
                    Subject           = "$Subject"
                    TextExtension     = @(
                        "2.5.29.37={text}1.3.6.1.5.5.7.3.2",
                        "2.5.29.17={text}UPN=$UserPrincipalName&DirectoryName=$Subject&GUID=$GUID&URL=$TargetDomain"
                    )
                    NotAfter          = $NotAfter
                    Signer            = $Signer
                }
                New-SelfSignedCertificate @CertParams
            }
            "DocumentEncryption" {
                $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "CA") | Where-Object Subject -EQ "CN=$Issuer" )

                $CertParams = @{
                    Type              = "DocumentEncryptionCert"
                    CertStoreLocation = $(Join-Path "Cert:\$CertStore" "My")
                    FriendlyName      = "$($Subject)_$($NotAfter.ToString('yyyyMMdd'))"
                    HashAlgorithm     = "sha256"
                    KeyAlgorithm      = "RSA"
                    KeyExportPolicy   = "NonExportable"
                    KeyLength         = 2048
                    KeyUsage          = "KeyEncipherment", "KeyAgreement", "DataEncipherment", "DigitalSignature"
                    Provider          = "Microsoft Strong Cryptographic Provider"
                    Subject           = "$Subject"
                    TextExtension     = @(
                        "2.5.29.37={text}1.3.6.1.4.1.311.80.1"
                    )
                    NotAfter          = $NotAfter
                    Signer            = $Signer
                }
                New-SelfSignedCertificate @CertParams
            }
            "CodeSigning" {
                $Signer = ( Get-ChildItem $(Join-Path "Cert:\$CertStore" "CA") | Where-Object Subject -EQ "CN=$Issuer" )

                $CertParams = @{
                    Type              = "CodeSigningCert"
                    CertStoreLocation = $(Join-Path "Cert:\$CertStore" "My")
                    Subject           = "$Subject"
                    FriendlyName      = "$($Subject)_$($NotAfter.ToString('yyyyMMdd'))"
                    HashAlgorithm     = "sha256"
                    KeyAlgorithm      = "RSA"
                    KeyExportPolicy   = "NonExportable"
                    KeyLength         = 2048
                    NotAfter          = $NotAfter
                    Signer            = $Signer
                }
                New-SelfSignedCertificate @CertParams
            }
        }
    }

    End {}
}