module("luci.controller.mailreport", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/luci_mailreport") then
        return
    end

    local page = entry({"admin", "services", "mailreport"}, cbi("mailreport/config"), _("Mail Report"), 40)
    page.description = _("Scheduled Server Status Email")

    -- 只有管理员能访问
    page.sysauth = "root"
end