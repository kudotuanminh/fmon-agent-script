param (
    [Alias('h')]
    [switch]$help,

    [Alias('v')]
    [switch]$verbose,

    [Alias('c')]
    [string]$config
)

$TELEGRAF_VER = "1.31.2"
$TELEGRAF_URL = "https://dl.influxdata.com/telegraf/releases/telegraf-" + $TELEGRAF_VER + "_windows_amd64.zip"

function usage() {
    Write-Output ""
    Write-Output "Usage: .\$(split-path $PSCommandPath -Leaf) [OPTIONS]"
    Write-Output ""
    Write-Output "Options:"
    Write-Output " -h, -help           Display this help message"
    Write-Output " -v, -verbose        Enable verbose mode"
    Write-Output " -c, -config URL     Specify a config file URL"
}

if ($help) {
    usage
    exit
}

$VERBOSE_MODE = $verbose
$CONFIG_FILE_URL = $config

$AdminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
$isAdmin = $currentPrincipal.IsInRole($AdminRole)

if (!$isAdmin) {
    Write-Output "This script requires Administrator privileges to install packages."
    Write-Output "You will be prompted for UAC."
    $ScriptPath = $script:MyInvocation.MyCommand.Path
    $Params = $PSBoundParameters
    $arg = ""
    if (-not [string]::IsNullOrEmpty($Params)) {
        Foreach ($key in $params.Keys) {
            $value = $params[$key]
            $arg += "-$key $value"
        }
    }
    Start-Process -FilePath powershell.exe -ArgumentList @("-NoExit -File `"$ScriptPath`" $arg") -Verb runas
    exit
}

Clear-Host
Write-Output " ________ ,---.    ,---.    ,-----.    ,---.   .--."
Write-Output "|        ||    \  /    |  .'  .-,  '.  |    \  |  |"
Write-Output "|   .----'|  ,  \/  ,  | / ,-.|  \ _ \ |  ,  \ |  |"
Write-Output "|  _|____ |  |\_   /|  |;  \  '_ /  | :|  |\_ \|  |"
Write-Output "|_( )_   ||  _( )_/ |  ||  _``,/ \ _/  ||  _( )_\  |"
Write-Output "(_ o._)__|| (_ o _) |  |: (  '\_/ \   ;| (_ o _)  |"
Write-Output "|(_,_)    |  (_,_)  |  | \ ```"/  \  ) / |  (_,_)\  |"
Write-Output "|   |     |  |      |  |  '. \_/`````".'  |  |    |  |"
Write-Output "'---'     '--'      '--'    '-----'    '--'    '--'"
Write-Output ""
Write-Output "Telegraf installation script."
Write-Output "----------------------------------------"

if ($VERBOSE_MODE) {
    Write-Output "Verbose mode enabled."
    $winVer = Get-CimInstance CIM_OperatingSystem | Select-Object -ExpandProperty Caption
    $winBuild = Get-CimInstance CIM_OperatingSystem | Select-Object -ExpandProperty BuildNumber
    Write-Output "Detected OS: $winVer build $winBuild"
}

Push-Location
Set-Location $([System.IO.Path]::GetTempPath())

if ($VERBOSE_MODE) {
    Write-Output "----------------------------------------"
    Write-Output "Downloading Telegraf..."
}
Invoke-WebRequest -Uri $TELEGRAF_URL -UseBasicParsing -OutFile "telegraf.zip"
if ($VERBOSE_MODE) {
    Write-Output "Telegraf downloaded at '$(Get-Location)\telegraf.zip'."
}

if ($VERBOSE_MODE) {
    Write-Output "----------------------------------------"
    Write-Output "Extracting Telegraf..."
}
Expand-Archive -Path "telegraf.zip" -DestinationPath .\telegraf
$telegrafdir = "telegraf\telegraf-" + $TELEGRAF_VER + "\telegraf.*"
xcopy /hievry $telegrafdir "C:\Program Files\telegraf\"
if ($VERBOSE_MODE) {
    Write-Output "Telegraf extracted to C:\Program Files\telegraf."
}

if ($VERBOSE_MODE) {
    Write-Output "----------------------------------------"
    Write-Output "Configuring Telegraf..."
}
switch ($CONFIG_FILE_URL) {
    "" {
        Write-Output "No config file specified. Will use default configuration."
        break
    }
    Default {
        Invoke-WebRequest -Uri $CONFIG_FILE_URL -UseBasicParsing -OutFile "telegraf.conf"
        if ($VERBOSE_MODE) {
            Write-Output "Telegraf config downloaded at '$(Get-Location)\telegraf.conf'."
        }
        Copy-Item -Path "telegraf.conf" -Destination "C:\Program Files\telegraf\telegraf.conf"
        if ($VERBOSE_MODE) {
            Write-Output "Telegraf configured."
        }
    }
}

if ($VERBOSE_MODE) {
    Write-Output "----------------------------------------"
    Write-Output "Installing Telegraf service..."
}
&"C:\Program Files\telegraf\telegraf.exe" --service install
&"C:\Program Files\telegraf\telegraf.exe" --service start
if ($VERBOSE_MODE) {
    Write-Output "Telegraf service installed"
}
Pop-Location
