# 太乙 ER1 (jdcloud_re-cs-07) GitHub Action 云编译操作说明

- 源码主线：**openwrt / openwrt**（分支 master）
- 目标机型：Qualcommax · IPQ60xx · JDCloud RE-CS-07
- 默认管理 IP：**192.168.18.254**　主机名：**MaskMan7WRT**　默认主题：**vantage**

## 一、本目录文件（上传到新仓库对应位置）

| 本地文件 | 仓库内路径 | 作用 |
| --- | --- | --- |
| `.config` | 仓库根目录 `.config` | 机型选择 + 预装包清单 |
| `diy-part1.sh` | 仓库根目录 `diy-part1.sh` | 更新 feeds 前追加第三方源（vantage / alist / mosdns） |
| `diy-part2.sh` | 仓库根目录 `diy-part2.sh` | 改默认 IP、主机名、默认主题 |
| `.github/workflows/openwrt-builder.yml` | `.github/workflows/openwrt-builder.yml` | 编译流程（源码主线已填好 openwrt master） |

## 二、三项定制分别落在哪（分工说明）

编译流程顺序：part1 加源 → 更新/安装 feeds → 加载 .config → **part2 改默认配置** → defconfig → 编译。

- **主题装进固件**：靠 `diy-part1.sh` 把 vantage 仓库加为第三方源，再由 `.config` 勾选 `luci-theme-vantage`。包必须先进源码树，否则勾了也无效。
- **默认 IP**：在 `diy-part2.sh` 里 sed 改 `config_generate` → `192.168.18.254`。
- **主机名**：在 `diy-part2.sh` 里 sed 改 `config_generate` → `MaskMan7WRT`（openwrt 默认主机名为 `OpenWrt`）。
- **默认主题**：在 `diy-part2.sh` 写入 uci-defaults，首启把 `luci.main.mediaurlbase` 指向 `/luci-static/vantage`。
- **默认语言**：`.config` 用翻译开关 `CONFIG_LUCI_LANG_zh_Hans=y` 打开简体中文；`diy-part2.sh` 的 uci-defaults 把 `luci.main.lang` 设为 `zh_cn`（加载时归一化为 `zh-cn` 匹配 `.lmo`），首启强制简体中文，不跟随浏览器。
- **概览移除"系统信息"卡片**：`diy-part2.sh` 明确删除 luci-mod-status 的 `10_system.js`（概览 include 卡片按文件名排序加载，删掉即不渲染），并在编译日志打印残留数量便于核对。
- **Packet path 流程图**：vantage 的 `nftflow` 组件只在 状态 → Nftables 页挂载，且依附该页规则表 DOM；概览页没有这层结构，本轮不移植到概览顶端（原因见风险段）。

## 三、GitHub 网页操作步骤

1. 登录 GitHub 账号（需能打开 GitHub；打不开先挂代理 / 换手机热点 / 用镜像）。
2. 打开模板 `https://github.com/P3TERX/Actions-OpenWrt`，点绿色 **Use this template → Create a new repository**；仓库名随意，Visibility 选 **Public（公开）**，点 **Create repository**。
3. 在新仓库点 **Add file → Upload files**，把 `.config`、`diy-part1.sh`、`diy-part2.sh` 拖到仓库根目录，底部点 **Commit changes**。
4. 再上传 workflow：**Add file → Create new file**，文件名填 `.github/workflows/openwrt-builder.yml`，把本目录同名文件内容贴进去，**Commit changes**。
5. 源码主线已在 yml 顶部填好（`REPO_URL: https://github.com/openwrt/openwrt`、`REPO_BRANCH: master`），一般无需再改。
6. 进仓库顶部 **Actions** 页，首次按提示点 **I understand my workflows, go ahead and enable them** 启用 Actions。
7. 左侧选 **OpenWrt Builder** → 右上 **Run workflow** → 点绿色 **Run workflow** 确认。
8. 点进这次运行记录看日志；云端编译约 1.5~3 小时，可关网页。成功后固件在仓库 **Releases**，或运行记录右侧 Artifacts 下载。
9. ER1 **没有 factory.bin**（官方同机型也只出两个包）：
   - `...-initramfs-uImage.itb`：内存启动 FIT 镜像，U-Boot「uImage 启动」页上传，不写 eMMC；
   - `...-squashfs-sysupgrade.bin`：系统内升级包，进系统后刷写 eMMC。

> 注意：改完文件一定要 **Commit changes**，然后用 **Run workflow** 全新触发；对旧 run 点 **Re-run jobs** 会复用旧代码，新文件不会生效。

## 四、预装包清单

### 官方源（编译最稳，已核实 openwrt snapshots 存在）
- Docker：`docker`、`dockerd`、`containerd`、`runc`、`luci-app-dockerman`
- Docker 加速器：首启由 uci-defaults `99-docker-mirror` 写入 `dockerd.globals.registry_mirrors`（`docker.m.daocloud.io`、`docker.1ms.run`）；国内直连 Docker Hub 超时，必须走镜像源。镜像须为 `linux/arm64`（本机 aarch64）。
- 去广告：`adguardhome`、`luci-app-adguardhome`
- SMB：`ksmbd-server`、`luci-app-ksmbd`
- LuCI Web 基础（必须显式选，否则 80 无服务）：`uhttpd`、`uhttpd-mod-ubus`、`uhttpd-mod-ucode`、`luci-mod-admin-full`、`luci-mod-network`、`luci-mod-status`、`luci-mod-system`、`luci-app-uhttpd`
- 网络协议面板：`luci-proto-ipv6`（DHCPv6/6in4/6to4/6rd/DS-Lite/IPIP6 界面）、`luci-proto-ppp`（PPP/PPPoE/PPtP 界面）；底层 `odhcp6c`、`ppp` 由系统默认拉入。缺 `luci-proto-ipv6` 时 wan6（proto=dhcpv6）接口页报"不支持的协议类型"。
- 运维小工具：`luci-app-upnp`、`luci-app-nlbwmon`、`luci-app-ttyd`（本体 miniupnpd/nlbwmon/ttyd 由依赖自动拉取）
- 软件包管理：编入官方 `luci-app-package-manager`（菜单位置 系统 → 软件包/Software；后端已适配 apk，检测到 `/usr/bin/apk` 走 `apk query/add/del`，自带简体中文）；命令行 `apk add <包名>` 同样可用（apk 本体、rpcd 后端与官方软件源默认内置）。
- Lua 兼容层：`luci-compat`（提供旧版 `luci.cbi` 等 Lua CBI 模块；老式 Lua CBI 第三方面板缺它会报 `module 'luci.cbi' not found`。新 luci 默认只带 `luci-lua-runtime`，不含 CBI）。
- 组网：`kmod-tun`（TUN 内核模块，与内核同树编译，提供 `/dev/net/tun`）+ `zerotier` 客户端本体（官方 packages feed；依赖的 libstdcpp/libminiupnpc/libnatpmp/libatomic 由编译自动拉取）。官方 luci feed 无图形面板，用 `zerotier-cli` 命令行管理。
- 中文界面：`.config` 用翻译开关 `CONFIG_LUCI_LANG_zh_Hans=y`（luci-base → Translations → 简体中文）。打开后 luci.mk 自动把所有已选主包的 `luci-i18n-*-zh-cn` 翻译包纳入；**不要**逐个手写 `CONFIG_PACKAGE_luci-i18n-*-zh-cn=y`——这些是 HIDDEN 包，会被 `make defconfig` 按默认逻辑清掉。
- 基础：`curl`、`ca-certificates`、`luci-app-ddns`

> 中文说明：第三方 `alist`、`mosdns` 官方无对应 `luci-i18n-*-zh-cn` 包，界面语言由各自前端自带；未翻译到的少量词条仍显示英文。

### 第三方 feed（地址在 diy-part1.sh，兼容性需实测）
- 主题：`luci-theme-vantage`（anothaDev/luci-theme-vantage）
- 网盘：`alist`、`luci-app-alist`（sbwml/luci-app-alist）
- DNS：`mosdns`、`luci-app-mosdns`（sbwml/luci-app-mosdns）
- 软件包面板：官方 `luci-app-package-manager`（随官方 luci feed，非第三方源）。原计划的 iStore `luci-app-store` 已弃用，见下文排错记录。

### 暂缓：OpenClash
- 官方源不带 OpenClash，第三方依赖杂、与新 luci 兼容性风险高，首版先在 `.config` 注释掉，保证基础固件先出包。
- 加回：part1 追加 `src-git openclash https://github.com/vernesong/OpenClash`，再取消 `.config` 里 `# CONFIG_PACKAGE_luci-app-openclash=y` 的注释。

### ZeroTier（已编入固件）
- 固件已带 `kmod-tun`（TUN 内核模块，同树编译）与 `zerotier` 客户端本体；依赖的用户态库编译时自动拉取。
- 首次使用：`/etc/init.d/zerotier enable && /etc/init.d/zerotier start`；`zerotier-cli info` 返回 `200 OK` + 16 位节点地址即正常。
- 执行 `zerotier-cli join <你的网络ID>`，再登录 my.zerotier.com 后台给本机设备授权；`zerotier-cli status` 看在线状态、`zerotier-cli peers` 看对端。
- 要打通局域网 ↔ ZeroTier 虚拟网：防火墙里把 zt 虚拟网卡加入 LAN 覆盖设备，并按需加转发规则。
- 官方源无图形面板；第三方 Lua CBI 面板需配合已编入的 `luci-compat`，兼容性以固化后实测为准。
- 不建议改在 dockerman 容器里跑：ZeroTier 需 TUN，容器方式仍要宿主先有 kmod-tun，还要挂 `/dev/net/tun`、加 `NET_ADMIN`，组网转发更绕。

## 五、风险与注意事项

1. **GitHub 能访问是硬前提**：建仓库、传文件、触发编译、下产物都要打开 GitHub；本地网络不通则流程无法启动。云端 runner 本身在海外，拉源码不受你本地网络影响。
2. **第三方 feed 兼容性**：openwrt 为 snapshot 新版本，sbwml 的 alist/mosdns、vantage 主题主要面向旧版 luci/24.10。若这几个包编译报错，先在 `.config` 注释对应行，保证基础固件先出包，再逐个加回。
3. **DNS 端口不冲突**：AdGuardHome 与 mosdns 都管 DNS，装完错开端口、明确分工，避免抢占 53。
4. **电脑网卡同网段**：默认 IP 改为 `192.168.18.254`，进后台前把电脑网卡设为 `192.168.18.2/24`。
5. **刷机两步走，别在 U-Boot 直刷 sysupgrade.bin**：先在 U-Boot「uImage 启动」页用 `initramfs-uImage.itb` 内存启动 → 进 OpenWrt 后，再用 LuCI 或 `sysupgrade -v` 刷 `squashfs-sysupgrade.bin` 写 eMMC。`sysupgrade.bin` 是 legacy 升级格式，不能在 U-Boot 直刷（上次半砖即由此导致）。
6. **后期在线装包的限制（snapshot）**：用户态服务/面板/库（daemon、`luci-app-*`、lib）可在官方软件包面板或 `apk add <包名>` 直接装；但带内核模块的包（`kmod-*`）必须与当前内核版本严格匹配，snapshot 内核滚动更新后在线 kmod 可能装不上或版本不符——这类需求最好在编译阶段就写进 `.config` 同树编译。第三方 feed（alist/mosdns/vantage）写入固件的是编译时快照地址，snapshot 滚动后其在线源可能 404；官方 base/packages/luci/routing/telephony/video 源不受影响。
7. **iStore 方案已弃用**：`luci-app-store` 依赖 GNU `tar`，当前 master apk 构建下 GNU tar 未被 `make defconfig` 选中（snapshot 二进制仓库也无 `tar.apk`，仅 `bsdtar`），store 主包连同 `tar` 被 defconfig 剔除；同 feed 的 `taskd`/`luci-lib-taskd`/`luci-lib-xterm` 虽能编入，但缺主面板后端空转。故改用官方 `luci-app-package-manager` 承担图形化装包；`luci-compat`、`luci-lua-runtime` 仍保留，供后期老式 Lua 面板兜底。
8. **老式 Lua CBI 面板需 `luci-compat`**：新 luci 默认只带 `luci-lua-runtime`，不含旧版 `luci.cbi`；第三方老式 Lua 面板（如 zerotier 面板）若 `require("luci.cbi")`，缺 `luci-compat` 会报 `module 'luci.cbi' not found`。本固件已编入 `luci-compat` 兜底；但个别更老面板还可能依赖已被 master 移除的其他 Lua 模块，仍可能报错，以固化后实测为准。
9. **Packet path 流程图已挂到概览顶端**：vantage `nftflow` 原本只在 状态 → Nftables 页由 `menu-vantage.js` 按 `data-page==='admin-status-nftables'` 拦截挂载。源码复核其 `draw()` 主体由 `nft --json list ruleset` 数据独立生成，不依赖 Nftables 页规则卡；耦合点仅入口页面判断与 `.nft-table` 锚点。方案：概览 `include/15_flow.js` 注册一张卡片，先放 `.nft-table` 占位（CSS 默认 `display:none`，无空框残留），再 `L.require('vantage-theme.nftflow').attach(#view)`；卡片仅首次 render 返回占位，概览轮询重建 DOM 时返回 `null` 保留已画流程图。已在内存系统实测：流程图在概览顶端、轮询不丢、无重复挂载。规则表模式下规则步骤条件对齐依赖 Nftables 页原始规则行，概览会略简，默认"流向"模式完整。

## 五补、编译排错记录

**已规避：immortalwrt firewall4 fullcone 补丁失败**
- 最初用 immortalwrt master，自带 `001-firewall4-add-support-for-fullcone-nat.patch` 在最新上游 firewall4 上 Hunk#1 打不上，导致 firewall4 编译失败、`world Error 2`。
- ER1 机型只在各主线 master，稳定分支 24.10/25.12 均无 cs-07，不能切分支绕开。
- 最终方案：**主线换成 openwrt/openwrt master**。已核实 openwrt master 带 cs-07 机型、无该 fullcone 补丁；Docker/AdGuardHome/SMB 官方源齐全。

**Release 403 "Resource not accessible by integration"**
- 原因：仓库 Actions 令牌默认只读，无权创建 Release。
- 处理：仓库 **Settings → Actions → General → Workflow permissions → Read and write permissions → Save**，再重跑。

**首轮固件实测：缺 LuCI Web 基础包（80 端口无服务）**
- 首轮编译成功、initramfs 内存启动后，网络/主机名/主题/Docker/各插件服务都正常，但 **80 端口无监听、LuCI 打不开**；SSH(22) 正常。
- 原因：`.config` 只勾了 `luci-app-*`，它们只依赖 `luci-base`，**不会自动拉 Web 服务器 uhttpd 和基础管理页 `luci-mod-*`**。
- 已在线 `apk add` 补装验证：`uhttpd`、`uhttpd-mod-ubus`、`uhttpd-mod-ucode`、`luci-mod-admin-full`、`luci-mod-network`、`luci-mod-status`、`luci-mod-system`、`luci-app-uhttpd`，补完 80 端口起、登录页与 vantage 主题正常、ubus 空密码登录成功、6 个插件读写 ACL 完整。
- 处理：上述 8 个包已写入本地 `.config` 的「LuCI Web 基础」段，**重编后固化进固件**；在线补的包只在内存系统，断电即丢，不能替代重编。

**iStore（luci-app-store）未编入，最终弃用并改用官方 package-manager**
- build-9（run 44025902005，success）复核：`luci-app-store`、`luci-lib-taskd`、`taskd`、`luci-lib-xterm` 及依赖在 manifest/config.buildinfo 全部为 0；其它第三方 feed（vantage/alist/mosdns）均正常编入。
- build-10（run 44040250337，success，266 包）复核：加固后 `luci-lib-taskd`、`taskd`、`luci-lib-xterm` 及 libuci-lua/mount-utils/script-utils/coreutils/coreutils-stty/luci-lua-runtime/luci-compat 均进 world；但 **`luci-app-store` 与 `tar` 仍被 defconfig 剔除**。
- 根因方向：store 的 `LUCI_DEPENDS` 写死 `+tar`（GNU tar）；当前 master apk 构建下 GNU tar 未被 defconfig 选中（snapshot 二进制仓库 packages/base 目录均无 `tar.apk`，仅 `bsdtar`），依赖不可满足导致 store 连带被剔；tar 本体同样未进。store 脚本仅做 `tar -czf/-zxf` 打解 gzip，busybox tar 可替代。
- 决定：不再追 iStore。图形化装包改用官方 `luci-app-package-manager`（依赖仅 `+luci-base`，后端 `package-manager-call` 已适配 apk，自带 zh_Hans）；part1 注释 istore 源、part2 移除 istore 兜底段，`.config` 取消 store/taskd/xterm/tar 勾选，保留 `luci-compat`、`luci-lua-runtime` 作 Lua 面板兜底。
- 教训：第三方 luci-app 必须**先在 part1 接对应 feed，再在 .config 勾选**；只勾 .config 不接 feed，包会被 defconfig 静默移除，且编译不一定报错。

**第三轮固件实测：wan6 接口页报"不支持的协议类型"**
- 现象：网络 → 接口，wan6（proto=dhcpv6，device=wan）显示"不支持的协议类型。安装扩展协议..."；wan（dhcp）正常。
- 根因：底层 `odhcp6c` 已装、内核 IPv6 未禁用，但 **LuCI 协议面板包 `luci-proto-ipv6` 未编入**，界面不认识 dhcpv6；纯 ucode/JS 面板缺失，不影响底层 IPv6 协商。
- 处理：`.config` 补 `luci-proto-ipv6=y`；另预留 `luci-proto-ppp=y`（PPPoE/PPtP 拨号界面，当前 wan 走 dhcp，`ppp-mod-pppoe` 本体已在系统内）。重编后界面可正常编辑 wan6。

**首轮 initramfs 实测通过项（openwrt master r38384）**
- 网络：`br-lan 192.168.18.254/24`，lan1 在线；WAN DHCP 拿到上级地址；QCA8075 四口全部识别。
- 定制：主机名 `MaskMan7WRT`；默认主题 vantage（登录页已加载 vantage.css）。
- Docker：dockerd/containerd/runc 29.6.1 运行中，overlayfs + cgroup v2，`S99dockerd` 开机自启。实测直连 `registry-1.docker.io` 超时；配 daocloud / 1ms.run 加速器后裸名 `docker pull alpine:latest` 成功（arm64/linux，4.28MB），容器可正常 run/exec。
- 插件服务：AdGuardHome(3000)、mosdns、ksmbd(445)、alist、ddns、ttyd(7681)、wsdd2 均在；对应 luci-app 已注册菜单。
- 备注：该 snapshot 已用 **apk**（无 opkg）。中文 i18n 包已在重编 `.config` 内；首轮内存系统 WAN 联网后在线补装 7 个 zh-cn 包验证通过，登录页返回"用户名/密码/登录"，固化后随固件永久生效。

## 六、可选追加的热门实用插件

未默认写入；需要时在 `.config` 追加对应 `CONFIG_PACKAGE_*=y`，编译前确认包在当前源存在：

- `luci-app-watchcat`：断线/异常自动重启守护
- `luci-app-sqm`：带宽 QoS 调度
- `luci-app-tailscale`：异地内网穿透（替代/补充 ZeroTier）

> upnp / nlbwmon / ttyd / kmod-tun / zerotier 已在 `.config` 编入；zerotier 官方无 luci 图形面板，用 `zerotier-cli` 命令行管理。

## 七、待办

- [x] 首轮 openwrt master 固件编译成功，initramfs 内存启动验证通过（网络/主机名/主题/Docker/插件）。
- [ ] 把补了 Web 基础包的新 `.config` 提交到 GitHub，重新触发 Action 编译。
- [ ] 新固件出包后：U-Boot「uImage 启动」页启动新 `initramfs-uImage.itb` → 进系统确认 LuCI 面板/插件正常 → 上传 `squashfs-sysupgrade.bin` 执行系统内升级写 eMMC。
- [ ] 固化后核对：默认 IP `192.168.18.254`、主机名 `MaskMan7WRT`、vantage 主题、Docker 与各插件开机自启。
- [x] 本轮已加入：upnp、nlbwmon（流量监控）、ttyd（网页终端）、kmod-tun（TUN 模块）、zerotier 客户端本体；zerotier 官方无 luci 面板，命令行管理。
- [ ] 待重编验证：新固件 world 应含官方 `luci-app-package-manager`（及对应 `luci-i18n-package-manager-zh-cn`）与 `zerotier`（含 libstdcpp/libminiupnpc/libnatpmp/libatomic 依赖）；内存启动后 系统 → 软件包 面板可列出已装/可装包、可在线 apk add/del，`zerotier-cli info` 正常。iStore 链（store/taskd/xterm/tar）不再编入。
- [x] Packet path 流程图已移植到概览顶端（内存系统实测通过）；part2 已内联 `15_flow.js`，重编后随固件固化。
- [ ] 待定：代理最终选 OpenClash 还是 Passwall；是否再追加 watchcat/sqm/tailscale 等插件。
