/**
 * @misty/dsh-pj — 前端状态条（web client）
 * 对话框上方显示「破甲包已装载」徽标 + 技能计数，数据来自 /api/dsh-pj/status。
 */
window.__ModuleLoader__.load({
  id: "@misty/dsh-pj",
  factory: (require) => {
    const React = require("react");
    const inject = ["slots"];

    const BADGE = {
      display: "inline-flex",
      alignItems: "center",
      gap: 6,
      padding: "2px 10px",
      borderRadius: 999,
      fontSize: 12,
      lineHeight: "18px",
      background: "var(--dsw-alias-bg-layer-2)",
      color: "var(--dsw-alias-label-primary)",
      border: "1px solid var(--dsw-alias-border-l1)",
      cursor: "default",
      userSelect: "none",
    };
    const DOT = {
      width: 6,
      height: 6,
      borderRadius: "50%",
      background: "#22c55e",
      flexShrink: 0,
    };

    function PjBadge() {
      const [info, setInfo] = React.useState(null);
      React.useEffect(() => {
        let alive = true;
        fetch("/api/dsh-pj/status")
          .then((r) => (r.ok ? r.json() : null))
          .then((d) => { if (alive) setInfo(d); })
          .catch(() => {});
        return () => { alive = false; };
      }, []);
      if (!info) return null;
      const title = `dsh-pj v${info.version} by ${info.author}\n内置技能 ${info.bundledSkills.length} 个\n已安装 ${info.skillsOnDisk} 个 -> ${info.skillsInstalledAt}`;
      return React.createElement(
        "span",
        { style: BADGE, title },
        React.createElement("span", { style: DOT }),
        `破甲包 ${info.bundledSkills.length} 技能已装载`
      );
    }

    return {
      slots: {
        // 挂在输入区右侧 slot；slot 名以宿主注册表为准，未命中时由用户在
        // 插件管理里看到模块已加载即可（不影响 host 侧功能）
        "conversation.input.right": PjBadge,
      },
    };
  },
});
