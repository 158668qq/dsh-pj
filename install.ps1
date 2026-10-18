# ============================================================
#  @misty/dsh-pj 一键安装（GitHub 远程或本地目录均可）
#  远程一条命令：
#    powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/158668qq/dsh-pj/master/install.ps1 | iex"
#  本地：
#    powershell -ExecutionPolicy Bypass -File install.ps1
#  卸载：
#    powershell -ExecutionPolicy Bypass -File install.ps1 -Uninstall
# ============================================================
param(
    [string]$Profile = 'web',
    [string]$Repo = '158668qq/dsh-pj',
    [string]$Branch = 'master',
    [switch]$Uninstall
)
$ErrorActionPreference = 'Stop'
$dsHome     = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $HOME '.dsh' }
$profilesDir = Join-Path $dsHome 'profiles'
$pluginsDir = Join-Path $dsHome 'plugins\@misty\dsh-pj'
$pkgName    = '@misty/dsh-pj'
$stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'

function Write-Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "[OK] $m" -ForegroundColor Green }

# ── 取插件源文件：本地（脚本同目录）或从 GitHub 拉临时包 ──
$src = $PSScriptRoot
$isRemote = -not (Test-Path (Join-Path $src 'package.json'))
if ($isRemote) {
    Write-Step "从 GitHub 拉取 $Repo@$Branch"
    $tmp = Join-Path $env:TEMP "dsh-pj-$stamp"
    $zip = "$tmp.zip"
    $archive = "https://codeload.github.com/$Repo/zip/refs/heads/$Branch"
    Invoke-WebRequest -Uri $archive -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $inner = Get-ChildItem $tmp -Directory | Select-Object -First 1
    if ($inner.Name -eq 'dsh-pj') { $src = $inner.FullName }
    else {
        $cand = Get-ChildItem $tmp -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'package.json') } | Select-Object -First 1
        if (-not $cand) { throw "压缩包里没找到 package.json" }
        $src = $cand.FullName
    }
    Write-Ok "已解压到 $src"
}

if ($Uninstall) {
    Write-Step '卸载'
    foreach ($p in @($pluginsDir, (Join-Path $profilesDir "node_modules\$pkgName"))) {
        if (Test-Path $p) {
            $item = Get-Item $p -Force
            if ($item.LinkType) { [System.IO.Directory]::Delete($p) }
            else { Remove-Item $p -Recurse -Force }
            Write-Ok "已删除 $p"
        }
    }
    $pkgPath = Join-Path $profilesDir "$Profile\package.json"
    if (Test-Path $pkgPath) {
        node -e "const f=process.argv[1];const j=require(f);if(j.dsh?.profile?.bundles){j.dsh.profile.bundles=j.dsh.profile.bundles.filter(b=>b!=='$pkgName');require('fs').writeFileSync(f,JSON.stringify(j,null,2))}" $pkgPath
        Write-Ok "已从 $pkgPath 的 bundles 移除 $pkgName"
    }
    Write-Ok '卸载完成，重启 DSH 生效'
    exit 0
}

# ── 安装 ──
Write-Step '安装插件到 external plugins 目录'
New-Item -ItemType Directory -Force -Path (Split-Path $pluginsDir -Parent) | Out-Null
if (Test-Path $pluginsDir) {
    $item = Get-Item $pluginsDir -Force
    if ($item.LinkType) { [System.IO.Directory]::Delete($pluginsDir) }
    else { Remove-Item $pluginsDir -Recurse -Force }
}
Copy-Item $src $pluginsDir -Recurse -Force
Write-Ok "插件已就位: $pluginsDir"

# 校验
node --check (Join-Path $pluginsDir 'lib\index.js')
if ($LASTEXITCODE -ne 0) { throw 'lib/index.js 语法检查失败' }
Write-Ok '语法检查通过'

# 同步进 profile bundles
$pkgPath = Join-Path $profilesDir "$Profile\package.json"
New-Item -ItemType Directory -Force -Path (Split-Path $pkgPath -Parent) | Out-Null
if (-not (Test-Path $pkgPath)) {
    @{ name = "dsh-profile-$Profile"; private = $true; dependencies = @{}
       dsh = @{ profile = @{ bundles = @('@deepseek-ai/dsh-base', '@deepseek-ai/dsh-web-app', $pkgName) } } } |
        ConvertTo-Json -Depth 8 | Set-Content $pkgPath -Encoding UTF8
    Write-Ok "已创建 $pkgPath"
} else {
    Copy-Item $pkgPath "$pkgPath.bak-$stamp"
    node -e "const fs=require('fs');const f=process.argv[1];const j=JSON.parse(fs.readFileSync(f,'utf8'));j.dsh=j.dsh||{};j.dsh.profile=j.dsh.profile||{};j.dsh.profile.bundles=j.dsh.profile.bundles||[];if(!j.dsh.profile.bundles.includes('@deepseek-ai/dsh-base'))j.dsh.profile.bundles.unshift('@deepseek-ai/dsh-base');if(!j.dsh.profile.bundles.includes('@deepseek-ai/dsh-web-app'))j.dsh.profile.bundles.push('@deepseek-ai/dsh-web-app');if(!j.dsh.profile.bundles.includes('$pkgName'))j.dsh.profile.bundles.push('$pkgName');fs.writeFileSync(f,JSON.stringify(j,null,2))" $pkgPath
    Write-Ok "$pkgName 已加入 bundles（备份: $pkgPath.bak-$stamp）"
}

Write-Host ''
Write-Ok "安装完成。完全退出 DSH 再启动，浏览器刷新一次即可。"
Write-Host '    验证: /pj status   |   GET /api/dsh-pj/status'
