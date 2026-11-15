#!/bin/bash
# DIY 脚本 part2：feeds 安装完成、make defconfig 之前执行。

# 1. 默认管理 IP -> 192.168.18.254
sed -i 's/192.168.1.1/192.168.18.254/g' package/base-files/files/bin/config_generate

# 2. 主机名 -> MaskMan7WRT（openwrt 默认主机名为 OpenWrt）
sed -i "s/hostname='OpenWrt'/hostname='MaskMan7WRT'/g" package/base-files/files/bin/config_generate

# 3. 默认主题 -> vantage（写入 uci-defaults，首启自动生效）
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-default-theme <<'EOF'
#!/bin/sh
uci -q set luci.main.mediaurlbase=/luci-static/vantage
uci -q commit luci
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-default-theme
