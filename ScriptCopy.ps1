param (
    [string]$sourceDir,
    [string]$replicaDir,
    [string]$logFile
)

function Write-Log {
    Param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "${timestamp}: $message"
    Write-Output $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

function Sync-Folders {
    $sourceFiles = Get-ChildItem -Path $sourceDir -Recurse
    $replicaFiles = Get-ChildItem -Path $replicaDir -Recurse

    # Copy new and updated files to the replica
    foreach ($file in $sourceFiles) {
        $relativePath = $file.FullName.Substring($sourceDir.Length)
        $targetPath = Join-Path -Path $replicaDir -ChildPath $relativePath

        if (-not (Test-Path -Path $targetPath) -or ($file.LastWriteTime -gt (Get-Item $targetPath).LastWriteTime)) {
            $targetDir = Split-Path -Path $targetPath -Parent
            if (-not (Test-Path -Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir | Out-Null
                Write-Log "Created directory: $targetDir"
            }

            Copy-Item -Path $file.FullName -Destination $targetPath -Force
            Write-Log "Copied: $($file.FullName) to $targetPath"
        }
    }

    # Remove files and folders not present in the source
    foreach ($file in $replicaFiles) {
        $relativePath = $file.FullName.Substring($replicaDir.Length)
        $sourcePath = Join-Path -Path $sourceDir -ChildPath $relativePath

        if (-not (Test-Path -Path $sourcePath)) {
            Remove-Item -Path $file.FullName -Recurse -Force
            Write-Log "Removed: $($file.FullName)"
        }
    }
}

# Main script execution
try {
    Write-Log "Starting synchronization from '$sourceDir' to '$replicaDir'"
    Sync-Folders
    Write-Log "Synchronization completed successfully."
} catch {
    Write-Log "Error: $_"
}
