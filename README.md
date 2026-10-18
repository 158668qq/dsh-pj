# @misty/dsh-pj

DSH 破甲懒人包插件版 · 作者 **misty** · v0.1.0

把 `SusuAIOverclock` 破甲懒人包（skills + prompts + 协议材料）打成单个标准 DSH 插件。

## 内容

- `skills/` — 151 个技能包（eni-* / coldbrew-* / competition-* / web-pentest /
  reverse-engineering / pwn-chain / radare2 / 西宫影安老版本脱修 等），
  首次启动自动安装到 `~/.dsh/skills`（不覆盖已有目录）。
- `prompts/` — cold-coffee.md、operator-config-v5.md
- `shield-protocol.md` / `AGENTS.md` — 常驻执行层配置材料
- `lib/index.js` — host 侧：`pj_status` 工具 + `/pj` 命令 + `/api/dsh-pj/status`
- `lib/client.js` — 前端状态条徽标

## 安装

### 一条命令（GitHub，推荐）

仓库推到 GitHub 后（假设 `misty/dsh-pj`）：

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/misty/dsh-pj/main/install.ps1 | iex"
```

卸载：

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/misty/dsh-pj/main/install.ps1 | iex" -Uninstall
```

脚本自动完成：从 GitHub 拉包 → 装到 `~/.dsh/plugins/@misty/dsh-pj` → 语法校验 →
写入 profile 的 `dsh.profile.bundles`（自动备份原 package.json）→ 提示重启。
也支持本地目录直接 `-File install.ps1`。

### A. 拷进 profile

```powershell
$dst = "$env:USERPROFILE\.dsh\profiles\node_modules\@misty\dsh-pj"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item "D:\DSH\dsh-pj\*" $dst -Recurse -Force
```

然后把 `"@misty/dsh-pj"` 追加进
`$env:USERPROFILE\.dsh\profiles\web\package.json` 的 `dsh.profile.bundles` 数组，
重启 DSH、刷新浏览器。

### B. external plugin + patch

```powershell
Copy-Item "D:\DSH\dsh-pj" "$env:USERPROFILE\.dsh\plugins\@misty\dsh-pj" -Recurse -Force
```

`cordis.patch.yml` 已随包附带。

### C. npm（发布后）

```powershell
cd "$env:USERPROFILE\.dsh\profiles"
npm install @misty/dsh-pj --no-save
```

## 发布到 GitHub 的仓库结构

直接把 `D:\DSH\dsh-pj\` 整个目录作为仓库根推送即可（install.ps1 已在根）：

```powershell
cd D:\DSH\dsh-pj
git init; git add -A; git commit -m "dsh-pj v0.1.0"
git remote add origin https://github.com/misty/dsh-pj.git
git push -u origin main
```

```
dsh-pj/                     ← 仓库根
├─ install.ps1              ← 一条命令入口（远程拉包 + 装配 + 卸载）
├─ package.json
├─ cordis.patch.yml
├─ lib/{index.js, client.js}
├─ skills/ (151 个)
├─ prompts/
├─ shield-protocol.md / AGENTS.md
├─ README.md / LICENSE
```

## 使用

| 入口 | 说明 |
|---|---|
| `/pj status` | 查看技能安装状态 |
| `/pj sync` | 强制同步内置技能到 `~/.dsh/skills`（覆盖同名） |
| `/pj prompt cold-coffee` | 输出内置破甲提示词 |
| 工具 `pj_status` | agent 可调用，action=status/sync |
| `GET /api/dsh-pj/status` | HTTP 状态端点 |

## 校验

```powershell
cd D:\DSH\dsh-pj
node --check lib/index.js && node --check lib/client.js
```
