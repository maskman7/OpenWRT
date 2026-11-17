#!/bin/bash
# DIY 脚本 part1：在 `./scripts/feeds update -a` 之前执行，追加第三方软件源。

# vantage 主题（仓库内含 luci-theme-vantage 与 luci-app-vantage）
echo 'src-git vantage https://github.com/anothaDev/luci-theme-vantage' >> feeds.conf.default

# alist 网盘聚合（luci-app-alist + alist 本体）
echo 'src-git alist https://github.com/sbwml/luci-app-alist' >> feeds.conf.default

# mosdns DNS 分流 / 去广告（luci-app-mosdns + mosdns 本体）
echo 'src-git mosdns https://github.com/sbwml/luci-app-mosdns' >> feeds.conf.default

# iStore 软件中心方案已弃用（luci-app-store 依赖 GNU tar，master apk 构建下未被选中）；
# 图形化装包改用官方 luci-app-package-manager（随官方 luci feed，无需第三方源）。
# echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default
