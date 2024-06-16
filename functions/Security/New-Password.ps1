Function New-Password {
    <#
        .SYNOPSIS
        Generates a new randomized password.

        .DESCRIPTION
        Generates a new randomized password of a specified length, with customizable complexity based on the input parameters.
        The password can include uppercase letters, lowercase letters, numbers, and special characters.

        .NOTES
        Legal Disclaimer:
        THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
        EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.

        .PARAMETER PwdLength
        Specifies the length of the password. Default is 16 characters.

        .PARAMETER LCCount
        Specifies the number of lowercase letters in the password.

        .PARAMETER UCCount
        Specifies the number of uppercase letters in the password.

        .PARAMETER NumCount
        Specifies the number of numeric characters in the password.

        .PARAMETER SymCount
        Specifies the number of special characters in the password.

        .EXAMPLE
        New-Password | Set-Clipboard
        Generates a 16-character randomized password containing uppercase, lowercase, numeric, and special characters, and copies it to the clipboard.

        .EXAMPLE
        New-Password | Get-Phonetic -output audio
        Generates a 16-character randomized password containing uppercase, lowercase, numeric, and special characters.
        Get-Phonetic will then return audio representation based upon the NATO spelling of each character.

        .EXAMPLE
        New-Password -PwdLength 24
        Generates a 24-character randomized password containing uppercase, lowercase, numeric, and special characters for increased strength.

        .EXAMPLE
        New-Password -PwdLength 18 -SymCount 1 -NumCount 1 -UCCount 3 -LCCount 3
        Generates an 18-character randomized password containing at least 1 special character, 1 numeric character, 3 uppercase letters, and 3 lowercase letters.
        The remaining characters will be randomized from the specified types.

        .EXAMPLE
        New-Password -PwdLength 9 -NumCount 9
        Generates a 9-character password consisting only of numbers.

        .EXAMPLE
        New-Password -PwdLength 9 -NumCount 3 -UCCount 2 -LCCount 4
        Generates a 9-character password without special characters, containing exactly 3 numeric characters, 2 uppercase letters, and 4 lowercase letters.

        .EXAMPLE
        New-Password -PwdLength 9 -SymCount 0
        Generates a 9-character password without special characters, with the remaining character types randomized.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("PasswordLength", "Length")]
        [ValidateRange(8, [int]::MaxValue)]
        [int]$PwdLength = 16,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("LowerCaseCount")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$LCCount = 0,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("UpperCaseCount")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$UCCount = 0,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("NumericCount")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$NumCount = 0,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("SymbolCount")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$SymCount = 0
    )

    Process {
        # Validate the total count does not exceed PwdLength
        $totalSpecifiedCount = $LCCount + $UCCount + $NumCount + $SymCount
        if ($totalSpecifiedCount -gt $PwdLength) {
            Write-Error "Invalid input: The sum of LCCount, UCCount, NumCount, and SymCount must be less than or equal to PwdLength."
            return
        }

        Write-Verbose "Password Length = $PwdLength"
        Write-Verbose "Pre-Adjusted LCCount = $LCCount"
        Write-Verbose "Pre-Adjusted UCCount = $UCCount"
        Write-Verbose "Pre-Adjusted NumCount = $NumCount"
        Write-Verbose "Pre-Adjusted SymCount = $SymCount"

        $charTypes = @(
            @{Name = 'LCCount'; Count = [ref]$LCCount; IsSpecified = $PSBoundParameters.ContainsKey('LCCount') },
            @{Name = 'UCCount'; Count = [ref]$UCCount; IsSpecified = $PSBoundParameters.ContainsKey('UCCount') },
            @{Name = 'NumCount'; Count = [ref]$NumCount; IsSpecified = $PSBoundParameters.ContainsKey('NumCount') },
            @{Name = 'SymCount'; Count = [ref]$SymCount; IsSpecified = $PSBoundParameters.ContainsKey('SymCount') }
        )

        # Filter out types with count explicitly set to 1 and value set to 0
        $charTypesCount = @($charTypes | Where-Object { $_.IsSpecified }).Count
        Write-Verbose "CharTypes Count: $(@($charTypes | Where-Object { $_.IsSpecified -and $_.Count.Value -ge 0 }).Count)"
        if ($charTypesCount -eq 0) {
            Write-Verbose "All character types will be included for distribution."
            $typesToDistribute = $charTypes
        } elseif ($charTypesCount -eq 1 -and ($charTypes | Where-Object { $_.IsSpecified -and $_.Count.Value -eq 0 })) {
            Write-Verbose "Excluding character types with a count of 0 for distribution."
            $typesToDistribute = $charTypes | Where-Object { (-not($_.IsSpecified)) }
        } else {
            Write-Verbose "Only specified character types with non-zero counts will be distributed."
            $typesToDistribute = $charTypes | Where-Object { $_.IsSpecified -and $_.Count.Value -gt 0 }
        }

        # Distribute remaining length
        $remainingLength = $PwdLength - $totalSpecifiedCount
        Write-Verbose "Remaining Length = $remainingLength"
        Write-Verbose "TypesToDistribute: $($typesToDistribute.Name)"
        while ($remainingLength -gt 0) {
            foreach ($type in ($typesToDistribute | Get-Random)) {
                $type.Count.Value++
                $remainingLength--
                if ($remainingLength -eq 0) { break }
            }
        }

        Write-Verbose "Adjusted LCCount = $LCCount"
        Write-Verbose "Adjusted UCCount = $UCCount"
        Write-Verbose "Adjusted NumCount = $NumCount"
        Write-Verbose "Adjusted SymCount = $SymCount"

        # # Helper function to generate character arrays
        function Get-RandomChars {
            param (
                [char[]]$charSet,
                [int]$count
            )
            if ($count -gt 0) {
                return ($charSet | Get-Random -Count $count)
            } else {
                return @()
            }
        }

        # # Generate the character sets
        $LCChars = Get-RandomChars -charSet 'abcdefghijklmnopqrstuvwxyz'.ToCharArray() -count $LCCount
        $UCChars = Get-RandomChars -charSet 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray() -count $UCCount
        $NumChars = Get-RandomChars -charSet (0..9 | ForEach-Object { $_.ToString() }).ToCharArray() -count $NumCount
        $SymChars = Get-RandomChars -charSet '~!@$^*()-_=+[]{}:,.'.ToCharArray() -count $SymCount

        # Combine all characters into a single array/list
        $arr = @()
        if ($LCChars) { $arr += $LCChars }
        if ($UCChars) { $arr += $UCChars }
        if ($NumChars) { $arr += $NumChars }
        if ($SymChars) { $arr += $SymChars }

        # Shuffle the combined array/list
        $RandPwd = ($arr | Get-Random -Count $arr.Count) -join ""
        $RandPwd
    }
}
