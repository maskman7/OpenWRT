local f = SimpleForm("zerotier", translate("ZeroTier 状态"),
	translate("ZeroTier 守护进程的只读状态。节点需先在 my.zerotier.com 后台授权，才会获得托管 IP。"))
f.reset = false
f.submit = false

local function run(cmd)
	return luci.sys.exec(cmd) or ""
end

local info = f:field(TextValue, "info")
info.rows = 3
info.readonly = true
info.cfgvalue = function() return run("zerotier-cli info 2>&1") end

local nets = f:field(TextValue, "nets")
nets.rows = 5
nets.readonly = true
nets.cfgvalue = function() return run("zerotier-cli listnetworks 2>&1") end

local peers = f:field(TextValue, "peers")
peers.rows = 8
peers.readonly = true
peers.cfgvalue = function() return run("zerotier-cli peers 2>&1") end

return f
