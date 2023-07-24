# Steam Launcher changing default audio to Aux (Game) input
# temporarily during game launch and then back to normal default
# Mostly needed for Unreal Engine games (Rocket League, Fall Guys, etc.)

# Added a decent bit of error checking, but not exhaustive

# [Set,Get]-AudioDevice needs to be installed
# https://github.com/frgnca/AudioDeviceCmdlets
$script:DefaultVariables = $(Get-Variable).Name
$script:GameStarted = $false
$script:SteamDialog = $false
$script:SteamError = $false
$script:GameAlreadyRunning = $false
$script:GameReturnCode = $null
$script:GameRetries = 2
$script:GameRetryCount = $script:GameRetries
$script:ProcessName = "rocketleague"
$script:GameName = "Rocket League"
$script:SteamAppID = "252950"
function Clear-ScriptVariables
{
    ((Compare-Object -ReferenceObject (Get-Variable).Name -DifferenceObject $Script:DefaultVariables).InputObject) |
        Where-Object {$_ -ne "_" -and $_ -ne "PSItem"} |
        ForEach-Object {
            Remove-Variable -Name $_ -Scope Script -ErrorAction SilentlyContinue
        }
}

function Set-NewPlaybackDevice
{
    $script:DefaultPlayback = Get-AudioDevice -Playback
    Write-Output "Getting Audio Devices and setting default to VM Aux Input"
    (Get-AudioDevice -list |Where-Object {$_.Name -match "VoiceMeeter Aux Input"} |Set-AudioDevice).Name
}
function Set-PreviousPlaybackDevice
{
    Write-Output "Setting default audio device back to normal default."
    ($script:DefaultPlayback | Set-AudioDevice).Name
}
function Test-Game{
    $try = 0
    if (Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue)
    {
        while ($try -lt 3 -and (Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue))
        {
            $try++
            Write-Warning "$script:GameName already running, waiting 10 seconds (Attempt $try of 3)"
            Start-Sleep -Seconds 20
        }
        if ($try -ge 3)
        {
            $script:GameAlreadyRunning = $true
            Write-Error "$script:GameName never closed, cannot start a new instance"
            Throw "$script:GameName never closed, cannot start a new instance."
        }
    }
}
function Start-Game
{
    $try = 0
    # run if when game isn't started yet
    if (! (Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue))
    {
        Write-Output "Launching $script:GameName via Steam Launcher"
        &"C:\Program Files (x86)\Steam\steam.exe" -applaunch $script:SteamAppID
    }
    # If game is current running, wait for it to close (try 3 times, ~30 seconds total)
    else
    {
        while ($try -lt 3 -and (Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue))
        {
            $try++
            Start-Sleep -Seconds 10
            if (! (Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue))
            {
                Write-Output "Trying to Launch $script:GameName via Steam Launcher... re-attempt #$try"
                &"C:\Program Files (x86)\Steam\steam.exe" -applaunch $script:SteamAppID
            }
        }
    }
}
function Test-GameAge
{
    if (Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue)
    {
        Write-Output "$script:GameName process detected, waiting for process to reach the age of 20 seconds"
        while ( ((Get-Date) - (Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue).StartTime) -lt (New-Timespan -Seconds 20) -or !(Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue))
        {
            Start-Sleep -Seconds 1
        }
    }
}

# End Functions


# Begin actual script
Try
{
    Test-Game -ErrorAction Stop
    # Set-NewPlaybackDevice
    while ($script:GameRetryCount -gt 0 -and $script:GameStarted -eq $false -and $script:SteamDialog -eq $false -and $script:SteamError -eq $false)
    {
        Write-Output "GameRetryCount: $script:GameRetryCount"
        Start-Game
        $script:GameRetryCount--
        Start-Sleep 10
        $script:SteamDialog = [bool](Get-Process |Where-Object {$_.name -eq "steamwebhelper" -and $_.mainWindowTItle -eq "Steam Dialog"})
        $script:SteamError = [bool](Get-Process |Where-Object {$_.name -eq "steam" -and $_.mainWindowTItle -eq "Steam - Error"})
        $script:GameStarted = [bool](Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue)
        if ($script:SteamDialog -eq $true -or $script:SteamError -eq $true)
        {
            Write-Warning "$script:GameName did not start, Check Steam Dialog window!"
            pause
        }
        Test-GameAge
    }
}
Catch
{
    if ($script:GameAlreadyRunning -eq $false)
    {
        Write-Warning $PSItem.ToString()
    }
}
Finally
{
    if ($script:DefaultPlayback)
    {
        # Set-PreviousPlaybackDevice
    }
    elseif ($script:GameStarted -eq $false -and $script:GameAlreadyRunning -eq $false)
    {
        Write-Warning "$script:GameName did not start correctly after $($GameRetries+1) attempts"
        pause
    }
    elseif ($script:GameAlreadyRunning -eq $true)
    {
        Write-Warning "$script:GameName was already running and did not exit in 30 seconds"
        pause
    }
    if (!(Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue))
    {
        Write-Warning "$script:GameName started, but then exited prematurely. Check for issues."
        pause
    }

    Clear-ScriptVariables
}
