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

# 4. 概览页移除"系统信息"卡片（10_system.js）；Packet path 流程图保留在 状态→Nftables 页
STATUS_INC="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include"
rm -f "$STATUS_INC/10_system.js"
find feeds package -type f -name '10_system.js' -path '*view/status/include*' -delete
echo "[part2] 10_system.js 残留数量: $(find feeds package -type f -name '10_system.js' -path '*view/status/include*' | wc -l)"
