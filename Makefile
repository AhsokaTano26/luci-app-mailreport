#
# Copyright (C) 2024 OpenWrt.org
#
include $(TOPDIR)/rules.mk

LUCI_TITLE:=Mail Report - Scheduled Server Status Email (Minimal Deps)
LUCI_DESCRIPTION:=A LuCI application to schedule status reports via email. Requires openssl-client.
# 核心依赖仅为 openssl-client
LUCI_DEPENDS:=+openssl-client +luci-lib-nixio

PKG_NAME:=luci-app-mailreport
PKG_VERSION:=1.0
PKG_RELEASE:=2

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-mailreport/install
    # 安装 Shell 脚本
    $(INSTALL_BIN) ./files/usr/bin/status_reporter.sh $(1)/usr/bin/
    # 安装默认配置
    $(INSTALL_CONF) ./files/etc/config/luci_mailreport $(1)/etc/config/
    # 安装 LuCI Controller 和 Model 文件
    $(CP) ./root/* $(1)/
endef

$(eval $(call BuildPackage,luci-app-mailreport))