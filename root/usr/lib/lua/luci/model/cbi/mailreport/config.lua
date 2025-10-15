local m = Map("luci_mailreport", translate("Mail Report Settings"), translate("Configure scheduled mail reporting for server status."))

-- ---------------------
-- 主设置部分
-- ---------------------
local s = m:section(TypedSection, "settings", translate("General Settings"))
s.anonymous = true
s.addremove = false

-- 启用/禁用
local o = s:option(Flag, "enabled", translate("Enable Mail Report"), translate("Turn on or off the scheduled email reporting service."))
o.default = 0
o.rmempty = false

-- Cron 定时表达式
local o = s:option(Value, "send_time", translate("Schedule Time (Cron)"), translate("Enter the cron expression for report frequency (e.g., 0 8 * * * for daily at 8 AM)."))
o.placeholder = "0 8 * * *"
o.default = "0 8 * * *"
o.datatype = "cron"

-- ---------------------
-- 邮件服务器设置
-- ---------------------
s = m:section(TypedSection, "settings", translate("Email Server and Recipient"))
s.anonymous = true
s.addremove = false

local o = s:option(Value, "recipient", translate("Recipient Email"), translate("The address that will receive the status reports."))
o.datatype = "mail"
o.rmempty = false

local o = s:option(Value, "sender_email", translate("Sender Email (Optional)"), translate("The email address used as the sender (MAIL FROM command). If empty, uses OpenWrt@router-name."))
o.datatype = "mail"

local o = s:option(Value, "smtp_server", translate("SMTP Server"), translate("The hostname or IP address of your outgoing mail server."))
o.rmempty = false

local o = s:option(Value, "smtp_port", translate("SMTP Port (SMTPS)"), translate("Standard port is 465 for SMTPS."))
o.datatype = "port"
o.default = "465"

local o = s:option(Value, "smtp_user", translate("Username"), translate("Your SMTP login username."))

local o = s:option(Value, "smtp_password", translate("Password"), translate("Your SMTP login password."))
o.password = true

-- ---------------------
-- 状态保存和 Cron 任务生成 (与之前版本一致)
-- ---------------------
function m.on_after_commit(map)
    local uci = require "luci.model.uci".cursor()
    local enabled = uci:get("luci_mailreport", "settings", "enabled")
    local cron_time = uci:get("luci_mailreport", "settings", "send_time")

    luci.sys.cron.remove("/usr/bin/status_reporter.sh")

    if enabled == "1" and cron_time and cron_time ~= "" then
        local cron_job = cron_time .. " /usr/bin/status_reporter.sh"
        luci.sys.cron.add(cron_job)
    end

    luci.sys.call("/etc/init.d/cron restart >/dev/null 2>&1")
end

return m