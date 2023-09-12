Function New-Password {
    <#
    .SYNOPSIS
        Create new randomized password.
    .DESCRIPTION
        Create new randomized passwords of varying lengths and/or complexity based upon parameter inputs.
    .NOTES
        Legal Disclaimer:
        THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
        EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
    .EXAMPLE
        New-Password | Set-Clipboard
        Description:  Create a 16-character randomized password containing uppercase, lowercase, numeric, and special characters
        which is then piped to your clipboard.
    .EXAMPLE
        New-Password | Get-Phonetic | ConvertTo-Json
        Description:  Create a 16-character randomized password containing uppercase, lowercase, numeric, and special characters
        which is then piped to another function to get the NATO spelling of each character.
    .EXAMPLE
        New-Password -PwdLength 24
        Description:  Create a very strong 24-character randomized password containing uppercase, lowercase, numeric, and special characters.
    .EXAMPLE
        New-Password -PwdLength 24 -SymCount 6 -NumCount 6 -UCCount 6 -LCCount 6
        Description:  Create a strong 16-character randomized password containing uppercase, lowercase, numeric, and special characters.
    .EXAMPLE
        New-Password -PwdLength 24 -SymCount 0
        Description:  Create a medium strength 16-character randomized password without special characters.
    .EXAMPLE
        New-Password -PwdLength 9 -SymCount 0 -LCCount 0 -UCCount 0
        Description:  Create a low strength 9-character randomized numeric only value.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("PasswordLength", "Length")]
        [Int]$PwdLength = "16",

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("LowerCaseCount")]
        [Int]$LCCount = "7",

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("UpperCaseCount")]
        [Int]$UCCount = "5",

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("NumericCount")]
        [Int]$NumCount = "2",

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("SymbolCount")]
        [Int]$SymCount = "2"
    )

    Begin {}

    Process {
        $PwdCount = ($LCCount + $UCCount + $NumCount + $SymCount)

        if ( $PwdCount -ne $PwdLength ) {
            Write-Verbose "Password Length = $PwdLength"
            if ($SymCount -gt 0) {
                if ($NumCount + $UCCount + $LCCount -ne 0) {
                    $SymCount = ([math]::Sqrt($PwdLength) - 2) -as [Int]
                } else {
                    $SymCount = $PwdLength
                }
            }

            if ($NumCount -gt 0) {
                if ($SymCount + $UCCount + $LCCount -ne 0) {
                    $NumCount = ([math]::Sqrt($PwdLength) - 2) -as [Int]
                } else {
                    $NumCount = $PwdLength
                }
            }

            if ($UCCount -gt 0) {
                if ($SymCount + $NumCount + $LCCount -ne 0) {
                    $UCCount = ([math]::Sqrt($PwdLength) + 1) -as [Int]
                } else {
                    $UCCount = $PwdLength
                }
            }

            if ($LCCount -gt 0) {
                $LCCount = ($PwdLength - ($UCCount + $NumCount + $SymCount) )
            }

            Write-Verbose "Password Count = $($LCCount + $UCCount + $NumCount + $SymCount)"
        } else {
            Write-Verbose "Password Count matches Password Length"
        }

        $LCChars = if ($LCCount -gt 0) { ('abcdefghijklmnopqrstuvwxyz'.ToCharArray()) | Get-Random -Count $LCCount }
        $UCChars = if ($UCCount -gt 0) { ('ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()) | Get-Random -Count $UCCount }
        $NumChars = if ($NumCount -gt 0) { 1..$NumCount | ForEach-Object { 0..9 | Get-Random } }
        $SymChars = if ($SymCount -gt 0) { ('~!#=+-,._<>{}[]?)@(/\*$&^%'.ToCharArray()) | Get-Random -Count $SymCount }

        $arr = @()
        $arr += $LCChars
        $arr += $UCChars
        $arr += $NumChars
        $arr += $SymChars
        $RandPwd = ($arr | Get-Random -Count $arr.Count) -join ""
        $RandPwd
    }

    End {}
}
