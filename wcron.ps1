
#---------------#
# MAIN FUNCTION #
#---------------#

# Start this at zero. It starts iterating when we enter the main program loop.
$lineCounter = 0
$successCounter = 0
$failCounter = 0

# The name of the main source file (the one you're reading).
$masterFilename = "wcron"

# Executables
#
# Non-explicitly defined executables are supported. They're called using the
# default case.
$ytDlpExecutable = "$HOME\OneDrive\Projects\tools\yt-dlp-date.ps1"
$galleryDlExecutable = "gallery-dl"

# You'll eventually move back to this when file processing in complete.
$initialDirectory = $(pwd)

# Check if any config file was provided as an argument.
if (!($args[0]))
{
	Write-Host "No configuration file(s) provided as argument(s). Quitting."
	exit 1
}

#------------------#
# CONFIG FILE LOOP #
#------------------#

foreach ($arg in $args)
{
	if (!(Test-Path -Path $arg -PathType Leaf))
	{
		Write-Host "[ERROR] Configuration file `""$arg"`" doesn't exist.`n"
		continue;
	}

	Write-Host "[WARNING] Using $arg`n"

	#----------------#
	# FILE LINE LOOP #
	#----------------#

	foreach ($line in Get-Content $arg)
	{

		# Increment the current line counter.
		$lineCounter += 1

		# If comment is set to the first character of a string, skip the line. Let the user know.
		if ($line.substring(0, 1) -Match "#")
		{
			Write-Host "[WARNING] Comment found at line $lineCounter.`n"
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
			Write-Host "[ERROR] `"$executable`" doesn't exist. Ensure it's installed before running $masterFilename."
			$failCounter += 1
			continue;
		}

		# Check if any variables are empty. If so, trigger a syntax error.
		if ((!($url)) -or (!($writePath)) -or (!($executable)))
		{
			Write-Host "[ERROR] line $lineCounter`: config syntax error"
			Write-Host $line
			# Iterate the fail total counter.
			$failCounter += 1
			continue
		}

		# Check if the write path exists. If not, create it.
		if (!(Test-Path $writePath -PathType Container)) { mkdir $writePath }

		# Print a nice title.
		Write-Host "[-- $url --]"

		# Change to the destination directory.
		Set-Location -Path $writePath

		# Depending on the executable used, switch to a certain invocation path.
		switch ($executable)
		{
			"yt-dlp"     { &     $ytDlpExecutable      $url; }
			"gallery-dl" { & $galleryDlExecutable -D . $url; }
			default      { &          $executable      $url; }
		}

		# Iterate the success total counter.
		$successCounter += 1

		# Go back to your initial directory.
		Set-Location -Path $initialDirectory

	}

	# Tally messages.
	Write-Host "[WARNING] Total URLs successfully processed: $successCounter"
	Write-Host "[WARNING] Total URLs failed to process: $failCounter"

}
