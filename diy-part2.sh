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

# 3b. Docker 加速器（首启写入 dockerd uci；国内直连 Docker Hub 超时，需走镜像源）
cat > package/base-files/files/etc/uci-defaults/99-docker-mirror <<'EOF'
#!/bin/sh
[ -f /etc/config/dockerd ] || exit 0
uci -q delete dockerd.globals.registry_mirrors
uci -q add_list dockerd.globals.registry_mirrors='https://docker.m.daocloud.io'
uci -q add_list dockerd.globals.registry_mirrors='https://docker.1ms.run'
uci -q commit dockerd
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-docker-mirror

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

# 5. iStore 链由 feeds install -a 自动链接（part1 已接 istore feed，.config 已勾 store 链）；
#    无需在此手动 feeds install 兜底。官方 luci-app-package-manager 共存作兜底。

# 6. 首启清理运行时无效第三方 apk 源：
#    part1 克隆 vantage/alist/mosdns 源码仅用于编译进固件；官方 snapshot 仓库没有对应
#    aarch64_cortex-a53/<feed>/packages.adb 目录，运行时 apk update 会对这三行报 EOF/404。
#    已编入固件的包不受影响，这里只把 distfeeds.list 里的第三方源行删掉。
cat > package/base-files/files/etc/uci-defaults/99-remove-thirdparty-feeds <<'EOF'
#!/bin/sh
F=/etc/apk/repositories.d/distfeeds.list
[ -f "$F" ] || exit 0
sed -i -E '\#/(alist|mosdns|vantage)/packages\.adb#d' "$F"
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-remove-thirdparty-feeds

# 7. iStore（B 方案）：去掉 luci-app-store 对 GNU tar 的硬依赖，改用 busybox tar。
#    store 脚本仅用 tar -c/-czf/-zxf/-xz/-C，busybox tar 均可替代；GNU tar 不编入，
#    避免 master apk 构建下 tar 未被 defconfig 选中而把 store 连带剔除。
STORE_MK="$(find feeds package/feeds -path '*luci-app-store/Makefile' 2>/dev/null | head -n1)"
if [ -n "$STORE_MK" ]; then
	sed -i 's/ +tar//' "$STORE_MK"
	echo "[part2] store Makefile 去 tar 依赖: $STORE_MK"
	grep '^LUCI_DEPENDS=' "$STORE_MK"
else
	echo "[part2] 警告: 未找到 luci-app-store/Makefile，istore feed 可能未拉取，store 将不编入。"
fi
