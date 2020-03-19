param (
    [string]$projectId,
    [string]$dir
)

Write-Host "$projectId"


# get workDir
$workDir = Get-Location
$workDir = "$workDir/$dir"
cd $workDir
Write-Host $workDir

# check parameters

if (!$projectId)
{
    Write-Host "ERROR!!! Need param projectId!"
    return;
}

if (!(Test-Path "$workDir/package.json" -PathType Leaf))
{
    Write-Host "ERROR!!! File package.json not found!"
    return;
}
 
$disk = "c:"
$isError = 0

$folderBackup = "$disk\node_backup";
if (!(Test-Path $folderBackup))
{
    Write-Host "folder $folderBackup not found. Will be created"
    mkdir $folderBackup
}

$folderProject = "$folderBackup\$projectId";
if (!(Test-Path $folderProject))
{
    Write-Host "folder $folderProject not found. Will be created"
    mkdir $folderProject
}



# get versions

if (Test-Path "$folderProject\version.txt" -PathType Leaf)
{
    $currVersion = Get-Content "$folderProject\version.txt"
}
else
{
    $currVersion = "null"

    Write-Host "file version.txt not found. Will be created"
    New-Item -Path $folderProject -Name "version.txt" -ItemType "file" -Value $currVersion
}

$nextVersion = Get-FileHash "$workDir\package.json" -Algorithm MD5
$nextVersion = $nextVersion.Hash

# equls version

Write-Host "version cache: $currVersion, version package: $nextVersion"

if ($currVersion -eq $nextVersion)
{
    if (Test-Path "$folderProject\node_modules")
    {
        Write-Host "Versions match. Packets will be taken from the cache"
        $installPackges = 0;
    }
    else
    {
        Write-Host "Versions match but folder 'node_modules' not found. Packages will be installed."
        $installPackges = 1;
    }
}
else
{
    if (Test-Path "$folderProject\node_modules")
    {
        Write-Host "versions don't match. the cache will be cleared"
        Remove-Item -LiteralPath "$folderProject\node_modules" -Force -Recurse
    }
    else
    {
        Write-Host "Versions don't match. Cache is empty."
    }

    $installPackges = 1;
}



if ($installPackges -eq 1)
{
    Write-Host "package installation"
    npm install
}
else
{
    Write-Host "copy packages from cache"
    Move-Item -Path "$folderProject\node_modules" -Destination "$workDir"
}



# Build app !!!!!!
Try
{
    Write-Host "Building app."
    npm run prod
}
Catch
{
    [system.exception]
    Write-Host "ERROR!!! Building app."
    $isError = 1;
}


# save cache
if ($isError -eq 0)
{
    Move-Item -Path "$workDir\node_modules" -Destination "$folderProject"
    Out-File -FilePath "$folderProject\version.txt" -InputObject $nextVersion
}
