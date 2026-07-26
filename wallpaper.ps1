$config = Get-Content -Path ".\variables.json" -Raw | ConvertFrom-Json

$srcImage = $config.src.Directory + $config.src.image
#$srcImage = ".\img\wim"
$targetImageLocation = $config.target.Disk + $config.target.Directory
#$targetImageLocation = "C:\Users\Public\"
$wallpaperLocation = $targetImageLocation + $config.src.image
#$wallpaperLocation = $targetImageLocation + "wim"
$pathHk = $config.reg.pathHkCurrent
#$pathHk = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
#$pathHk = "HKCU:\Control Panel\Desktop"
$refresh = $config.systemRefresh
#$refresh = 10

while ($true) {
    $type = Read-Host "`nWhat will you do?`n1: Set wallpaper for current user`n2: Set wallpaper for all users`n3: Delete wallpaper for all users`nEnter option"
    if ($type -eq 1) {
        $pathHk = $config.reg.pathHkCurrent
        #$pathHk = "HKCU:\Control Panel\Desktop"
        break
    }
    elseif ($type -in 2, 3) {
        $pathHk = $config.reg.pathHkSystem
        #$pathHk = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        break
    }
    else {
        Write-Host "Invalid input.`n"
    }
}

if ($type -eq 3) {
    try {
        Remove-ItemProperty -Path $pathHk -Name "Wallpaper" -WhatIf -ErrorAction Stop
        Remove-ItemProperty -Path $pathHk -Name "WallpaperStyle" -WhatIf -ErrorAction Stop
        while ($true) {
            $delete = Read-Host "`nDo you want to delete the values? (Y/N)"
            if ($delete -in "Y", "y") {
                Remove-ItemProperty -Path $pathHk -Name "Wallpaper" -ErrorAction Stop
                Remove-ItemProperty -Path $pathHk -Name "WallpaperStyle" -ErrorAction Stop
                Write-Host "Values are deleted."
                break
            }
            elseif ($delete -in "N", "n") {
                Write-Host "Values are not deleted."
                break
            }
            else {
                Write-Host "Invalid input."
            }
        }
    }
    catch {
        Write-Host "Values do not exist."
    }
    finally {
        exit
    }
}
elseif ($type -in 1, 2) {
    # --- Testing ---
    # -- BEFORE RUNNING: Give each picture the same base name and add number after --
    # -- BEFORE RUNNING: Change src.image in variables.json to exclude extention and write the correct base name of the pictures --

    $choice = Read-Host "Wallpaper (number)"
    while ($true) {
        $format = Read-Host "`nFile extention:`n1: .jpg`n2: .png`nChoose value"
        if ($format -eq 1) {
            $format = ".jpg"
            break
        }
        elseif ($format -eq 2) {
            $format = ".png"
            break
        }
        else {
            Write-Host "`nInvalid input."
        }
    }
    $srcImage = $srcImage + $choice + $format
    $wallpaperLocation = $wallpaperLocation + $choice + $format

    # ------------------------------------------------------------------------------------------------------------------------------

    while ($true) {
        $wallpaperStyle = Read-Host "`nStyles for wallpaper:`n0: Centered`n1: Tiled`n2: Stretch`n3: Fit`n4: Fill`n5: Span`nEnter value"
        if ($wallpaperStyle -eq 0) {
            $tileWallpaper = Read-Host "`nWallpaper tiling:`n0: Off`n1: On`nEnter value"
        }
        elseif ($wallpaperStyle -eq 1) {
            $tileWallpaper = 1
        }
        else {
            $tileWallpaper = 0
        }
        if ($wallpaperStyle -notin 0, 1, 2, 3, 4, 5 -or $tileWallpaper -notin 0, 1) {
            Write-Host "Invalid input(s)."
            while ($true) {
                $invalidAbort = Read-Host "Do you want to abort? (Y/N)"
                if ($invalidAbort -in "y", "Y") {
                    Write-Host "Aborted PowerShell script!"
                    exit
                }
                elseif ($invalidAbort -in "n", "N") {
                    break
                }
                else {
                    Write-Host "Invalid input."
                }
            }
        }
        else {
            break
        }
    }
    Copy-Item -Path $srcImage -Destination $targetImageLocation -Force
    $wallpaper = Get-Item $wallpaperLocation
    $wallpaper.Attributes = $wallpaper.Attributes -bor [System.IO.FileAttributes]::Hidden
    Start-Sleep -Milliseconds 100
}
else {
    Write-Host "Unable to perform action(s)."
    exit
}

if (Test-Path $wallpaperLocation) {
    Write-Host "$srcImage copied to $targetImageLocation"
    function Get-WallpaperPath {
        param (
            [Parameter(Mandatory)]
            [string]$WallpaperSpelling
        )
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            $Global:wallpaperPathPresent = Get-ItemPropertyValue -Path $pathHk -Name $WallpaperSpelling
        }
        else {
            $Global:wallpaperPathPresent = Get-ItemProperty -Path $pathHk -Name $WallpaperSpelling.$WallpaperSpelling
        }
    }
    if ($type -eq 1) {
        Set-ItemProperty -Path $pathHk -Name "WallpaperStyle" -Value "$wallpaperStyle"
        Set-ItemProperty -Path $pathHk -Name "TileWallPaper" -Value "$tileWallpaper"
        Set-ItemProperty -Path $pathHk -Name "WallPaper" -Value $wallpaperLocation
        
        Get-WallpaperPath -WallpaperSpelling "WallPaper"
    }
    elseif ($type -eq 2) {
        $key = try {
            Get-Item -Path $pathHk -ErrorAction Stop
        }
        catch {
            New-Item -Path $pathHk -Force
        }
        function Set-WallpaperValues {
            param (
                [Parameter(Mandatory)]
                [string]$KeyName,
                [string]$KeyValue
            )
            try {
                Set-ItemProperty -Path $pathHk -Name $KeyName -Value $KeyValue -ErrorAction Stop
            }
            catch {
                New-ItemProperty -Path $key.PSPath -Name $KeyName -PropertyType String -Value $KeyValue
            }
        }
        Set-WallpaperValues -KeyName "Wallpaper" -KeyValue $wallpaperLocation
        Set-WallpaperValues -KeyName "WallpaperStyle" -KeyValue "$wallpaperStyle"

        Get-WallpaperPath -WallpaperSpelling "Wallpaper"
    }
    else {
        Write-Host "Unable to change wallpaper."
    }

    if ($wallpaperPathPresent -eq $wallpaperLocation -or $type -eq 3) {
        Write-Host "Wallpaper is set.`n$pathHk\WallPaper`n$pathHk\WallpaperStyle`n$pathHk\TileWallpaper`n"
        for ($refreshCount = 1; $refreshCount -le $refresh; $refreshCount++) {
            Write-Host "System refresh $refreshCount/$refresh"
            rundll32.exe user32.dll, UpdatePerUserSystemParameters 1, True
            rundll32.exe user32.dll, UpdatePerUserSystemParameters
            Start-Sleep -Seconds 1
        }
        if ($?) {
            Write-Host "`nSystem is refreshed."
        }
        else {
            Write-Host "`nSystem is unable to refresh."
        }
    }
    else {
        Write-Host "Unable to change wallpaper."
    }
}
else {
    Write-Host "Unable to copy $srcImage to $targetImageLocation."
}
