#
# sfml-nuget.ps1
#

#########################

# Some customisation variables
$pkg_prefix = "sfml." # Prefix of packages. If you change this variable, do not remove the reference to the SFML!!!
$keep_sources = $true # Use $true to keep source files or $false to delete them, $true by default
$keep_autopkg = $false # Keep autopkg files, $false by default
$use_old_include_workaround = $false # Use in case of errors with the new one, $false by default
$add_docs = $false # Add docs in system module, $false by default

# SFML packages variables
$sfml_owners =	"username" # Packages "owner" name. Replace username with your name
$sfml_tags = "sfml, native, CoApp" # Tags for your packages, "sfml, native, CoApp" by default

# SFML nuget packages 'generation' variables
$sfml_module_list = "system", "window", "graphics", "audio", "network" # SFML packages, that will be generated
$sfml_version = "2.5.0" # Min supported version - 2.2
$sfml_platforms = "x86", "x64"
$sfml_toolchains = "v120", "v140", "v141"
$sfml_configurations = "debug", "release"

#########################

# It's not recommended to change these values
$sfml_download_url = "http://www.sfml-dev.org/files/"
$sfml_authors = "Laurent Gomila"
$sfml_licence_url = "http://www.sfml-dev.org/license.php"
$sfml_project_url = "http://www.sfml-dev.org"
$sfml_icon_url = "http://www.sfml-dev.org/images/sfml-icon.png"
$sfml_require_license_acceptance = "false"
$sfml_summary = "SFML provides a simple interface to the various components of your PC, to ease the development of games and multimedia applications. It is composed of five modules: system, window, graphics, audio and network."
$sfml_description = "SFML provides a simple interface to the various components of your PC, to ease the development of games and multimedia applications. It is composed of five modules: system, window, graphics, audio and network.
With SFML, your application can compile and run out of the box on the most common operating systems: Windows, Linux, Mac OS X and soon Android & iOS.
SFML has official bindings for the C and .Net languages. And thanks to its active community, it is also available in many other languages such as Java, Ruby, Python, Go, and more."
$sfml_changelog = "https://www.sfml-dev.org/changelog.php#sfml-$sfml_version"

# Don't change these values
$dir = Split-Path -Path $MyInvocation.MyCommand.Path
$coapp_download_url = "http://coapp.org/pages/releases.html"
$linking = "static", "dynamic"
$to_msvc = @{ "v100" = "vc10"; "v110" = "vc11"; "v120" = "vc12"; "v140" = "vc14"; "v141" = "vc15" }
$to_bits = @{ "x86" = "32"; "Win32" = "32" ; "x64" = "64" }
$dependencies = @{ "window" = "system"; "graphics" = ("window", "system"); "audio" = "system"; "network" = "system" }

#########################

function PackageHeader($pkgName)
{
	$currentYear = (Get-Date).Year
	return "configurations {
	UserPlatformToolset {
		// Needed because autopackage lacks VS2015 support
			key = ""PlatformToolset"";
			choices: ""v120, v140, v141"";
	};
}

nuget {
	nuspec {
		id = $pkg_prefix$pkgname;
		title: $pkg_prefix$pkgname;
		version: $sfml_version;
		authors: { $sfml_authors };
		owners: { $sfml_owners };
		licenseUrl: ""$sfml_licence_url"";
		projectUrl: ""$sfml_project_url"";
		iconUrl: ""$sfml_icon_url"";
		requireLicenseAcceptance: $sfml_require_license_acceptance;
		summary: ""$sfml_summary"";
		description: @""$sfml_description"";
		releaseNotes: ""$sfml_changelog"";
		copyright: Copyright $currentYear;
		tags: ""$sfml_tags"";
	}

	#output-packages {
		default : `${pkgname};
		redist : `${pkgname}.redist;
		symbols : `${pkgname}.symbols;
	}"
}

function AddMainFile()
{
	$datas = ""
	foreach($p in $sfml_platforms)
	{
		foreach($v in $sfml_toolchains)
		{
			foreach($c in $sfml_configurations)
			{
				$datas += "		[$p,$v,$c] {"
				$libfile = "			lib += `${SRC}bin\$p\$v\$c\lib\sfml-main"
				if ($c -eq "debug")
				{
					$libfile += "-d"
				}
				$libfile += ".lib;"
				$datas += "
$libfile
		}

"
			}
		}
	}
	return $datas
}

function AddFiles($pkgName)
{
	$datas = ""
	foreach($p in $sfml_platforms)
	{
		foreach($v in $sfml_toolchains)
		{
			foreach($c in $sfml_configurations)
			{
				foreach($l in $linking)
				{
					$datas += "		[$p,$v,$c,$l] {"
					$libfile = "			lib += `${SRC}bin\$p\$v\$c\lib\sfml-$pkgName"
					$binfile = "			bin += `${SRC}bin\$p\$v\$c\bin\sfml-$pkgName"
					if ($l -eq "static")
					{
						$libfile += "-s"
					}
					if ($c -eq "debug")
					{
						$libfile += "-d"
						$binfile += "-d"
					}
					$libfile += ".lib;"
					$binfile += "-2.dll;"
					$datas += "
$libfile"

					if ($l -eq "dynamic")
					{
						$datas += "
$binfile"
					}
					$datas += "
		}
"
				}
			}
		}
	}
	return $datas
}

function AddDependencies($pkgName)
{
	if (-not $dependencies.ContainsKey($pkgName))
	{
		return ""
	}
	$datas += "

	dependencies {
		packages : {"
	foreach($p in $dependencies[$pkgName])
	{
		$datas += "
			$pkg_prefix$p/$sfml_version,"
	}
	$datas = $datas.TrimEnd(",")
	$datas += "
		};
	}"
	return $datas
}

function GeneratePackage($pkgName)
{

	$autopkg = PackageHeader($pkgName)
	$autopkg += AddDependencies($pkgName)
	$autopkg += "

	files {
		#defines {
			SRC = ..\sources\;
		}

"
	if ($pkgName -eq "system")
	{
		$autopkg += "		nestedInclude: {
			#destination = `${d_include}$include_workaround;
			""`${SRC}include\**""
		};

"
		if ($add_docs -ne $false)
		{
			$autopkg += "		docs: {
			`${SRC}doc\**\*
		};

"
		}
		$autopkg += AddMainFile
	}
	$autopkg += AddFiles($pkgName)
	if($pkgName -eq "system")
	{
		$autopkg += "		[x86] {
			lib += `${SRC}ext\lib\x86\*.lib;
			bin += `${SRC}ext\bin\x86\*.dll;
		}

		[x64] {
			lib += `${SRC}ext\lib\x64\*.lib;
			bin += `${SRC}ext\bin\x64\*.dll;
		}
"
	}
	$autopkg += "	};

	targets {
		Defines += HAS_SFML;
		[static]
			Defines += SFML_STATIC;
	}
}"
	$autopkg | Out-File "$pkg_prefix$pkgName.autopkg"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
	param([string]$zipfile, [string]$outpath)
	[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function CreateDirectory($dirName)
{
	if (-not (Test-Path $dirName)){
		New-Item -ItemType Directory -Force -Path "$dirName" | Out-Null
	}
}

function CreateFile($fileName)
{
	if (-not (Test-Path $fileName)){
		New-Item -ItemType File -Force -Path "$fileName" | Out-Null
	}
}

#########################
########## Main #########
#########################

# Checking on installed CoApp Tools
try
{
	Show-CoAppToolsVersion | Out-Null
}
catch
{
	Write-Host -ForegroundColor Yellow "You need CoApp tools to build NuGet packages!"
	Read-Host "Press ENTER to open CoApp website or Ctrl-C to exit..."
	Start-Process $coapp_download_url
	Exit
}

# For old include workaround
if ($use_old_include_workaround -ne $false)
{
	$include_workaround = ""
}

CreateDirectory("$dir\temp")
CreateDirectory("$dir\sources")
CreateDirectory("$dir\sources\include")
CreateDirectory("$dir\distfiles")
CreateDirectory("$dir\build")

if ($add_docs -ne $false) {
	CreateDirectory("$dir\sources\doc")
}

# For old include Workaround
if ($use_old_include_workaround)
{
	CreateFile("$dir\sources\include\delete.me")
}

foreach($p in $sfml_platforms)
{
	foreach ($t in $sfml_toolchains)
	{
		$filename = "SFML-$sfml_version-windows-" + $to_msvc[$t] + "-" + $to_bits[$p] + "-bit.zip"
		$outfile = "$dir\distfiles\$filename"
		if (-not (Test-Path $outfile))
		{
			$fileuri = $sfml_download_url + $filename
			$webclient = New-Object System.Net.WebClient
			$downloaded = $false
			while ($downloaded -eq $false)
			{
				try
				{
					Write-Host "`nDownloading $filename..."
					$webclient.DownloadFile($fileuri, $outfile)
					$downloaded = $true
					Write-Host -ForegroundColor Green "$filename downloaded"
				}
				catch
				{
					Write-Warning "An error occurred while downloading the file $fileuri"
					Write-Host -ForegroundColor Yellow "Press ENTER to try again or Ctrl-C to exit..."
					Read-Host
				}
			}
		}
		Write-Host "`nExtracting $filename..."
		Remove-Item "$dir\temp\*" -Recurse | Out-Null # Clearing directory to avoid Unzip exceptions
		Unzip "$outfile" "$dir\temp"
		$zip = "$dir\temp\SFML-$sfml_version"

		CreateDirectory("$dir\sources\ext\lib\$p\")
		CreateDirectory("$dir\sources\ext\bin\$p\")
		CreateDirectory("$dir\sources\bin\$p\$t\debug\bin\")
		CreateDirectory("$dir\sources\bin\$p\$t\release\bin\")
		CreateDirectory("$dir\sources\bin\$p\$t\debug\lib\")
		CreateDirectory("$dir\sources\bin\$p\$t\release\lib\")

		Copy-Item "$zip\include\*" "$dir\sources\include\" -Force -Recurse | Out-Null
		if ($add_docs -ne $false)
		{
			Copy-Item "$zip\doc\*" "$dir\sources\doc\" -Force -Recurse | Out-Null
		}
		Move-Item "$zip\bin\sfml-*-d-2.dll" "$dir\sources\bin\$p\$t\debug\bin\" -Force | Out-Null
		Move-Item "$zip\bin\sfml-*.dll" "$dir\sources\bin\$p\$t\release\bin\" -Force | Out-Null
		Move-Item "$zip\bin\*.dll" "$dir\sources\ext\bin\$p\" -Force | Out-Null
		Move-Item "$zip\lib\sfml-*-d.lib" "$dir\sources\bin\$p\$t\debug\lib\" -Force | Out-Null
		Move-Item "$zip\lib\sfml-*.lib" "$dir\sources\bin\$p\$t\release\lib\" -Force | Out-Null
		Move-Item "$zip\lib\*.lib" "$dir\sources\ext\lib\$p\" -Force | Out-Null
		Remove-Item "$zip" -Recurse | Out-Null
	}
}

# New include workaround
if ($use_old_include_workaround -eq $false)
{
	if ((Get-ChildItem -Path "$dir\sources\include\" -File -Force).Count -gt 0)
	{
		$include_workaround = ""
	}
	else
	{
		$include_workaround = "SFML\"
	}
}

Write-Host
Set-Location -Path "$dir\build"
foreach($module in $sfml_module_list)
{
	Write-Host "Generating $pkg_prefix$module.autopkg..."
	GeneratePackage($module)
}
Set-Location -Path ..

New-Item -ItemType Directory -Force -Path "$dir\repository" | Out-Null
Set-Location -Path "$dir\repository"
Get-ChildItem "../build/" -Filter *.autopkg | `
Foreach-Object{
	Write-Host "`nGenerating NuGet package from $_...`n"
	Write-NuGetPackage ..\build\$_ | Out-Null
	if ($keep_autopkg -eq $false) {
		Remove-Item ..\build\$_ | Out-Null
	}
}
Write-Host "`nCleaning..."
Remove-Item *.symbols.* | Out-Null
Set-Location -Path ..
Remove-Item "$dir\temp" -Recurse | Out-Null
if ($keep_autopkg -eq $false) { Remove-Item "$dir\build" -Recurse | Out-Null }
if ($use_old_include_workaround -ne $false) { Remove-Item "$dir\sources\include\delete.me" | Out-Null } # For old include workaround
if ($keep_sources -ne $true) { Remove-Item "$dir\sources" -Recurse | Out-Null }
Write-Host -ForegroundColor Green "Done! Your packages are available in $dir\repository"
Pause