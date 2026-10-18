# ============================================================
#  @misty/dsh-pj 一键安装 — DSH 桌面端（Electron）专用
#  适配桌面端真实结构：~/.dsh/plugins 实体 + profiles/desktop
#  pnpm workspace file: 依赖 + dsh.profile.bundles
#
#  远程一条命令：
#    powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/158668qq/dsh-pj/master/install.ps1 | iex"
#  本地：
#    powershell -ExecutionPolicy Bypass -File install.ps1
#  卸载：
#    powershell -ExecutionPolicy Bypass -File install.ps1 -Uninstall
# ============================================================
param(
    [string]$Repo = '158668qq/dsh-pj',
    [string]$Branch = 'master',
    [switch]$Uninstall
)
$ErrorActionPreference = 'Stop'
$dsHome      = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $HOME '.dsh' }
$pluginsRoot = Join-Path $dsHome 'plugins'
$pluginDir   = Join-Path $pluginsRoot '@misty\dsh-pj'
$desktopDir  = Join-Path $dsHome 'profiles\desktop'
$pkgName     = '@misty/dsh-pj'
$depSpec     = 'file:../../plugins/@misty/dsh-pj'
$stamp       = Get-Date -Format 'yyyyMMdd-HHmmss'

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
    $cand = Get-ChildItem $tmp -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'package.json') } | Select-Object -First 1
    if (-not $cand) { throw '压缩包里没找到 package.json' }
    $src = $cand.FullName
    Write-Ok "已解压到 $src"
}

if ($Uninstall) {
    Write-Step '卸载'
    $desktopPkg = Join-Path $desktopDir 'package.json'
    if (Test-Path $desktopPkg) {
        Copy-Item $desktopPkg "$desktopPkg.bak-$stamp"
        node -e "const fs=require('fs');const f=process.argv[1];const j=JSON.parse(fs.readFileSync(f,'utf8'));if(j.dependencies)delete j.dependencies['$pkgName'];if(j.dsh?.profile?.bundles)j.dsh.profile.bundles=j.dsh.profile.bundles.filter(b=>b!=='$pkgName');fs.writeFileSync(f,JSON.stringify(j,null,2)+'\n')" $desktopPkg
        Write-Ok "已从 desktop profile 移除 $pkgName"
        Push-Location $desktopDir
        try { pnpm install --prefer-offline 2>&1 | Select-Object -Last 1 | Out-Host } finally { Pop-Location }
    }
    if (Test-Path $pluginDir) {
        Remove-Item $pluginDir -Recurse -Force
        Write-Ok "已删除 $pluginDir"
    }
    Write-Ok '卸载完成，重启 DSH 桌面端生效'
    exit 0
}

# ── 安装 ──
Write-Step '安装插件实体到 ~/.dsh/plugins/@misty/dsh-pj'
New-Item -ItemType Directory -Force -Path (Split-Path $pluginDir -Parent) | Out-Null
if (Test-Path $pluginDir) {
    $item = Get-Item $pluginDir -Force
    if ($item.LinkType) { [System.IO.Directory]::Delete($pluginDir) }
    else { Remove-Item $pluginDir -Recurse -Force }
}
# 拷内容（不含 .git）
robocopy $src $pluginDir /E /NFL /NDL /NJH /NJS /XD .git | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy 失败 exit=$LASTEXITCODE" }
Write-Ok "插件实体已就位: $pluginDir"

# 校验
node --check (Join-Path $pluginDir 'lib\index.js')
if ($LASTEXITCODE -ne 0) { throw 'lib/index.js 语法检查失败' }
Write-Ok '语法检查通过'

if (-not (Test-Path $desktopDir)) { throw "桌面端 profile 不存在: $desktopDir（先启动一次 DSH 桌面端）" }
$desktopPkg = Join-Path $desktopDir 'package.json'
if (-not (Test-Path $desktopPkg)) { throw "desktop package.json 缺失: $desktopPkg" }

Write-Step "把 $pkgName 注册进 desktop profile"
Copy-Item $desktopPkg "$desktopPkg.bak-$stamp"
node -e "const fs=require('fs');const f=process.argv[1];const j=JSON.parse(fs.readFileSync(f,'utf8'));j.dependencies=j.dependencies||{};j.dependencies['$pkgName']='$depSpec';j.dsh=j.dsh||{profile:{}};j.dsh.profile=j.dsh.profile||{};j.dsh.profile.bundles=j.dsh.profile.bundles||[];if(!j.dsh.profile.bundles.includes('$pkgName'))j.dsh.profile.bundles.push('$pkgName');fs.writeFileSync(f,JSON.stringify(j,null,2)+'\n')" $desktopPkg
Write-Ok "package.json 已更新（备份: $desktopPkg.bak-$stamp）"

Write-Step 'pnpm install（hoisted 模式，链接插件实体）'
Push-Location $desktopDir
try {
    $env:CI = 'true'
    pnpm install --prefer-offline --config.confirmModulesPurge=false --no-frozen-lockfile 2>&1 | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" }
    if ($LASTEXITCODE -ne 0) {
        # pnpm 10 已知问题：既有 file:D:/ 绝对路径依赖会被错误拼接（ENOENT）。junction + 相对路径修复
        Write-Host '[INFO] pnpm 失败，尝试修复既有 file:D:/ 绝对路径依赖后重试' -ForegroundColor Yellow
        $mirrorLink = Join-Path $desktopDir 'dsh-our-free-model-mirror'
        if (-not (Test-Path $mirrorLink)) {
            New-Item -ItemType Junction -Path $mirrorLink -Target 'D:\DSH\dsh-our-free-model-mirror' | Out-Null
        }
        node -e "const fs=require('fs');const f=process.argv[1];const j=JSON.parse(fs.readFileSync(f,'utf8'));if(j.dependencies['dsh-our-free-model']==='file:D:/DSH/dsh-our-free-model-mirror')j.dependencies['dsh-our-free-model']='file:dsh-our-free-model-mirror';fs.writeFileSync(f,JSON.stringify(j,null,2)+'\n')" $desktopPkg
        pnpm install --prefer-offline --config.confirmModulesPurge=false --no-frozen-lockfile 2>&1 | Select-Object -Last 2 | ForEach-Object { Write-Host "    $_" }
        if ($LASTEXITCODE -ne 0) { throw "pnpm install 修复后仍失败（exit $LASTEXITCODE）；备份 $desktopPkg.bak-$stamp 可回滚" }
        Write-Ok 'file 依赖修复后安装成功'
    }
} finally { Pop-Location }

# 验证 node_modules 里出现
$mounted = Join-Path $desktopDir "node_modules\@misty\dsh-pj"
if (Test-Path (Join-Path $mounted 'package.json')) {
    Write-Ok "已挂载: $mounted"
} else {
    Write-Host "[WARN] node_modules 里未见 $pkgName，检查 pnpm 输出" -ForegroundColor Yellow
}

Write-Host ''
Write-Ok '安装完成。完全退出 DSH 桌面端再启动即可。'
Write-Host '    验证: /pj status   |   设置 → 插件管理 里看到 @misty/dsh-pj'
