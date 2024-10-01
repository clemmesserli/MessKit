function ConvertFrom-MorseCode {
  <#
  .SYNOPSIS
  Create plain text from morse code.

  .DESCRIPTION
  This script/function converts input strings to Morse Code.
  It utilizes a dictionary mapping Morse Code symbols to characters for decoding.

  .EXAMPLE
  ConvertFrom-MorseCode -String '-.-. .- .-.. .-.. / ----. .---- .---- -.-.--'

  .EXAMPLE
  ConvertFrom-MorseCode -String '.- -... -.-. .---- ..--- ...-- .--.-. .--. ----- .-- . .-. ... .... ...-- .-.. .-.. .-.-.- .-. ----- -.-. -.- ... -.-.--'

  .EXAMPLE
  ConvertFrom-MorseCode -String '.--. ----- .-- . .-. ... .... ...-- .-.. .-.. / .-. ----- -.-. -.- ... -.-.--' | Set-Clipboard

  .EXAMPLE
  ConvertFrom-MorseCode -String (Get-Content ./private/MorseCode.txt) | Out-File ./private/MorsePlain.txt
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [string[]]$String
  )

  process {
    $morseToLetter = @{
      # Upper-Case Letters
      ".-" = "A"; "-..." = "B"; "-.-." = "C"; "-.." = "D"; "." = "E"
      "..-." = "F"; "--." = "G"; "...." = "H"; ".." = "I"; ".---" = "J"
      "-.-" = "K"; ".-.." = "L"; "--" = "M"; "-." = "N"; "---" = "O"
      ".--." = "P"; "--.-" = "Q"; ".-." = "R"; "..." = "S"; "-" = "T"
      "..-" = "U"; "...-" = "V"; ".--" = "W"; "-..-" = "X"; "-.--" = "Y"
      "--.." = "Z"

      # Numbers
      "-----" = "0"; ".----" = "1"; "..---" = "2"; "...--" = "3"; "....-" = "4"
      "....." = "5"; "-...." = "6"; "--..." = "7"; "---.." = "8"; "----." = "9"

      # Symbols
      "-.-.--" = "!"; ".--.-." = "@"; ".-..." = "&"; "-...-" = "="
      ".-.-." = "+"; "-....-" = "-"; "-..-." = "/"; ".-.-.-" = "."
      "--..--" = ","; "---..." = ":"; "-.--." = "("; "-.--.-" = ")"
      ".----." = "`'"; ".-..-." = "`""; "..--.." = "?"; "/" = " "
    }

    $stringBuilder = [System.Text.StringBuilder]::new()
    foreach ($s in $String) {
      foreach ($char in $s.Split(' ')) {
        $letter = $morseToLetter[$char]
        [void]$stringBuilder.Append($letter)
      }
      $stringBuilder.ToString()
    }
  }
}