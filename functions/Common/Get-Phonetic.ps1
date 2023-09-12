Function Get-Phonetic {
    <#
    .SYNOPSIS
        Function to return the phonetic spelling from a list of one or more strings.
    .DESCRIPTION
        This function expands the NATO spelling alphabet to also include non-alphanumeric characters on most computer keyboards.
    .NOTES
        Legal Disclaimer:
        THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
        EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
    .PARAMETER StringList
        One or more strings to be spelled phonetically.
    .EXAMPLE
        Get-Phonetic -StringList "P@ssw0rd!" | Select-Object -ExpandProperty phonetic | Format-List
        Description: Returns String plus Phonetic alphabet in json formatting
    .EXAMPLE
        Get-Phonetic -StringList "P@ssw0rd!","Go0dL&ck^" | ConvertTo-Json -depth 10
        Description: Returns an Array of String plus Phonetic alphabet values in json formatting
    .EXAMPLE
        Get-Phonetic -StringList "P@ssw0rd!","Go0dL&ck^" | ConvertTo-Json -depth 10 | ConvertFrom-Unicode
        Description: Returns String plus Phonetic alphabet in json formatting, replacing any special unicode values resulting from the 'ConvertTo-Json' cmdlet
    .EXAMPLE
        New-Password -PwdLength 16 | Get-Phonetic | ConvertTo-Json -depth 10 | ConvertFrom-Unicode
        Description: Makes use of the 'New-Password' function to create a new randomized value which is then returned as a String plus Phonetic alphabet in json formatting, replacing any special unicode values resulting from the 'ConvertTo-Json' cmdlet
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [String[]]$StringList
    )

    Begin {}

    Process {
        $PhoneticResponse = @()
        ForEach ($String In $StringList) {
            $NatoList = @()
            foreach ($Char in $String.ToCharArray()) {
                switch -CaseSensitive ($Char) {
                    #region Lower-Case Letters
                    "a" { $nato = "$Char = lower case a as in alpha" }
                    "b" { $nato = "$Char = lower case b as in bravo" }
                    "c" { $nato = "$Char = lower case c as in charlie" }
                    "d" { $nato = "$Char = lower case d as in delta" }
                    "e" { $nato = "$Char = lower case e as in echo" }
                    "f" { $nato = "$Char = lower case f as in foxtrot" }
                    "g" { $nato = "$Char = lower case g as in golf" }
                    "h" { $nato = "$Char = lower case h as in hotel" }
                    "i" { $nato = "$Char = lower case i as in india" }
                    "j" { $nato = "$Char = lower case j as in juliett" }
                    "k" { $nato = "$Char = lower case k as in kilo" }
                    "l" { $nato = "$Char = lower case l as in lima" }
                    "m" { $nato = "$Char = lower case m as in mike" }
                    "n" { $nato = "$Char = lower case n as in november" }
                    "o" { $nato = "$Char = lower case o as in oscar" }
                    "p" { $nato = "$Char = lower case p as in papa" }
                    "q" { $nato = "$Char = lower case q as in quebec" }
                    "r" { $nato = "$Char = lower case r as in romeo" }
                    "s" { $nato = "$Char = lower case s as in sierra" }
                    "t" { $nato = "$Char = lower case t as in tango" }
                    "u" { $nato = "$Char = lower case u as in uniform" }
                    "v" { $nato = "$Char = lower case v as in victor" }
                    "w" { $nato = "$Char = lower case w as in whiskey" }
                    "x" { $nato = "$Char = lower case x as in x-ray" }
                    "y" { $nato = "$Char = lower case y as in yankee" }
                    "z" { $nato = "$Char = lower case z as in zulu" }
                    #endregion Lower-Case Letters

                    #region Upper-Case Letters
                    "A" { $nato = "$Char = upper case A as in Alpha" }
                    "B" { $nato = "$Char = upper case A as in Bravo" }
                    "C" { $nato = "$Char = upper case C as in Charlie" }
                    "D" { $nato = "$Char = upper case D as in Delta" }
                    "E" { $nato = "$Char = upper case E as in Echo" }
                    "F" { $nato = "$Char = upper case F as in Foxtrot" }
                    "G" { $nato = "$Char = upper case G as in Golf" }
                    "H" { $nato = "$Char = upper case H as in Hotel" }
                    "I" { $nato = "$Char = upper case I as in India" }
                    "J" { $nato = "$Char = upper case J as in Juliett" }
                    "K" { $nato = "$Char = upper case K as in Kilo" }
                    "L" { $nato = "$Char = upper case L as in Lima" }
                    "M" { $nato = "$Char = upper case M as in Mike" }
                    "N" { $nato = "$Char = upper case N as in November" }
                    "O" { $nato = "$Char = upper case O as in Oscar" }
                    "P" { $nato = "$Char = upper case P as in Papa" }
                    "Q" { $nato = "$Char = upper case Q as in Quebec" }
                    "R" { $nato = "$Char = upper case R as in Romeo" }
                    "S" { $nato = "$Char = upper case S as in Sierra" }
                    "T" { $nato = "$Char = upper case T as in Tango" }
                    "U" { $nato = "$Char = upper case U as in Uniform" }
                    "V" { $nato = "$Char = upper case V as in Victor" }
                    "W" { $nato = "$Char = upper case W as in Whiskey" }
                    "X" { $nato = "$Char = upper case X as in X-ray" }
                    "Y" { $nato = "$Char = upper case Y as in Yankee" }
                    "Z" { $nato = "$Char = upper case Z as in Zulu" }
                    #endregion Upper-Case Letters

                    #region Numbers
                    "0" { $nato = "$Char = number Zero" }
                    "1" { $nato = "$Char = number One" }
                    "2" { $nato = "$Char = number Two" }
                    "3" { $nato = "$Char = number Three" }
                    "4" { $nato = "$Char = number Four" }
                    "5" { $nato = "$Char = number Five" }
                    "6" { $nato = "$Char = number Six" }
                    "7" { $nato = "$Char = number Seven" }
                    "8" { $nato = "$Char = number Eight" }
                    "9" { $nato = "$Char = number Nine" }
                    #endregion Numbers

                    #region Symbols
                    "``" { $nato = "$Char = backtick" }
                    "~" { $nato = "$Char = tilde" }
                    "!" { $nato = "$Char = exclamation" }
                    "@" { $nato = "$Char = at sign" }
                    "#" { $nato = "$Char = pound" }
                    "`$" { $nato = "$Char = dollar" }
                    "%" { $nato = "$Char = percent" }
                    "^" { $nato = "$Char = carat" }
                    "&" { $nato = "$Char = ampersand" }
                    "<" { $nato = "$Char = less than" }
                    ">" { $nato = "$Char = greater than" }
                    "=" { $nato = "$Char = equal" }
                    "+" { $nato = "$Char = plus" }
                    "-" { $nato = "$Char = minus" }
                    "*" { $nato = "$Char = asterisk" }
                    "/" { $nato = "$Char = forward slash" }
                    "\" { $nato = "$Char = back slash" }
                    "." { $nato = "$Char = period" }
                    "," { $nato = "$Char = comma" }
                    ";" { $nato = "$Char = semicolon" }
                    ":" { $nato = "$Char = colon" }
                    "_" { $nato = "$Char = underscore" }
                    "(" { $nato = "$Char = left parenthesis" }
                    ")" { $nato = "$Char = right parenthesis" }
                    "{" { $nato = "$Char = left curly brace" }
                    "}" { $nato = "$Char = right curly brace" }
                    "[" { $nato = "$Char = left bracket" }
                    "]" { $nato = "$Char = right bracket" }
                    "|" { $nato = "$Char = pipe" }
                    "`'" { $nato = "$Char = single quote" }
                    "`"" { $nato = "$Char = double quote" }
                    "?" { $nato = "$Char = question mark" }
                    " " { $nato = "$Char = space" }
                    #endregion Symbols
                }
                $NatoList += $nato
                $NatoHash = [PSCustomObject]@{
                    String   = $String;
                    Length   = $String.Length;
                    Phonetic = $NatoList;
                }
            }
            $PhoneticResponse += $NatoHash
        }
        $PhoneticResponse
    }

    End {}
}