#!/bin/bash

# 定义 GitHub 代理地址
GH_PROXY='https://ghfast.top/'

# 定义颜色函数
info() { echo -e "\033[32m\033[01m$*\033[0m"; }
error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; }

# 多语言提示
info "请输入 frpc 配置内容 / Please input frpc configuration content:"
info "完成后请按 Ctrl+D / Press Ctrl+D when finished:\n"

# 读取用户输入的配置内容到临时文件
cat > /tmp/frpc.toml

# 检查用户是否输入了内容
if [ ! -s /tmp/frpc.toml ]; then
    rm -f /tmp/frpc.toml
    error "错误：未输入配置内容 / Error: No configuration content provided"
fi

# 创建配置目录
[ ! -d "/etc/frpc" ] && mkdir -p /etc/frpc

# 复制配置文件
mv /tmp/frpc.toml /etc/frpc/idx-frpc.toml

# 检查下载工具
DOWNLOAD_TOOL="curl"
if ! command -v curl >/dev/null 2>&1; then
    if command -v wget >/dev/null 2>&1; then
        DOWNLOAD_TOOL="wget"
    else
        error "未找到 curl 或 wget / curl or wget not found"
    fi
fi

# 检测系统架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        ARCH_TYPE="amd64"
        ;;
    aarch64|arm64)
        ARCH_TYPE="arm64"
        ;;
    armv7l|armv7)
        ARCH_TYPE="arm"
        ;;
    mips)
        ARCH_TYPE="mips"
        ;;
    mips64)
        ARCH_TYPE="mips64"
        ;;
    *)
        error "不支持的架构: $ARCH / Unsupported architecture: $ARCH"
        ;;
esac

# 下载最新版本 frpc
info "下载 frpc / Downloading frpc..."
if [ "$DOWNLOAD_TOOL" = "curl" ]; then
    LATEST_VERSION=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep -o '"tag_name": ".*"' | cut -d'"' -f4)
    DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/${LATEST_VERSION}/frp_${LATEST_VERSION#v}_linux_${ARCH_TYPE}.tar.gz"
    curl -L "${GH_PROXY}${DOWNLOAD_URL}" -o /tmp/frp.tar.gz
else
    LATEST_VERSION=$(wget -qO- https://api.github.com/repos/fatedier/frp/releases/latest | grep -o '"tag_name": ".*"' | cut -d'"' -f4)
    DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/${LATEST_VERSION}/frp_${LATEST_VERSION#v}_linux_${ARCH_TYPE}.tar.gz"
    wget -O /tmp/frp.tar.gz "${GH_PROXY}${DOWNLOAD_URL}"
fi

# 下载并解压 frpc
curl -L "$DOWNLOAD_URL" -o /tmp/frp.tar.gz
tar -xzf /tmp/frp.tar.gz -C /tmp
mv /tmp/frp_*/frpc /etc/frpc/
rm -rf /tmp/frp.tar.gz /tmp/frp_*

# 创建服务文件
cat > /etc/init.d/idx-frpc << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

NAME="frpc"
USE_PROCD=1

FRPC_PROG="/etc/frpc/frpc"
FRPC_CONF="/etc/frpc/idx-frpc.toml"
FRPC_LOG="/var/log/idx-frpc.log"
FRPC_PID="/var/run/idx-frpc.pid"

start_service() {
    echo -e "\nStarting frpc server..."
    procd_open_instance
    procd_set_param command $FRPC_PROG -c $FRPC_CONF
    procd_set_param pidfile $FRPC_PID
    procd_set_param file $FRPC_CONF
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_set_param respawn ${respawn_threshold:-3600} ${respawn_timeout:-5} ${respawn_retry:-5}
    procd_close_instance
}

stop_service() {
    echo "Stopping frpc server..."
    service_stop $FRPC_PROG
}

reload_service() {
    stop
    start
}
EOF

# 设置执行权限
chmod +x /etc/init.d/idx-frpc

# 启动服务
/etc/init.d/idx-frpc start

info "安装完成 / Installation completed"
echo -e "\n使用方法 / Usage:"
info "启动 / Start:   /etc/init.d/idx-frpc start"
info "停止 / Stop:    /etc/init.d/idx-frpc stop"
info "重启 / Restart: /etc/init.d/idx-frpc restart"

# 创建卸载脚本
cat > /usr/bin/uninstall-idx-frpc << 'EOF'
#!/bin/bash
info() { echo -e "\033[32m\033[01m$*\033[0m"; }
info "正在卸载 idx-frpc / Uninstalling idx-frpc..."
/etc/init.d/idx-frpc stop
rm -rf /etc/frpc
rm -f /etc/init.d/idx-frpc
rm -f /var/log/idx-frpc.log
rm -f /var/run/idx-frpc.pid
rm -f /usr/bin/uninstall-idx-frpc
info "卸载完成 / Uninstallation completed"
EOF

chmod +x /usr/bin/uninstall-idx-frpc

info "卸载命令 / Uninstall: uninstall-idx-frpc"