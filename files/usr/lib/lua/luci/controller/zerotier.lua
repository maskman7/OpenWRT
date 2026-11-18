module("luci.controller.zerotier", package.seeall)

function index()
	if luci.sys.call("test -f /etc/config/zerotier") ~= 0 then
		return
	end

	entry({"admin", "vpn"}, firstchild(), _("VPN"), 45).dependent = false

	entry({"admin", "vpn", "zerotier"}, firstchild(), _("ZeroTier"), 60).dependent = false
	entry({"admin", "vpn", "zerotier", "status"}, form("zerotier/status"), _("状态"), 1)
	entry({"admin", "vpn", "zerotier", "settings"}, cbi("zerotier/settings"), _("设置"), 2)
	entry({"admin", "vpn", "zerotier", "status_json"}, call("act_status"))
end

function act_status()
	local e = {}
	e.running = luci.sys.call("pgrep /usr/bin/zerotier-one >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
