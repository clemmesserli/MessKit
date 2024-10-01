Function ConvertTo-Base32 {
	<#
    .SYNOPSIS
        A PowerShell function to convert arbitrary data into a Base32 encoded string.
    .DESCRIPTION
        Takes a string, byte array or file object as input and returns a Base32 encoded string
        or location of the Base32 result output file object. The default input and output type
        if positional parameters are used is [System.String].
    .PARAMETER Bytes
        [System.Byte[]] object containing a byte array to be encoded as Base32 string. Accepts
        pipeline input.
    .PARAMETER String
        [System.String] object containing plain text to be encoded as Base32 string. Accepts
        pipeline input.
    .PARAMETER InFile
        [System.IO.Fileinfo] object containing the details of a file on disk to be converted to
        Base32 string and output as a new file; output files are written as UTF-8 no BOM.
        Accepts pipeline input.
    .PARAMETER OutFile
        Optional [System.IO.Fileinfo] object containing the details of the new file to write to
        disk containing Base32 encoded data from the input file. Can be used with any input mode
        (Bytes, String, or InFile).
    .PARAMETER Unormatted
        By default the function adds line breaks to output string every 64 characters and block
        style header / footer (-----BEGIN BASE32 ENCODED DATA-----/-----END BASE32 ENCODED
        DATA-----); this parameter suppresses formatting and returns the Base32 string result as
        a single, unbroken string object with no header or footer.
    .PARAMETER Base32Hex
        Use the alternative charset described in RFC4648 for "Base32 Hex"
        (0123456789ABCDEFGHIJKLMNOPQRSTUV) instead of the typical Base32 charset
        (ABCDEFGHIJKLMNOPQRSTUVWXYZ234567).
    .PARAMETER AutoSave
        [System.String] containing a new file extension to use to automatically generate files.
        When paired with -InFile, automatically create an output filename of in the form of the
        original file name plus the suffix specified after the parameter, for example -AutoSave
        "B32" would create the OutFile name <InFile>.b32. Useful if piping the output of
        Get-ChildItem to the function to convert files as a bulk operation. Cannot be used with
        input methods other than -InFile.
    .PARAMETER Raw
        Optional switch parameter that when present will produce raw string output instead of a
        PSObject. This parameter limits the functionality of the pipeline but is convenient for
        simple encoding operations.
    .INPUTS
        Any single object or collection of strings, bytes, or files (such as those from
        Get-ChildItem) can be piped to the function for processing into Base32 encoded data.
    .OUTPUTS
        The output is always an ASCII string; if any input method is used with -OutFile or
        -InFile is used with -AutoSave, the output is a [System.IO.FileInfo] object containing
        details of a UTF8 no BOM text file with the Base32 encoded data as contents. Unless
        -Unformatted is specified, the console or file string data is formatted with block
        headers (-----BEGIN BASE32 ENCODED DATA-----/-----END BASE32 ENCODED DATA-----) and line
        breaks are added every 64 character. If -Unformatted is present, the output is a
        [System.String] with no line breaks or header / footer. If outputting to the console,
        the string is returned within a PSObject with a single member named Base32EncodedData as
        [System.String]; if -Raw is specified, the [System.String] is not wrapped in a PSObject
        and returned directly. This means that output using -Raw cannot easily use the pipeline,
        but makes it a useful option for quick encoding operations. The -Verbose parameter will
        return the function's total execution time.
    .EXAMPLE
        Convert a string directly into Base32:
            ConvertTo-Base32 "This is a plaintext string"
    .EXAMPLE
        Pipe an object (string or array of strings, byte array or array of byte arrays, file
        info or array of file info objects) to the function for encoding as Base32:
            $MyObject | ConvertTo-Base32
    .EXAMPLE
        Convert a byte array to Base32 and return the output with block formatting and not
        wrapped in a PSObject (as a raw [System.String]):
            ConvertTo-Base32 -ByteArray $Bytes -Raw
    .EXAMPLE
        Load the contents of a file as byte array and convert directly into Base32-Hex:
            ConvertTo-Base32 -Base32Hex -ByteArray ([System.IO.File]::ReadAllBytes('C:\File.txt'))
    .EXAMPLE
        Pipe the results of a directory listing from Get-ChildItem and generate a new Base32
        encoded file with block formatting for each input file:
            Get-ChildItem C:\Text\*.txt | ConvertTo-Base32 -AutoSave "B32"
    .EXAMPLE
        Use file based input to Base32 encode an input file and output the results as new file
		with no line breaks or header / footer:
            ConvertTo-Base32 -File C:\Text\file.txt -OutFile C:\Text\base32.txt -Unformatted
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
			ParameterSetName = "ByteInput",
			ValueFromPipeline,
			ValueFromPipelineByPropertyName,
			Mandatory,
			Position = 0,
			HelpMessage = 'Byte array to Base32 encode.'
		)]
		[ValidateNotNullOrEmpty()]
		[Alias('ByteArray', 'Data')]
		[Byte[]]$Bytes,

		[Parameter(
			ParameterSetName = "StringInput",
			ValueFromPipeline,
			ValueFromPipelineByPropertyName,
			Mandatory,
			Position = 0,
			HelpMessage = 'String to Base32 encode.'
		)]
		[ValidateNotNullOrEmpty()]
		[Alias('Plaintext', 'Text')]
		[String]$String,

		[Parameter(
			ParameterSetName = "FileInput",
			ValueFromPipeline,
			ValueFromPipelineByPropertyName,
			Mandatory,
			Position = 0,
			HelpMessage = 'File to Base32 encode.'
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
		[Alias('Filename', 'FullName', 'File')]
		[Fileinfo]$InFile,

		[Parameter(
			ParameterSetName = "StringInput",
			ValueFromPipeline,
			ValueFromPipelineByPropertyName,
			Position = 1,
			HelpMessage = 'Output result to specified file as UTF8-NoBOM text instead of console.'
		)]

		[Parameter(ParameterSetName = "ByteInput")]
		[Parameter(ParameterSetName = "FileInput")]
		[ValidateNotNullOrEmpty()]
		[Fileinfo]$OutFile,

		[Parameter(
			ParameterSetName = "ByteInput",
			HelpMessage = 'Do not format output string using header/footer and line breaks.')]
		[Parameter(ParameterSetName = "StringInput")]
		[Parameter(ParameterSetName = "FileInput")]
		[ValidateNotNullOrEmpty()]
		[Switch]$Unformatted,

		[Parameter(
			ParameterSetName = "ByteInput",
			HelpMessage = 'Use extended Base32 Hex charset instead of standard Base32 charset.')]
		[Parameter(ParameterSetName = "StringInput")]
		[Parameter(ParameterSetName = "FileInput")]
		[ValidateNotNullOrEmpty()]
		[Switch]$Base32Hex,

		[Parameter(
			ParameterSetName = "FileInput",
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
			ParameterSetName = "ByteInput",
			HelpMessage = 'When returning a string instead of a file, return a raw string instead of PSObject; applies to both console and file output modes.'
		)]
		[Parameter(ParameterSetName = "StringInput")]
		[Parameter(ParameterSetName = "FileInput")]
		[ValidateNotNullOrEmpty()]
		[Switch]$Raw
	)

	Begin {
		If ($Base32Hex) {
			[String]$B32CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
			[String]$B32Name = "Base32-Hex"
		} Else {
			[String]$B32CHARSET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
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
			If ($Raw) {
				Write-Warning "File output mode specified; Parameter '-Raw' will be ignored."
			}
		}
		Switch ($PSCmdlet.ParameterSetName) {
			"ByteInput" {
				[System.IO.Stream]$InputStream = New-Object -TypeName System.IO.MemoryStream(, $Bytes)
				Break
			}
			"StringInput" {
				[System.IO.Stream]$InputStream = New-Object -TypeName System.IO.MemoryStream(, [System.Text.Encoding]::ASCII.GetBytes($String))
				Break
			}
			"FileInput" {
				[System.IO.Stream]$InputStream = [System.IO.File]::Open($InFile.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
				Break
			}
		}
		[System.Object]$Timer = [System.Diagnostics.Stopwatch]::StartNew()
		[System.Object]$BinaryReader = New-Object -TypeName System.IO.BinaryReader($InputStream)
		[System.Object]$Base32Output = New-Object -TypeName System.Text.StringBuilder
		If (-Not $Unformatted) {
			[void]$Base32Output.Append("$($B32Header)`r`n")
		}
		Try {
			While ([System.Byte[]]$BytesRead = $BinaryReader.ReadBytes(5)) {
				[System.Boolean]$AtEnd = ($BinaryReader.BaseStream.Length -eq $BinaryReader.BaseStream.Position)
				[System.UInt16]$ByteLength = $BytesRead.Length
				If ($ByteLength -lt 5) {
					[System.Byte[]]$WorkingBytes = , 0x00 * 5
					[System.Buffer]::BlockCopy($BytesRead, 0, $WorkingBytes, 0, $ByteLength)
					[System.Array]::Resize([ref]$BytesRead, 5)
					[System.Buffer]::BlockCopy($WorkingBytes, 0, $BytesRead, 0, 5)
				}
				[System.Char[]]$B32Chars = , 0x00 * 8
				[System.Char[]]$B32Chunk = , "=" * 8
				$B32Chars[0] = ($B32CHARSET[($BytesRead[0] -band 0xF8) -shr 3])
				$B32Chars[1] = ($B32CHARSET[(($BytesRead[0] -band 0x07) -shl 2) -bor (($BytesRead[1] -band 0xC0) -shr 6)])
				$B32Chars[2] = ($B32CHARSET[($BytesRead[1] -band 0x3E) -shr 1])
				$B32Chars[3] = ($B32CHARSET[(($BytesRead[1] -band 0x01) -shl 4) -bor (($BytesRead[2] -band 0xF0) -shr 4)])
				$B32Chars[4] = ($B32CHARSET[(($BytesRead[2] -band 0x0F) -shl 1) -bor (($BytesRead[3] -band 0x80) -shr 7)])
				$B32Chars[5] = ($B32CHARSET[($BytesRead[3] -band 0x7C) -shr 2])
				$B32Chars[6] = ($B32CHARSET[(($BytesRead[3] -band 0x03) -shl 3) -bor (($BytesRead[4] -band 0xE0) -shr 5)])
				$B32Chars[7] = ($B32CHARSET[$BytesRead[4] -band 0x1F])
				[Array]::Copy($B32Chars, $B32Chunk, ([Math]::Ceiling(($ByteLength / 5) * 8)))
				If ($BinaryReader.BaseStream.Position % 8 -eq 0 -and -Not $Unformatted -and -not $AtEnd) {
					[void]$Base32Output.Append($B32Chunk)
					[void]$Base32Output.Append("`r`n")
				} Else {
					[void]$Base32Output.Append($B32Chunk)
				}
			}
			If (-Not $Unformatted) {
				[void]$Base32Output.Append("`r`n$($B32Footer)")
			}
			[String]$Base32Result = $Base32Output.ToString()
			$Base32ResultObject = New-Object -TypeName PSObject
			If ($OutFile) {
				[System.IO.File]::WriteAllLines($OutFile.FullName, $Base32Result, (New-Object -TypeName System.Text.UTF8Encoding $False))
				$Base32ResultObject = $OutFile
			} Else {
				If ($Raw) {
					$Base32ResultObject = $Base32Result
				} Else {
					Add-Member -InputObject $Base32ResultObject -MemberType 'NoteProperty' -Name 'Base32EncodedData' -Value $Base32Result
				}
			}
			Return ($Base32ResultObject)
		} Catch {
			Write-Error "Exception: $($_.Exception.Message)"
			Break
		} Finally {
			$BinaryReader.Close()
			$BinaryReader.Dispose()
			$InputStream.Close()
			$InputStream.Dispose()
			$Timer.Stop()
			[String]$TimeLapse = "Base32 encode completed after $($Timer.Elapsed.Hours) hours, $($Timer.Elapsed.Minutes) minutes, $($Timer.Elapsed.Seconds) seconds, $($Timer.Elapsed.Milliseconds) milliseconds"
			Write-Verbose $TimeLapse
		}
	}

	End {}
}