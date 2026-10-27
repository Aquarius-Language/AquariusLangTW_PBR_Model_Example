param([string]$編譯器 = '', [switch]$桌面,
    [switch]$Android, [switch]$APK
)
$ErrorActionPreference = 'Stop'
if (-not $編譯器) {
    $本機編譯器 = Join-Path (Split-Path $PSScriptRoot) 'AquariusLangTW/compiler/AquariusCli/bin/Release/net8.0/aqua.dll'
    $已安裝 = Get-Command aqua -ErrorAction SilentlyContinue
    $編譯器 = if (Test-Path -LiteralPath $本機編譯器) { $本機編譯器 } elseif ($已安裝) { $已安裝.Source } else { throw '請指定新版星泉編譯器：-編譯器 完整路徑。' }
}
$執行階段 = 'dotnet'
if ($編譯器.EndsWith('.dll')) {
    $本機執行階段 = Join-Path $env:USERPROFILE '.dotnet/dotnet.exe'
    if (Test-Path -LiteralPath $本機執行階段) { $執行階段 = $本機執行階段 }
}
function 執行編譯器([string[]]$參數) {
    if ($編譯器.EndsWith('.dll')) { & $執行階段 $編譯器 @參數 } else { & $編譯器 @參數 }
    if ($LASTEXITCODE -ne 0) { throw '星泉建置失敗。' }
}
$原主控台輸出編碼 = [Console]::OutputEncoding
$原輸出編碼 = $OutputEncoding
Push-Location $PSScriptRoot
try {
    [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
    $OutputEncoding = [Console]::OutputEncoding
    $來源 = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.aqua' | Sort-Object Name | ForEach-Object FullName)
    執行編譯器 (@('build') + $來源 + @('--root','.','--entry','main.aqua','--assets','assets','-o','pbr_models.wasm'))
    執行編譯器 @('build','pbr_models.wasm','--target','web','-o','web')
    if ($桌面) {
        執行編譯器 @('build','pbr_models.wasm','--target','windows','-o','dist/pbr_models.exe')
    }
    Write-Output '完成：pbr_models.wasm 與 ./web。'

    if ($Android -or $APK) {
        $AndroidOutput = 'dist/android.apk'
        執行編譯器 @('build','pbr_models.wasm','--target','android','-o',$AndroidOutput) | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Android 建置失敗。' }
    }
} finally {
    [Console]::OutputEncoding = $原主控台輸出編碼
    $OutputEncoding = $原輸出編碼
    Pop-Location
}
