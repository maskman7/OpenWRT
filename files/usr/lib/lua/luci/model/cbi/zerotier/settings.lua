local m = Map("zerotier", translate("ZeroTier 设置"),
	translate("管理 ZeroTier 客户端。修改后需重启 zerotier 服务生效。"))

local g = m:section(NamedSection, "global", "zerotier", translate("全局"))
g.anonymous = true
g.addremove = false

local en = g:option(Flag, "enabled", translate("启用"))
en.rmempty = false

local s = m:section(TypedSection, "network", translate("网络"),
	translate("要加入的 ZeroTier 网络 ID。在此增删条目后重启 zerotier 服务生效。"))
s.addremove = true
s.anonymous = true

local id = s:option(Value, "id", translate("Network ID"))
id.rmempty = false

local am = s:option(Flag, "allow_managed", translate("托管 IP"))
am.default = "1"

local ag = s:option(Flag, "allow_global", translate("允许全局 IP"))
local ad = s:option(Flag, "allow_default", translate("允许默认路由"))
local adns = s:option(Flag, "allow_dns", translate("允许 DNS"))

return m
