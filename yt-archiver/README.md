# YT Channel Archiver (PowerShell + yt-dlp)

Skrypt `yt-archive.ps1` automatyzuje archiwizacje kanalow YouTube przez `yt-dlp` na Windows 11 (PowerShell).

## Co potrafi

- dodac kanal do listy (`add`),
- pokazac liste kanalow (`list`),
- uruchomic archiwizacje jednego lub wszystkich kanalow (`run`).

Kazdy kanal jest pobierany z ustawieniami zgodnymi z podanym wzorcem komendy.

## Wymagania

1. Windows 11 + PowerShell (5.1 lub 7+).
2. `yt-dlp.exe` w tym samym folderze co `yt-archive.ps1`.
3. Firefox (dla `--cookies-from-browser firefox`).
4. Katalog docelowy, np. `D:/youtube-dl`.

## Struktura plikow

W folderze `yt-archiver`:

- `yt-archive.ps1` – glowny skrypt,
- `channels.json` – lista kanalow (tworzy sie automatycznie),
- `downloaded.txt` – archiwum pobran yt-dlp (tworzone przez yt-dlp),
- `yt-dlp.exe` – binarka yt-dlp.

## Uzycie

### Dodanie kanalu

```powershell
.\yt-archive.ps1 add "https://www.youtube.com/@BogumilStorchMedia" storch
```

`storch` to alias folderu i bedzie uzyty w sciezce:
`D:/youtube-dl/storch/%(uploader)s - %(title)s - %(id)s - %(upload_date)s.%(ext)s`

Jesli nie podasz aliasu, skrypt sprobuje wyliczyc go z URL.

### Lista kanalow

```powershell
.\yt-archive.ps1 list
```

### Archiwizacja wszystkich kanalow

```powershell
.\yt-archive.ps1 run
```

### Archiwizacja jednego kanalu

```powershell
.\yt-archive.ps1 run storch
```

## Parametry yt-dlp uzywane przez skrypt

Skrypt uruchamia `yt-dlp.exe` z argumentami:

- `--output "D:/youtube-dl/<alias>/%(uploader)s - %(title)s - %(id)s - %(upload_date)s.%(ext)s"`
- `--continue`
- `--retries 4`
- `--download-archive downloaded.txt`
- `--ignore-errors`
- `--user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0"`
- `--cookies-from-browser firefox`
- `--extractor-args youtubetab:ignoreerrors`
- `-f "bestvideo[height<=380]+bestaudio/best[height<=380]"`
- `<url_kanalu>`

Dzieki `downloaded.txt` kolejne uruchomienia pobieraja tylko nowe materialy.
