[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('add', 'list', 'run')]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Arg1,

    [Parameter(Position = 2)]
    [string]$Arg2
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptRoot 'channels.json'
$ytDlpPath = Join-Path $scriptRoot 'yt-dlp.exe'

function Ensure-ConfigFile {
    if (-not (Test-Path $configPath)) {
        @() | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8
    }
}

function Read-Channels {
    Ensure-ConfigFile

    $raw = Get-Content -Path $configPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $parsed = $raw | ConvertFrom-Json
    if ($null -eq $parsed) {
        return @()
    }

    if ($parsed -is [System.Array]) {
        return $parsed
    }

    return @($parsed)
}

function Save-Channels {
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]$Channels
    )

    $Channels | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8
}

function Show-Help {
@"
Uzycie:
  .\yt-archive.ps1 add <url_kanalu> [alias_folderu]
  .\yt-archive.ps1 list
  .\yt-archive.ps1 run [alias_folderu]

Opis:
  add  - dodaje kanal YouTube do listy archiwizacji.
         alias_folderu jest opcjonalny i pozwala nadpisac nazwe folderu.
  list - wyswietla zapisane kanaly.
  run  - uruchamia yt-dlp dla wszystkich kanalow albo tylko jednego aliasu.

Przyklady:
  .\yt-archive.ps1 add "https://www.youtube.com/@BogumilStorchMedia" storch
  .\yt-archive.ps1 list
  .\yt-archive.ps1 run
  .\yt-archive.ps1 run storch
"@
}

function Get-DefaultAliasFromUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        $uri = [System.Uri]$Url
        $lastSegment = ($uri.AbsolutePath.TrimEnd('/') -split '/')[-1]
    }
    catch {
        $lastSegment = $Url
    }

    if ([string]::IsNullOrWhiteSpace($lastSegment)) {
        $lastSegment = 'kanal'
    }

    return ($lastSegment -replace '[^a-zA-Z0-9_-]', '_').ToLowerInvariant()
}

function Add-Channel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [string]$Alias
    )

    if (-not $Alias) {
        $Alias = Get-DefaultAliasFromUrl -Url $Url
    }

    $channels = Read-Channels

    if ($channels | Where-Object { $_.alias -eq $Alias }) {
        throw "Kanal z aliasem '$Alias' juz istnieje."
    }

    if ($channels | Where-Object { $_.url -eq $Url }) {
        throw 'Ten URL juz istnieje na liscie.'
    }

    $newChannel = [PSCustomObject]@{
        alias = $Alias
        url = $Url
    }

    $updated = @($channels + $newChannel)
    Save-Channels -Channels $updated

    Write-Host "Dodano kanal: [$Alias] $Url"
}

function List-Channels {
    $channels = Read-Channels

    if (-not $channels -or $channels.Count -eq 0) {
        Write-Host 'Brak kanalow na liscie. Uzyj komendy add.'
        return
    }

    Write-Host 'Zapisane kanaly:'
    $i = 1
    foreach ($channel in $channels) {
        Write-Host ("{0}. [{1}] {2}" -f $i, $channel.alias, $channel.url)
        $i++
    }
}

function Invoke-ChannelArchive {
    param(
        [Parameter(Mandatory = $true)]
        $Channel
    )

    if (-not (Test-Path $ytDlpPath)) {
        throw "Nie znaleziono yt-dlp.exe pod sciezka: $ytDlpPath"
    }

    $outputTemplate = "D:/youtube-dl/{0}/%(uploader)s - %(title)s - %(id)s - %(upload_date)s.%(ext)s" -f $Channel.alias

    $arguments = @(
        '--output', $outputTemplate,
        '--continue',
        '--retries', '4',
        '--download-archive', 'downloaded.txt',
        '--ignore-errors',
        '--user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
        '--cookies-from-browser', 'firefox',
        '--extractor-args', 'youtubetab:ignoreerrors',
        '-f', 'bestvideo[height<=380]+bestaudio/best[height<=380]',
        $Channel.url
    )

    Write-Host "\n=== Archiwizacja kanalu [$($Channel.alias)] ==="
    & $ytDlpPath @arguments

    if ($LASTEXITCODE -ne 0) {
        throw "yt-dlp zakonczyl dzialanie kodem: $LASTEXITCODE"
    }
}

function Run-Archive {
    param(
        [string]$Alias
    )

    $channels = Read-Channels
    if (-not $channels -or $channels.Count -eq 0) {
        throw 'Brak kanalow do archiwizacji. Dodaj kanal komenda add.'
    }

    $selected = $channels

    if ($Alias) {
        $selected = $channels | Where-Object { $_.alias -eq $Alias }
        if (-not $selected) {
            throw "Nie znaleziono kanalu o aliasie: $Alias"
        }
    }

    foreach ($channel in $selected) {
        Invoke-ChannelArchive -Channel $channel
    }
}

if (-not $Command) {
    Show-Help
    exit 0
}

switch ($Command) {
    'add' {
        if (-not $Arg1) {
            throw 'Dla komendy add podaj URL kanalu.'
        }

        Add-Channel -Url $Arg1 -Alias $Arg2
    }
    'list' {
        List-Channels
    }
    'run' {
        Run-Archive -Alias $Arg1
    }
}
