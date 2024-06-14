Function ConvertFrom-Unicode {
    <#
        .SYNOPSIS
        Converts Unicode escape sequences in a string to their corresponding Unicode characters.

        .DESCRIPTION
        This function takes a string as input and converts any Unicode escape sequences (e.g. \uXXXX) to their corresponding Unicode characters.

        .PARAMETER InputString
        The string containing Unicode escape sequences to be converted.

        .EXAMPLE
        ConvertFrom-Unicode -InputString "Hello \u0048\u0065\u006C\u006C\u006F"
        Output: "Hello Hello"

        .EXAMPLE
        "Hello \u0048\u0065\u006C\u006C\u006F" | ConvertFrom-Unicode
        Output: "Hello Hello"

        This example converts the Unicode escape sequences in the input string to their corresponding characters.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $InputString
    )

    Process {
        $InputString | ForEach-Object {
            [System.Text.RegularExpressions.Regex]::Unescape($_)
        }
    }
}