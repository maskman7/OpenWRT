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
- **默认语言**：中文翻译包在 `.config` 勾选 `luci-i18n-*-zh-cn`；`diy-part2.sh` 的 uci-defaults 把 `luci.main.lang` 设为 `zh_cn`（加载时自动归一化为 `zh-cn` 匹配 `.lmo`），首启强制简体中文，不跟随浏览器。
- **概览移除"系统信息"卡片**：`diy-part2.sh` 用 `find ... -delete` 删掉 luci-mod-status 的 `10_system.js`（概览 include 卡片按文件名排序加载，删掉即不渲染）。Packet path 流程图是 vantage 主题挂在 **状态 → Nftables** 页的组件，不在概览，保持原样未动。

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
- 去广告：`adguardhome`、`luci-app-adguardhome`
- SMB：`ksmbd-server`、`luci-app-ksmbd`
- LuCI Web 基础（必须显式选，否则 80 无服务）：`uhttpd`、`uhttpd-mod-ubus`、`uhttpd-mod-ucode`、`luci-mod-admin-full`、`luci-mod-network`、`luci-mod-status`、`luci-mod-system`、`luci-app-uhttpd`
- 运维小工具：`luci-app-upnp`、`luci-app-nlbwmon`、`luci-app-ttyd`（本体 miniupnpd/nlbwmon/ttyd 由依赖自动拉取）
- 软件包管理：`luci-app-package-manager`（系统 → Software 面板，后期在线搜装/卸载；apk 本体、rpcd 后端与官方软件源默认内置，无需另勾）
- 组网：`kmod-tun`（TUN 内核模块，与内核同树编译，提供 `/dev/net/tun`）、`zerotier`（ZeroTier 客户端；官方源无 `luci-app-zerotier` 面板，用命令行/UCI 管理）
- 中文语言包：`luci-i18n-base-zh-cn`、`luci-i18n-dockerman-zh-cn`、`luci-i18n-adguardhome-zh-cn`、`luci-i18n-ksmbd-zh-cn`、`luci-i18n-ddns-zh-cn`、`luci-i18n-upnp-zh-cn`、`luci-i18n-nlbwmon-zh-cn`、`luci-i18n-ttyd-zh-cn`、`luci-i18n-uhttpd-zh-cn`、`luci-i18n-package-manager-zh-cn`
- 基础：`curl`、`ca-certificates`、`luci-app-ddns`

> 中文说明：第三方 `alist`、`mosdns` 官方源无对应 `luci-i18n-*-zh-cn` 包，其界面语言由各自前端自带；未翻译到的少量词条仍显示英文。

### 第三方 feed（地址在 diy-part1.sh，兼容性需实测）
- 主题：`luci-theme-vantage`（anothaDev/luci-theme-vantage）
- 网盘：`alist`、`luci-app-alist`（sbwml/luci-app-alist）
- DNS：`mosdns`、`luci-app-mosdns`（sbwml/luci-app-mosdns）

### 暂缓：OpenClash
- 官方源不带 OpenClash，第三方依赖杂、与新 luci 兼容性风险高，首版先在 `.config` 注释掉，保证基础固件先出包。
- 加回：part1 追加 `src-git openclash https://github.com/vernesong/OpenClash`，再取消 `.config` 里 `# CONFIG_PACKAGE_luci-app-openclash=y` 的注释。

### ZeroTier 固化后配置
- 固件已带 `kmod-tun` + `zerotier`，`diy-part2.sh` 的 uci-defaults 已 `/etc/init.d/zerotier enable` 开机自启。
- 进系统后执行 `zerotier-cli join <你的网络ID>`，再登录 my.zerotier.com 后台给本机设备授权；`zerotier-cli status` 看在线状态、`zerotier-cli peers` 看对端。
- 要打通局域网 ↔ ZeroTier 虚拟网：防火墙里把 zt 虚拟网卡加入 LAN 覆盖设备，并按需加转发规则。
- 官方源无 `luci-app-zerotier` 图形面板，以上用命令行/UCI 管理；想要面板需另接第三方 feed，与新 luci 兼容性自担。
- 不建议改在 dockerman 容器里跑：ZeroTier 需 TUN，容器方式仍要宿主先有 kmod-tun，还要挂 `/dev/net/tun`、加 `NET_ADMIN`，组网转发更绕。

## 五、风险与注意事项

1. **GitHub 能访问是硬前提**：建仓库、传文件、触发编译、下产物都要打开 GitHub；本地网络不通则流程无法启动。云端 runner 本身在海外，拉源码不受你本地网络影响。
2. **第三方 feed 兼容性**：openwrt 为 snapshot 新版本，sbwml 的 alist/mosdns、vantage 主题主要面向旧版 luci/24.10。若这几个包编译报错，先在 `.config` 注释对应行，保证基础固件先出包，再逐个加回。
3. **DNS 端口不冲突**：AdGuardHome 与 mosdns 都管 DNS，装完错开端口、明确分工，避免抢占 53。
4. **电脑网卡同网段**：默认 IP 改为 `192.168.18.254`，进后台前把电脑网卡设为 `192.168.18.2/24`。
5. **刷机两步走，别在 U-Boot 直刷 sysupgrade.bin**：先在 U-Boot「uImage 启动」页用 `initramfs-uImage.itb` 内存启动 → 进 OpenWrt 后，再用 LuCI 或 `sysupgrade -v` 刷 `squashfs-sysupgrade.bin` 写 eMMC。`sysupgrade.bin` 是 legacy 升级格式，不能在 U-Boot 直刷（上次半砖即由此导致）。
6. **后期在线装包的限制（snapshot）**：用户态服务/面板/库（daemon、`luci-app-*`、lib）可在 系统 → Software 面板或 `apk add <包名>` 直接装；但带内核模块的包（`kmod-*`）必须与当前内核版本严格匹配，snapshot 内核滚动更新后在线 kmod 可能装不上或版本不符——这类需求最好在编译阶段就写进 `.config` 同树编译。第三方 feed（alist/mosdns/vantage）写入固件的是编译时快照地址，snapshot 滚动后其在线源可能 404；官方 base/packages/luci/routing/telephony/video 源不受影响。

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

**首轮 initramfs 实测通过项（openwrt master r38384）**
- 网络：`br-lan 192.168.18.254/24`，lan1 在线；WAN DHCP 拿到上级地址；QCA8075 四口全部识别。
- 定制：主机名 `MaskMan7WRT`；默认主题 vantage（登录页已加载 vantage.css）。
- Docker：dockerd/containerd/runc 29.6.1 运行中，overlayfs + cgroup v2，`S99dockerd` 开机自启。
- 插件服务：AdGuardHome(3000)、mosdns、ksmbd(445)、alist、ddns、ttyd(7681)、wsdd2 均在；对应 luci-app 已注册菜单。
- 备注：该 snapshot 已用 **apk**（无 opkg）。中文 i18n 包已在重编 `.config` 内；首轮内存系统 WAN 联网后在线补装 7 个 zh-cn 包验证通过，登录页返回"用户名/密码/登录"，固化后随固件永久生效。

## 六、可选追加的热门实用插件

未默认写入；需要时在 `.config` 追加对应 `CONFIG_PACKAGE_*=y`，编译前确认包在当前源存在：

- `luci-app-watchcat`：断线/异常自动重启守护
- `luci-app-sqm`：带宽 QoS 调度
- `luci-app-tailscale`：异地内网穿透（替代/补充 ZeroTier）

> upnp / nlbwmon / ttyd / zerotier 已在本轮正式加入 `.config`，不再属于可选。

## 七、待办

- [x] 首轮 openwrt master 固件编译成功，initramfs 内存启动验证通过（网络/主机名/主题/Docker/插件）。
- [ ] 把补了 Web 基础包的新 `.config` 提交到 GitHub，重新触发 Action 编译。
- [ ] 新固件出包后：U-Boot「uImage 启动」页启动新 `initramfs-uImage.itb` → 进系统确认 LuCI 面板/插件正常 → 上传 `squashfs-sysupgrade.bin` 执行系统内升级写 eMMC。
- [ ] 固化后核对：默认 IP `192.168.18.254`、主机名 `MaskMan7WRT`、vantage 主题、Docker 与各插件开机自启。
- [x] 本轮已加入：upnp、nlbwmon（流量监控）、ttyd（网页终端）、zerotier + kmod-tun（组网）。
- [ ] 待定：代理最终选 OpenClash 还是 Passwall；是否再追加 watchcat/sqm/tailscale 等插件。
