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
- 去广告：`adguardhome`、`luci-app-adguardhome`
- SMB：`ksmbd-server`、`luci-app-ksmbd`
- LuCI Web 基础（必须显式选，否则 80 无服务）：`uhttpd`、`uhttpd-mod-ubus`、`uhttpd-mod-ucode`、`luci-mod-admin-full`、`luci-mod-network`、`luci-mod-status`、`luci-mod-system`、`luci-app-uhttpd`
- 运维小工具：`luci-app-upnp`、`luci-app-nlbwmon`、`luci-app-ttyd`（本体 miniupnpd/nlbwmon/ttyd 由依赖自动拉取）
- 软件包管理：**不**编入官方 `luci-app-package-manager` 面板，在线装包统一走 iStore 软件中心；命令行 `apk add <包名>` 同样可用（apk 本体、rpcd 后端与官方软件源默认内置）。
- Lua 兼容层：`luci-compat`（提供旧版 `luci.cbi` 等 Lua CBI 模块；老式 Lua CBI 第三方面板缺它会报 `module 'luci.cbi' not found`。新 luci 默认只带 `luci-lua-runtime`，不含 CBI）。
- 组网：`kmod-tun`（TUN 内核模块，与内核同树编译，提供 `/dev/net/tun`）；`zerotier` 本体与面板不预置，后期在 iStore / `apk add zerotier` 手动安装。
- 中文界面：`.config` 用翻译开关 `CONFIG_LUCI_LANG_zh_Hans=y`（luci-base → Translations → 简体中文）。打开后 luci.mk 自动把所有已选主包的 `luci-i18n-*-zh-cn` 翻译包纳入；**不要**逐个手写 `CONFIG_PACKAGE_luci-i18n-*-zh-cn=y`——这些是 HIDDEN 包，会被 `make defconfig` 按默认逻辑清掉。
- 基础：`curl`、`ca-certificates`、`luci-app-ddns`

> 中文说明：第三方 `alist`、`mosdns` 官方无对应 `luci-i18n-*-zh-cn` 包，界面语言由各自前端自带；未翻译到的少量词条仍显示英文。

### 第三方 feed（地址在 diy-part1.sh，兼容性需实测）
- 主题：`luci-theme-vantage`（anothaDev/luci-theme-vantage）
- 网盘：`alist`、`luci-app-alist`（sbwml/luci-app-alist）
- DNS：`mosdns`、`luci-app-mosdns`（sbwml/luci-app-mosdns）
- 软件中心：`luci-app-store`（linkease/istore，iStore 一键装应用；后端 `taskd`、`luci-lib-taskd`、`luci-lib-xterm` 与 Lua 运行时 `luci-lua-runtime` 由依赖自动拉取；界面中文随主包内置，无独立 i18n 包；已适配 apk）

### 暂缓：OpenClash
- 官方源不带 OpenClash，第三方依赖杂、与新 luci 兼容性风险高，首版先在 `.config` 注释掉，保证基础固件先出包。
- 加回：part1 追加 `src-git openclash https://github.com/vernesong/OpenClash`，再取消 `.config` 里 `# CONFIG_PACKAGE_luci-app-openclash=y` 的注释。

### ZeroTier（后期手动安装，不预置进固件）
- 固件只带 `kmod-tun`（TUN 内核模块，同树编译）；`zerotier` 本体与面板不在固件内。
- 需要时在 iStore 软件中心搜装，或命令行 `apk add zerotier`；装完 `/etc/init.d/zerotier enable && /etc/init.d/zerotier start`。
- 之后执行 `zerotier-cli join <你的网络ID>`，再登录 my.zerotier.com 后台给本机设备授权；`zerotier-cli status` 看在线状态、`zerotier-cli peers` 看对端。
- 要打通局域网 ↔ ZeroTier 虚拟网：防火墙里把 zt 虚拟网卡加入 LAN 覆盖设备，并按需加转发规则。
- 官方源无图形面板；第三方 Lua CBI 面板需配合已编入的 `luci-compat`，兼容性以固化后实测为准。
- 不建议改在 dockerman 容器里跑：ZeroTier 需 TUN，容器方式仍要宿主先有 kmod-tun，还要挂 `/dev/net/tun`、加 `NET_ADMIN`，组网转发更绕。

## 五、风险与注意事项

1. **GitHub 能访问是硬前提**：建仓库、传文件、触发编译、下产物都要打开 GitHub；本地网络不通则流程无法启动。云端 runner 本身在海外，拉源码不受你本地网络影响。
2. **第三方 feed 兼容性**：openwrt 为 snapshot 新版本，sbwml 的 alist/mosdns、vantage 主题主要面向旧版 luci/24.10。若这几个包编译报错，先在 `.config` 注释对应行，保证基础固件先出包，再逐个加回。
3. **DNS 端口不冲突**：AdGuardHome 与 mosdns 都管 DNS，装完错开端口、明确分工，避免抢占 53。
4. **电脑网卡同网段**：默认 IP 改为 `192.168.18.254`，进后台前把电脑网卡设为 `192.168.18.2/24`。
5. **刷机两步走，别在 U-Boot 直刷 sysupgrade.bin**：先在 U-Boot「uImage 启动」页用 `initramfs-uImage.itb` 内存启动 → 进 OpenWrt 后，再用 LuCI 或 `sysupgrade -v` 刷 `squashfs-sysupgrade.bin` 写 eMMC。`sysupgrade.bin` 是 legacy 升级格式，不能在 U-Boot 直刷（上次半砖即由此导致）。
6. **后期在线装包的限制（snapshot）**：用户态服务/面板/库（daemon、`luci-app-*`、lib）可在 iStore 软件中心或 `apk add <包名>` 直接装；但带内核模块的包（`kmod-*`）必须与当前内核版本严格匹配，snapshot 内核滚动更新后在线 kmod 可能装不上或版本不符——这类需求最好在编译阶段就写进 `.config` 同树编译。第三方 feed（alist/mosdns/vantage）写入固件的是编译时快照地址，snapshot 滚动后其在线源可能 404；官方 base/packages/luci/routing/telephony/video 源不受影响。
7. **iStore 软件中心兼容性**：`luci-app-store` 是 Lua 面板，经 `luci-lua-runtime` 在新 luci 下运行；内存系统在线安装时依赖全部拉齐、控制器/视图/中文/自启就位，但 Lua 页面在新 JS 侧边栏的实际渲染需固化后浏览器核对。商店内第三方应用面向多平台打包，官方 README 自陈"商店里的插件不一定都能在本固件装上"，其依赖与 snapshot apk/新 luci 的兼容性需逐个实测；装不上的应用仍可走官方源 `apk add` 或编译阶段纳入 `.config`。
8. **老式 Lua CBI 面板需 `luci-compat`**：新 luci 默认只带 `luci-lua-runtime`，不含旧版 `luci.cbi`；第三方老式 Lua 面板（如 zerotier 面板）若 `require("luci.cbi")`，缺 `luci-compat` 会报 `module 'luci.cbi' not found`。本固件已编入 `luci-compat` 兜底；但个别更老面板还可能依赖已被 master 移除的其他 Lua 模块，仍可能报错，以固化后实测为准。
9. **Packet path 流程图未移植到概览**：vantage `nftflow` 只在 状态 → Nftables 页挂载，其 `attach()` 等待该页规则表 DOM 后再叠加流程图；概览页没有这层规则表 DOM，独立复用需另写概览卡片并在真机调试闭环，本轮暂不移植，流程图保留在 Nftables 页查看。

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

**第三轮固件实测：iStore（luci-app-store）未编入**
- 现象：r38415 固件里 compat / 中文 / 删卡 / Docker 等均生效，但 `luci-app-store` 及其依赖链（`taskd`、`luci-lib-taskd`、`luci-lib-xterm`）缺失，在线源列表里也没有 istore feed。
- 根因：`.config` 勾了 `luci-app-store=y`，但远端 `diy-part1.sh` 漏了 istore feed 行（只有 vantage/alist/mosdns）；feed 没接入，编译树里没有 store 包，`make defconfig` 把这条勾选静默清掉。
- 处理：part1 补回 `src-git istore https://github.com/linkease/istore;main`；part2 末尾兜底 `./scripts/feeds install -p istore luci-app-store luci-lib-taskd taskd luci-lib-xterm`。重编后核对 world 含 store。
- 教训：第三方 luci-app 必须**先在 part1 接对应 feed，再在 .config 勾选**；只勾 .config 不接 feed，包会被 defconfig 静默移除，且编译不一定报错。

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

> upnp / nlbwmon / ttyd / kmod-tun 已在本轮正式加入 `.config`；zerotier 本体与面板后期手动安装。

## 七、待办

- [x] 首轮 openwrt master 固件编译成功，initramfs 内存启动验证通过（网络/主机名/主题/Docker/插件）。
- [ ] 把补了 Web 基础包的新 `.config` 提交到 GitHub，重新触发 Action 编译。
- [ ] 新固件出包后：U-Boot「uImage 启动」页启动新 `initramfs-uImage.itb` → 进系统确认 LuCI 面板/插件正常 → 上传 `squashfs-sysupgrade.bin` 执行系统内升级写 eMMC。
- [ ] 固化后核对：默认 IP `192.168.18.254`、主机名 `MaskMan7WRT`、vantage 主题、Docker 与各插件开机自启。
- [x] 本轮已加入：upnp、nlbwmon（流量监控）、ttyd（网页终端）、kmod-tun（TUN 模块）；zerotier 本体/面板后期手动安装。
- [ ] 待重编验证：part1 补回 istore feed、part2 兜底显式 install store 链后，新固件 world 应含 `luci-app-store` / `luci-lib-taskd` / `taskd` / `luci-lib-xterm`。
- [ ] 待定：代理最终选 OpenClash 还是 Passwall；是否再追加 watchcat/sqm/tailscale 等插件。
