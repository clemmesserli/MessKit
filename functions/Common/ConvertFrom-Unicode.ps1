Function ConvertFrom-Unicode {
    <#
        .SYNOPSIS
        Converts Unicode escape sequences in a string to their corresponding Unicode characters.

        .DESCRIPTION
        This function takes a string as input and converts any Unicode escape sequences (e.g., \uXXXX) to their corresponding Unicode characters.

        .PARAMETER InputString
        The string containing Unicode escape sequences to be converted.

        .EXAMPLE
        ConvertFrom-Unicode -InputString "Hello \u0048\u0065\u006C\u006C\u006F"
        Output: "Hello Hello"

        .EXAMPLE
        "Hello \u0048\u0065\u006C\u006C\u006F" | ConvertFrom-Unicode
        Output: "Hello Hello"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]] $InputString
    )

    begin {
        $regex = [regex]'\\u(?<Value>[a-fA-F0-9]{4})'
    }

    Process {
        foreach ($string in $InputString) {
            $regex.Replace($string, {
                    param($match)
                    [char]::ConvertFromUtf32([int]::Parse($match.Groups['Value'].Value, 'HexNumber'))
                })
        }
    }
}