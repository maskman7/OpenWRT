#!/bin/bash
# DIY 脚本 part2：feeds 安装完成、make defconfig 之前执行。

# 1. 默认管理 IP -> 192.168.18.254
sed -i 's/192.168.1.1/192.168.18.254/g' package/base-files/files/bin/config_generate

# 2. 主机名 -> MaskMan7WRT（openwrt 默认主机名为 OpenWrt）
sed -i "s/hostname='OpenWrt'/hostname='MaskMan7WRT'/g" package/base-files/files/bin/config_generate

# 3. 默认主题 -> vantage、默认语言 -> 简体中文（写入 uci-defaults，首启自动生效）
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-default-theme <<'EOF'
#!/bin/sh
uci -q set luci.main.mediaurlbase=/luci-static/vantage
uci -q set luci.main.lang=zh_cn
uci -q commit luci
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-default-theme

# 4. 概览页移除"系统信息"卡片（10_system.js）
STATUS_INC="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include"
rm -f "$STATUS_INC/10_system.js"
find feeds package -type f -name '10_system.js' -path '*view/status/include*' -delete
echo "[part2] 10_system.js 残留数量: $(find feeds package -type f -name '10_system.js' -path '*view/status/include*' | wc -l)"

# 4b. 概览顶端注册 Packet path 流程图卡片（复用 vantage 自带 nftflow；占位 .nft-table 默认 display:none，
#     无空框残留；卡片仅首次 render 返回占位，概览轮询重建 DOM 时返回 null 保留已画好的流程图）
cat > "$STATUS_INC/15_flow.js" <<'FLOWEOF'
'use strict';'require baseclass';
// 概览顶端卡片：复用 vantage 主题自带的 nftflow 流程图（Packet path）。
// nftflow 原本只在 状态→Nftables 页挂载；这里在概览 include 目录注册一张卡片，
// 提供 .nft-table 占位容器后调用其 attach()，流程图主体由 nft 规则数据独立生成。
// 概览会轮询重建卡片 DOM，故本卡片仅首次 render 返回占位，之后返回 null 保留已画好的流程图。
var built = false;
return baseclass.extend({
	title: _('Packet path', 'vantage-theme'),
	render: function() {
		if (built) return null;
		built = true;
		var holder = E('div', { 'class': 'nft-table' }, [E('div', { 'class': 'nft-chains' })]);
		setTimeout(function() {
			var view = document.getElementById('view');
			if (!view) return;
			L.require('vantage-theme.nftflow').then(function(m) { m.attach(view); })
				.catch(function(e) { if (window.console) console.warn('vantage: overview flow', e); });
		}, 80);
		return holder;
	}
});
FLOWEOF

# 5. 显式把 iStore 及其依赖链链接进 package/feeds（兜底：install -a 对子目录 feed 可能漏装）
./scripts/feeds install -p istore luci-app-store luci-lib-taskd taskd luci-lib-xterm || true
