
#---------------#
# MAIN FUNCTION #
#---------------#

$lineCounter = 0
$successCounter = 0
$failCounter = 0

$masterFilename = "wcron"

# Executables
$ytDlpExecutable = "$HOME\OneDrive\Projects\tools\yt-dlp-date.ps1"
$galleryDlExecutable = "gallery-dl"

$initialDirectory = $(pwd)

# Check if any config file was provided as an argument.
if (!($args[0]))
{
	Write-Host "No configuration file(s) provided as argument(s). Quitting."
	exit 1
}

foreach ($arg in $args)
{
	if (!(Test-Path -Path $arg -PathType Leaf))
	{
		Write-Host "[SKIPPING] Configuration file `""$arg"`" doesn't exist.`n"
		continue;
	}

	Write-Host "[CONFIG] Using $arg`n"

	foreach ($line in Get-Content $arg)
	{

		# increment the counter. Note: Start this at zero.
		$lineCounter += 1

		# If comment is set to the first character of a string, skip the line. Let the user know.
		if ($line.substring(0, 1) -Match "#")
		{
			Write-Host "[SKIPPING] Comment found at line $lineCounter.`n"
			continue;
		}

		# url is the web page pull requests will be made to.
		$url = $line | foreach-object{($_ -split ",")[0]}; $url = $url.Trim();
		# writePath is the directory wcron will cd, and write to.
		$writePath = $line | foreach-object{($_ -split ",")[1]}; $writePath = $writePath.Trim();
		# executable is the program path or relative path files will be pulled down using.
		$executable = $line | foreach-object{($_ -split ",")[2]}; $executable = $executable.Trim();

		# Check that both executables exist.
		if (!(Test-Path $executable -PathType Leaf) -And !(Get-Command $executable -ErrorAction SilentlyContinue))
		{
			Write-Host $executable "doesn't exist. Ensure it's installed before running $masterFilename."
			$failCounter += 1
			continue;
		}

		# Check if any variables are empty. If so, trigger a syntax error.
		if ((!($url)) -or (!($writePath)) -or (!($executable)))
		{
			Write-Host "line $lineCounter`: config syntax error"
			Write-Host $line
			$failCounter += 1
			continue
		}

		# Check if the write path exists. If not, create it.
		if (!(Test-Path $writePath -PathType Container))
		{
			mkdir $writePath
		}

		# Print a nice title. Add a new line to the end.
		Write-Host "[URL]" $url "`n"

		# Change to the destination directory.
		Set-Location -Path $writePath

		# Depending on the executable used, switch to a certain invocation path.
		switch ($executable)
		{
			"yt-dlp"     { &     $ytDlpExecutable      $url; }
			"gallery-dl" { & $galleryDlExecutable -D . $url; }
			default      { &          $executable      $url; }
		}

		$successCounter += 1

		# Go back to your initial directory.
		Set-Location -Path $initialDirectory

	}

	Write-Host "`n[TOTALS]`nTotal URLs successfully processed: $successCounter"
	Write-Host "Total URLs failed to process: $failCounter"

}
