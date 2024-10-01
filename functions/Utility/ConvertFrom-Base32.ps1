Function ConvertFrom-Base32 {
	<#
    .SYNOPSIS
        A PowerShell function to convert an arbitrary Base32 encoded string into a byte array or
        binary file.
    .DESCRIPTION
        Takes a string of Base32 formatted data and decodes into the original ASCII string or
        byte array. Input includes a Base32 string or a file containing Base32 string. Both
        formatted (line breaks) and unformatted Base32 data are supported. The default input and
        output type if positional parameters are used is [System.String]; it is also possible to
        write a binary file from the Base32 input using -OutFile.
    .PARAMETER Base32EncodedString
        [System.String] object containing Base32 encoded data. Accepts pipeline input.
    .PARAMETER InFile
        [System.IO.Fileinfo] object containing the details of a file on disk to be loaded as a
        string object and decoded from Base32 string; accepts pipeline input.
    .PARAMETER OutFile
        Optional [System.IO.Fileinfo] object containing the details of the new file to write to
        disk containing Base32 decoded data from the input file. Can be used with any input mode
        (Bytes, String, or InFile); file content will be raw decoded bytes.
    .PARAMETER Base32Hex
        Use the alternative charset described in RFC4648 for "Base32 Hex"
        (0123456789ABCDEFGHIJKLMNOPQRSTUV) instead of the typical Base32 charset
        (ABCDEFGHIJKLMNOPQRSTUVWXYZ234567) when decoding.
    .PARAMETER OutBytes
        Return the decoded data as [System.Byte[]] to the console instead of the default ASCII
        string.
    .PARAMETER AutoSave
        When paired with -InFile, automatically create an output filename of in the form of the
        original file name plus the suffix specified after the parameter; for example, -AutoSave
        "BIN" will result in OutFile name <InFile>.bin. Useful if piping the output of
        Get-ChildItem to the function to convert files as a bulk operation. Cannot be used with
        input methods other than -InFile.
    .PARAMETER Raw
        Optional switch parameter that when present will produce raw output instead of a
        PSObject. Depending on the parameters used, the return object could be of type
        [System.String] or [System.Byte[]].
    .INPUTS
        Any single object, array or collection of strings or files (such as those from
        Get-ChildItem) can be piped to the function for processing from Base32 encoded data.
        Input data from file is always processed as ASCII text regardless of source file text
        encoding.
    .OUTPUTS
        In the case of direct string input, a [System.String] containing the decoded data as
        ASCII text is returned within a PSObject with a single member named Base32DecodedData.
        If any input method is used with -OutFile or -InFile is used with -AutoSave, the output
        is a [System.IO.FileInfo] object containing details of a binary file with the Base32
        decoded data as contents. If -OutBytes is specified, data is returned to the console as
        [System.Byte[]] wrapped in a PSObject. If -Raw is specified, the [System.String] or
        [System.Byte[]] is not wrapped in a PSObject and is returned directly. This means that
        output using -Raw cannot easily use the pipeline. The -Verbose parameter will return the
        function's total execution time.
    .EXAMPLE
        Convert a Base32 string to a decoded byte array:
            [System.Byte[]]$Bytes = ConvertFrom-Base32 "IIAGCADTABSQAMYAGIAA====" -OutBytes -Raw
    .EXAMPLE
        Decode a Base32 encoded string:
            ConvertFrom-Base32 -Base32EncodedString "IIAGCADTABSQAMYAGIAA===="
    .EXAMPLE
        Pipe an object (string or array of strings, file info or array of file info objects) to
        the function for decoding from Base32:
            $MyObject | ConvertFrom-Base32
    .EXAMPLE
        Pipe the results of a directory listing from Get-ChildItem and generate a new Base32
        decoded file for each input file:
            Get-ChildItem C:\Text\*.b32 | ConvertFrom-Base32 -AutoSave "BIN"
    .EXAMPLE
        Use file based input to decode an input file and output the results as new file
            ConvertFrom-Base32 -File C:\Text\file.b32 -OutFile C:\Text\file.txt
    .NOTES
        More information on the Base16, Base32, and Base64 Data Encoding standard can be found
        on the IETF web site: https://tools.ietf.org/html/rfc4648
    #>
	[CmdletBinding(
		SupportsShouldProcess = $True,
		ConfirmImpact = "High",
		DefaultParameterSetName = "StringInput"
	)]
	[OutputType([System.Management.Automation.PSObject])]
	Param (
		[Parameter(
			ParameterSetName = "StringInput",
			ValueFromPipeline,
			ValueFromPipelineByPropertyName,
			Mandatory,
			Position = 0,
			HelpMessage = 'Base32 encoded string.'
		)]
		[ValidateNotNullOrEmpty()]
		[Alias('String', 'Plaintext', 'Text', 'Base32EncodedData')]
		[String]$Base32EncodedString,

		[Parameter(
			ParameterSetName = "FileInput",
			ValueFromPipeline,
			ValueFromPipelineByPropertyName,
			Mandatory,
			Position = 0,
			HelpMessage = 'File to Base32 decode.'
		)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript( {
				If (-Not($_ | Test-Path -PathType Leaf)) {
					Throw ("Invalid input file name specified.")
				} Else {
					$True
				}
			})]
		[ValidateScript( {
				Try {
					$_.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None).Close()
					$True
				} Catch {
					Throw ("Input file is locked for reading or could not obtain read access.")
				}
			})]
		[Alias('Filename', 'FullName')]
		[System.IO.Fileinfo]$InFile,

		[Parameter(
			ParameterSetName = "FileInput",
			ValueFromPipeline = $False,
			ValueFromPipelineByPropertyName = $False,
			Mandatory = $False,
			Position = 1,
			HelpMessage = 'Path to output file when decoding in file mode.'
		)]
		[ValidateNotNullOrEmpty()]
		[System.IO.Fileinfo]$OutFile,

		[Parameter(
			ParameterSetName = "ByteInput",
			ValueFromPipeline = $False,
			ValueFromPipelineByPropertyName = $False,
			Mandatory = $False,
			HelpMessage = 'Use extended Base32 Hex charset instead of standard Base32 charset.'
		)]
		[Parameter(ParameterSetName = "StringInput")]
		[Parameter(ParameterSetName = "FileInput")]
		[ValidateNotNullOrEmpty()]
		[Switch]$Base32Hex,

		[Parameter(
			ParameterSetName = "ByteInput",
			ValueFromPipeline = $False,
			ValueFromPipelineByPropertyName = $False,
			Mandatory = $False,
			HelpMessage = 'Output decoded data as raw bytes instead of ASCII text.'
		)]
		[Parameter(ParameterSetName = "StringInput")]
		[Parameter(ParameterSetName = "FileInput")]
		[ValidateNotNullOrEmpty()]
		[Switch]$OutBytes,

		[Parameter(
			ParameterSetName = "FileInput",
			ValueFromPipeline = $False,
			ValueFromPipelineByPropertyName = $False,
			Mandatory = $False,
			HelpMessage = 'When in file input mode, automatically select output file name using the specified suffix as the file extension; not valid with any other input mode (String or Bytes).'
		)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript( {
				If (-Not(($_.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1))) {
					Throw ("AutoSave suffix contains illegal characters.")
				} Else {
					$True
				}
			})]
		[String]$AutoSave,

		[Parameter(
			ParameterSetName = "StringInput",
			ValueFromPipeline = $False,
			ValueFromPipelineByPropertyName = $False,
			Mandatory = $False,
			HelpMessage = 'When returning to console, return a raw byte array instead of PSObject.'
		)]
		[Parameter(ParameterSetName = "FileInput")]
		[ValidateNotNullOrEmpty()]
		[Switch]$Raw
	)

	Begin {
		If ($PSBoundParameters.ContainsKey("AutoSave") -and $PSCmdlet.ParameterSetName -ne "FileInput") {
			Write-Error "-AutoSave can only be used in file input mode." -ErrorAction Stop
		}
		If ($Base32Hex) {
			[String]$B32CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
			[String]$B32CHARSET_Pattern = "^[A-V0-9 ]+=*$"
			[String]$B32Name = "Base32-Hex"
		} Else {
			[String]$B32CHARSET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
			[String]$B32CHARSET_Pattern = "^[A-Z2-7 ]+=*$"
			[String]$B32Name = "Base32"
		}
		[String]$B32Header = "-----BEGIN $($B32Name.ToUpper()) ENCODED DATA-----"
		[String]$B32Footer = "-----END $($B32Name.ToUpper()) ENCODED DATA-----"
	}

	Process {
		If ($PSBoundParameters.ContainsKey('InFile') -and $PSBoundParameters.ContainsKey('AutoSave')) {
			$OutFile = ($InFile.FullName.ToString()) + ".$($AutoSave)"
		}
		If ($OutFile) {
			If ((Test-Path $OutFile -PathType Leaf) -and ($PSCmdlet.ShouldProcess($OutFile, 'Overwrite'))) {
				Remove-Item $OutFile -Confirm:$False
			}
			If (Test-Path $OutFile -PathType Leaf) {
				Write-Error "Could not overwrite existing output file '$($Outfile)'" -ErrorAction Stop
			}
			$Null = New-Item -Path $OutFile -ItemType File
		}
		Switch ($PSCmdlet.ParameterSetName) {
			"StringInput" {
				[String]$Base32String = $Base32EncodedString.Replace($B32Header, "").Replace($B32Footer, "").Replace(" ", "").Replace("`r`n", "").Replace("`n", "").ToUpper()
				Break
			}
			"FileInput" {
				[String]$Base32String = ([System.IO.File]::ReadAllText($InFile.FullName)).Replace($B32Header, "").Replace($B32Footer, "").Replace(" ", "").Replace("`r`n", "").Replace("`n", "").ToUpper()
				Break
			}
		}
		If (-not ($Base32String -match $B32CHARSET_Pattern)) {
			Throw ("Invalid Base32 data encountered in input stream.")
		}
		[System.Object]$Timer = [System.Diagnostics.Stopwatch]::StartNew()
		[System.Object]$InputStream = New-Object -TypeName System.IO.MemoryStream([System.Text.Encoding]::ASCII.GetBytes($Base32String), 0, $Base32String.Length)
		[System.Object]$BinaryReader = New-Object -TypeName System.IO.BinaryReader($InputStream)
		[System.Object]$OutputStream = New-Object -TypeName System.IO.MemoryStream
		[System.Object]$BinaryWriter = New-Object -TypeName System.IO.BinaryWriter($OutputStream)
		Try {
			While ([System.Char[]]$CharsRead = $BinaryReader.ReadChars(8)) {
				[System.Byte[]]$B32Bytes = , 0x00 * 5
				[System.UInt16]$CharLen = 8 - ($CharsRead -Match "=").Count
				[System.UInt16]$ByteLen = [Math]::Floor(($CharLen * 5) / 8)
				[System.Byte[]]$BinChunk = , 0x00 * $ByteLen
				If ($CharLen -lt 8) {
					[System.Char[]]$WorkingChars = , "A" * 8
					[System.Array]::Copy($CharsRead, $WorkingChars, $CharLen)
					[System.Array]::Resize([ref]$CharsRead, 8)
					[System.Array]::Copy($WorkingChars, $CharsRead, 8)
				}
				$B32Bytes[0] = (($B32CHARSET.IndexOf($CharsRead[0]) -band 0x1F) -shl 3) -bor (($B32CHARSET.IndexOf($CharsRead[1]) -band 0x1C) -shr 2)
				$B32Bytes[1] = (($B32CHARSET.IndexOf($CharsRead[1]) -band 0x03) -shl 6) -bor (($B32CHARSET.IndexOf($CharsRead[2]) -band 0x1F) -shl 1) -bor (($B32CHARSET.IndexOf($CharsRead[3]) -band 0x10) -shr 4)
				$B32Bytes[2] = (($B32CHARSET.IndexOf($CharsRead[3]) -band 0x0F) -shl 4) -bor (($B32CHARSET.IndexOf($CharsRead[4]) -band 0x1E) -shr 1)
				$B32Bytes[3] = (($B32CHARSET.IndexOf($CharsRead[4]) -band 0x01) -shl 7) -bor (($B32CHARSET.IndexOf($CharsRead[5]) -band 0x1F) -shl 2) -bor (($B32CHARSET.IndexOf($CharsRead[6]) -band 0x18) -shr 3)
				$B32Bytes[4] = (($B32CHARSET.IndexOf($CharsRead[6]) -band 0x07) -shl 5) -bor ($B32CHARSET.IndexOf($CharsRead[7]) -band 0x1F)
				[System.Buffer]::BlockCopy($B32Bytes, 0, $BinChunk, 0, $ByteLen)
				$BinaryWriter.Write($BinChunk)
			}
			$ResultObject = New-Object -TypeName PSObject
			If ($OutFile) {
				[System.IO.File]::WriteAllBytes($OutFile, ($OutputStream.ToArray()))
				$ResultObject = $OutFile
			} Else {
				If ($OutBytes -and $Raw) {
					$ResultObject = $OutputStream.ToArray()
				} ElseIf ($OutBytes) {
					Add-Member -InputObject $ResultObject -MemberType 'NoteProperty' -Name 'ByteArray' -Value $OutputStream.ToArray()
				} ElseIf ($Raw) {
					[String]$Results = [System.Text.Encoding]::ASCII.GetString(($OutputStream.ToArray()))
					$ResultObject = $Results
				} Else {
					[String]$Results = [System.Text.Encoding]::ASCII.GetString(($OutputStream.ToArray()))
					Add-Member -InputObject $ResultObject -MemberType 'NoteProperty' -Name 'Base32DecodedString' -Value $Results
				}
			}
			Return ($ResultObject)
		} Catch {
			Write-Error "Exception: $($_.Exception.Message)"
			Break
		} Finally {
			$BinaryReader.Close()
			$BinaryReader.Dispose()
			$BinaryWriter.Close()
			$BinaryWriter.Dispose()
			$InputStream.Close()
			$InputStream.Dispose()
			$OutputStream.Close()
			$OutputStream.Dispose()
			$Timer.Stop()
			[String]$TimeLapse = "Base32 decode completed after $($Timer.Elapsed.Hours) hours, $($Timer.Elapsed.Minutes) minutes, $($Timer.Elapsed.Seconds) seconds, $($Timer.Elapsed.Milliseconds) milliseconds"
			Write-Verbose $TimeLapse
		}
	}

	End {}
}