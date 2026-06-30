$ErrorActionPreference = "Stop"

# CHANGE THESE PATHS
$ObsidianRoot = "C:\Users\Zema\Documents\Obsidian\Coding"
$BlogRoot = "C:\Users\Zema\Code\coding-blog"

$ObsidianPosts = Join-Path $ObsidianRoot "Posts"
$BlogPosts = Join-Path $BlogRoot "src\content\blog"

$ObsidianAssets = Join-Path $ObsidianRoot "Attachments\Posts"
$BlogAssets = Join-Path $BlogRoot "src\content\blog\images"

# Only these folders will be mirrored
$Languages = @("en", "ru")

# PUBLISHING OPTIONS
$PublishToGit = $args -contains "--publish"
$BuildFromSrc = $args -contains "--build"
function Invoke-RobocopyMirror {
  param(
    [Parameter(Mandatory=$true)]
    [string]$Source,

    [Parameter(Mandatory=$true)]
    [string]$Destination
  )

  if (-not (Test-Path $Source)) {
    Write-Error "Source path does not exist: $Source"
    return
  }

  New-Item -ItemType Directory -Path $Destination -Force | Out-Null

  robocopy $Source $Destination /MIR /XD ".obsidian" ".trash" ".git" /XF ".DS_Store" "Thumbs.db" "desktop.ini" "ehthumbs.db" "IconCache.db" | Out-Null
  
  if ($LASTEXITCODE -ge 7) {
    Write-Error "Robocopy failed with exit code $LASTEXITCODE"
  }

  $global:LASTEXITCODE = 0
}

Write-Host "1. Syncing posts from Obsidian to Blog..."
foreach ($Language in $Languages) {
    $SourcePath = Join-Path $ObsidianPosts $Language
    $DestinationPath = Join-Path $BlogPosts $Language

    Write-Host "Syncing language: $Language"
    Invoke-RobocopyMirror -Source $SourcePath -Destination $DestinationPath
}

if (Test-Path $ObsidianAssets) {
    Write-Host "2. Syncing assets from Obsidian to Blog..."

    foreach ($Language in $Languages) {
        $SourcePath = Join-Path $ObsidianAssets $Language
        $DestinationPath = Join-Path $BlogAssets $Language

        if (Test-Path $SourcePath) {
            Write-Host "Syncing assets for language: $Language"
            Invoke-RobocopyMirror -Source $SourcePath -Destination $DestinationPath
        }
    }
} else {
    Write-Warning "2. Obsidian assets directory does not exist: $ObsidianAssets"
}

if ($BuildFromSrc) {
    Write-Host "3. Building the blog..."
    Set-Location $BlogRoot
    pnpm build
} else {
    Write-Host "Skipping build. Use --build flag to enable."
}

if ($PublishToGit) {
    Write-Host "4. Git status:"
    git status --short

    Write-Host "5. Staging public blog content..."
    git add src/content/posts src/assets/images/posts

    $ChangedFiles = git diff --cached --name-only
    if ([string]::IsNullOrWhiteSpace($ChangedFiles)) {
        Write-Host "No changes detected. Exiting."
        exit 0
    }

    Write-Host "Changed files:"
    $ChangedFiles | ForEach-Object { Write-Host $_ }

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    git commit -m "Publish blog posts with titles: $ChangedFiles`nTimestamp: $Timestamp"
    git push

    Write-Host "Done! Blog posts have been published and pushed to the repository."
} else {
    Write-Host "Skipping Git publish. Use --publish flag to enable."
}