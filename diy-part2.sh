#!/bin/bash
# DIY 脚本 part2：feeds 安装完成、make defconfig 之前执行。

# 0. 移除打不上的 fullcone 补丁
#    master 上游 firewall4 已更新，immortalwrt 自带的 001-fullcone-nat 补丁
#    Hunk#1 对不上源码，导致 firewall4 编译失败；删除后按上游干净源码编译。
#    代价：丢失 FullCone NAT 支持（不影响 Docker 与日常上网）。
rm -f package/network/config/firewall4/patches/001-firewall4-add-support-for-fullcone-nat.patch

# 1. 默认管理 IP -> 192.168.18.254
sed -i 's/192.168.1.1/192.168.18.254/g' package/base-files/files/bin/config_generate

# 2. 主机名 -> MaskMan7WRT（immortalwrt 默认主机名为 ImmortalWrt）
sed -i "s/hostname='ImmortalWrt'/hostname='MaskMan7WRT'/g" package/base-files/files/bin/config_generate

# 3. 默认主题 -> vantage（写入 uci-defaults，首启自动生效）
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-default-theme <<'EOF'
#!/bin/sh
uci -q set luci.main.mediaurlbase=/luci-static/vantage
uci -q commit luci
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-default-theme
