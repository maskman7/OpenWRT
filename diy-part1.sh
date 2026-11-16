#!/bin/bash
# DIY 脚本 part1：在 `./scripts/feeds update -a` 之前执行，追加第三方软件源。

# vantage 主题（仓库内含 luci-theme-vantage 与 luci-app-vantage）
echo 'src-git vantage https://github.com/anothaDev/luci-theme-vantage' >> feeds.conf.default

# alist 网盘聚合（luci-app-alist + alist 本体）
echo 'src-git alist https://github.com/sbwml/luci-app-alist' >> feeds.conf.default

# mosdns DNS 分流 / 去广告（luci-app-mosdns + mosdns 本体）
echo 'src-git mosdns https://github.com/sbwml/luci-app-mosdns' >> feeds.conf.default

# iStore 软件中心（luci-app-store + taskd/luci-lib-taskd/luci-lib-xterm；已适配 apk，分支 main）
echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default
