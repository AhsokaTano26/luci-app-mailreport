#
# Copyright (C) 2024 OpenWrt.org
#
# package/luci-app-mailreport/Makefile

include $(TOPDIR)/rules.mk

# ----------------------------------------------------
# 软件包元数据定义
# ----------------------------------------------------
LUCI_TITLE:=Mail Report - Scheduled Server Status Email (Minimal Deps)
LUCI_DESCRIPTION:=A LuCI application to schedule status reports via email using openssl-util.
# 修正依赖：使用 openssl-util 代替 openssl-client
LUCI_DEPENDS:=+openssl-util +luci-lib-nixio

PKG_NAME:=luci-app-mailreport
PKG_VERSION:=1.0
PKG_RELEASE:=3

# ----------------------------------------------------
# 包含 LuCI 编译系统
# ----------------------------------------------------
# 必须包含 LuCI 的 Makefile 规则
include $(TOPDIR)/feeds/luci/luci.mk

# ----------------------------------------------------
# 文件安装规则 (Define Package Install)
# ----------------------------------------------------
# 这一块定义了编译系统如何将源代码目录下的文件复制到最终的 IPK 文件中。
# 注意：以下所有以 "$(INSTALL_...)" 或 "$(CP)" 开头的行，前面的缩进必须是 Tab 字符！
define Package/luci-app-mailreport/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/config

	# 安装状态报告 Shell 脚本，并赋予执行权限 (INSTALL_BIN 自动处理)
	$(INSTALL_BIN) ./files/usr/bin/status_reporter.sh $(1)/usr/bin/

	# 安装默认配置文件
	$(INSTALL_CONF) ./files/etc/config/luci_mailreport $(1)/etc/config/

	# 复制 LuCI 控制器和 CBI 模型文件
	$(CP) ./root/* $(1)/
endef

# ----------------------------------------------------
# 调用编译函数
# ----------------------------------------------------
$(eval $(call BuildPackage,luci-app-mailreport))