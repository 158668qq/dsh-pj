/**
 * @misty/dsh-pj v0.1.0 — DSH 破甲懒人包插件版（作者 misty）
 *
 * 功能：
 *  ① 首次启动把内置 skills/（151 个技能包）安装到 ~/.dsh/skills（已存在则跳过，
 *     不覆盖用户改动；可用 /pj sync 强制同步）
 *  ② 注册 pj_status 工具：返回插件状态与技能清单
 *  ③ 注册 /pj 命令：status / sync / prompt（读取 prompts/ 下的破甲提示词）
 *  ④ prompts/ 与 shield-protocol.md、AGENTS.md 随包分发，路径可由工具取回
 */
import { existsSync, mkdirSync, readdirSync, cpSync, statSync, readFileSync } from "node:fs";
import path from "node:path";
import os from "node:os";

export const name = "dsh-pj";

export const inject = ["tools", "commands", "webServer"];

const HOME = process.env.DSH_HOME || path.join(os.homedir(), ".dsh");
const SKILLS_DST = path.join(HOME, "skills");
const PLUGIN_ROOT = path.dirname(new URL(import.meta.url, "file://").pathname).replace(/^\/([A-Za-z]:)/, "$1");

function skillsSrc() {
	return path.join(PLUGIN_ROOT, "skills");
}

function listSkills() {
	const src = skillsSrc();
	if (!existsSync(src)) return [];
	return readdirSync(src, { withFileTypes: true })
		.filter((d) => d.isDirectory() && existsSync(path.join(src, d.name, "SKILL.md")))
		.map((d) => d.name);
}

function syncSkills(force = false) {
	const src = skillsSrc();
	const names = listSkills();
	let installed = 0, skipped = 0;
	mkdirSync(SKILLS_DST, { recursive: true });
	for (const n of names) {
		const from = path.join(src, n);
		const to = path.join(SKILLS_DST, n);
		if (!force && existsSync(path.join(to, "SKILL.md"))) { skipped++; continue; }
		cpSync(from, to, { recursive: true, force: true });
		installed++;
	}
	return { installed, skipped, total: names.length, dst: SKILLS_DST };
}

export function apply(ctx) {
	// ── 首次自动安装技能（不覆盖已有）──────────────────────────────
	let firstSync = null;
	try {
		if (!existsSync(SKILLS_DST) || readdirSync(SKILLS_DST).length === 0) {
			firstSync = syncSkills(false);
		}
	} catch { /* 权限问题不阻塞启动 */ }

	// ── 工具 ────────────────────────────────────────────────────────
	const statusTool = {
		name: "pj_status",
		description: "返回 dsh-pj 插件状态：技能安装情况、内置提示词文件清单、版本信息。",
		parameters: {
			type: "object",
			properties: {
				action: {
					type: "string",
					enum: ["status", "sync"],
					description: "status=只读状态；sync=强制同步技能包到 ~/.dsh/skills（覆盖同名）",
				},
			},
			additionalProperties: false,
		},
		execute(args = {}) {
			if (args.action === "sync") {
				const r = syncSkills(true);
				return { ok: true, action: "sync", ...r };
			}
			const promptsDir = path.join(PLUGIN_ROOT, "prompts");
			const prompts = existsSync(promptsDir) ? readdirSync(promptsDir) : [];
			const dstNames = existsSync(SKILLS_DST) ? readdirSync(SKILLS_DST, { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => d.name) : [];
			return {
				ok: true,
				plugin: "@misty/dsh-pj",
				version: "0.1.0",
				author: "misty",
				bundledSkills: listSkills(),
				skillsInstalledAt: SKILLS_DST,
				skillsOnDisk: dstNames.length,
				firstRunInstall: firstSync,
				prompts,
				shieldProtocol: existsSync(path.join(PLUGIN_ROOT, "shield-protocol.md")),
				agentsMd: existsSync(path.join(PLUGIN_ROOT, "AGENTS.md")),
			};
		},
	};

	// ── 命令 ────────────────────────────────────────────────────────
	const pjCommand = async (argv = []) => {
		const sub = (argv[0] || "status").toLowerCase();
		if (sub === "sync") {
			const r = syncSkills(true);
			return `[dsh-pj] 技能同步完成：安装 ${r.installed}，共 ${r.total} -> ${r.dst}`;
		}
		if (sub === "prompt") {
			const key = argv[1] || "cold-coffee";
			const f = path.join(PLUGIN_ROOT, "prompts", `${key}.md`);
			if (!existsSync(f)) {
				const list = existsSync(path.join(PLUGIN_ROOT, "prompts")) ? readdirSync(path.join(PLUGIN_ROOT, "prompts")) : [];
				return `[dsh-pj] 未找到提示词 ${key}。可用：${list.join(", ")}`;
			}
			const text = readFileSync(f, "utf8");
			return text.length > 12000 ? text.slice(0, 12000) + "\n...（截断，完整见 " + f + "）" : text;
		}
		const st = statusTool.execute({});
		return [
			`[dsh-pj] v${st.version} by ${st.author}`,
			`内置技能: ${st.bundledSkills.length} 个`,
			`已安装位置: ${st.skillsInstalledAt}（磁盘上 ${st.skillsOnSkillsOnDisk ?? st.skillsOnDisk} 个目录）`,
			`提示词: ${st.prompts.join(", ") || "无"}`,
			`用法: /pj status | /pj sync | /pj prompt <cold-coffee|operator-config-v5>`,
		].join("\n");
	};

	const register = (svc) => {
		if (!svc) return;
		if (typeof svc.define === "function") {
			try { svc.define(statusTool); } catch { /* defineTool 形态不同时忽略 */ }
			try { svc.define("pj", pjCommand); } catch { /* */ }
			return;
		}
		if (typeof svc.addTool === "function") svc.addTool(statusTool);
		if (typeof svc.addCommand === "function") svc.addCommand("pj", pjCommand);
	};

	// 作用域服务注入形态兼容：ctx.services.* 或直接 ctx.*
	register(ctx.services?.tools ?? ctx.tools);
	register(ctx.services?.commands ?? ctx.commands);

	// ── HTTP API ────────────────────────────────────────────────────
	const web = ctx.services?.webServer ?? ctx.webServer;
	try {
		const router = web?.router;
		if (router?.get) {
			router.get("/api/dsh-pj/status", (c) => c.json(statusTool.execute({})));
		}
	} catch { /* web 不可用时静默 */ }

	return { name, version: "0.1.0" };
}
