function ConvertFrom-MorseCode {
  <#
  .SYNOPSIS
  Converts Morse code to plain text.

  .DESCRIPTION
  This function decodes Morse code input strings into readable text.
  It utilizes a dictionary mapping Morse Code symbols to characters for decoding.

  The function supports letters, numbers, and common punctuation marks.
  Each Morse code character should be separated by a space, and words separated by slashes (/).

  Invalid Morse code patterns that don't match any known character will cause errors.

  .PARAMETER String
  Specifies the Morse code string(s) to convert to plain text. This parameter accepts an array of strings
  and can receive input from the pipeline. Empty strings are allowed but will be ignored.

  .EXAMPLE
  ConvertFrom-MorseCode -String '-.-. .- .-.. .-.. / ----. .---- .---- -.-.--'

  Output: CALL 911!

  .EXAMPLE
  ConvertFrom-MorseCode -String '.- -... -.-. .---- ..--- ...-- .--.-. .--. ----- .-- . .-. ... .... ...-- .-.. .-.. .-.-.- .-. ----- -.-. -.- ... -.-.--'

  Output: ABC123@P0WERSH3LL.R0CKS!

  .EXAMPLE
  ConvertFrom-MorseCode -String '.--. ----- .-- . .-. ... .... ...-- .-.. .-.. / .-. ----- -.-. -.- ... -.-.--' | Set-Clipboard

  Converts the Morse code to "P0WERSH3LL R0CKS!" and places it in the clipboard.

  .EXAMPLE
  ConvertFrom-MorseCode -String (Get-Content ./private/MorseCode.txt) | Out-File ./private/MorsePlain.txt

  Reads Morse code from a file, converts it to plain text, and saves the output to another file.

  .OUTPUTS
  System.String
  Returns the decoded plain text from the Morse code input.

  .NOTES
  Author: MessKit Project
  Supported characters: A-Z, 0-9, and common punctuation
  Each Morse character should be separated by a space, with words separated by '/'
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
      '.-' = 'A'; '-...' = 'B'; '-.-.' = 'C'; '-..' = 'D'; '.' = 'E'
      '..-.' = 'F'; '--.' = 'G'; '....' = 'H'; '..' = 'I'; '.---' = 'J'
      '-.-' = 'K'; '.-..' = 'L'; '--' = 'M'; '-.' = 'N'; '---' = 'O'
      '.--.' = 'P'; '--.-' = 'Q'; '.-.' = 'R'; '...' = 'S'; '-' = 'T'
      '..-' = 'U'; '...-' = 'V'; '.--' = 'W'; '-..-' = 'X'; '-.--' = 'Y'
      '--..' = 'Z'

      # Numbers
      '-----' = '0'; '.----' = '1'; '..---' = '2'; '...--' = '3'; '....-' = '4'
      '.....' = '5'; '-....' = '6'; '--...' = '7'; '---..' = '8'; '----.' = '9'

      # Symbols
      '-.-.--' = '!'; '.--.-.' = '@'; '.-...' = '&'; '-...-' = '='
      '.-.-.' = '+'; '-....-' = '-'; '-..-.' = '/'; '.-.-.-' = '.'
      '--..--' = ','; '---...' = ':'; '-.--.' = '('; '-.--.-' = ')'
      '.----.' = "`'"; '.-..-.' = "`""; '..--..' = '?'; '/' = ' '
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