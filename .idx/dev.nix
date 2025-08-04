# 要了解更多关于如何使用 Nix 配置您的环境
# 请参阅：https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # 系统环境变量
  env = {
    # Sing-box 配置
    ARGO_DOMAIN = "your-domain.example.com";
    UUID = "de04add9-5c68-8bab-950c-08cd5320df18";  # 可以通过 `cat /proc/sys/kernel/random/uuid` 获取
    CDN = "your-cdn-domain.com";
    NODE_NAME = "your-node-name";
    VMESS_PORT = "";  # 端口范围 1000-65535，留空则不启用
    VLESS_PORT = "";  # 端口范围 1000-65535，留空则不启用
    REALITY_PORT = "";  # 端口范围 1000-65535，留空则不启用
    ANYTLS_PORT = "";  # 端口范围 1000-65535，留空则不启用
    HYSTERIA2_PORT = "";  # 端口范围 1000-65535，留空则不启用
    TUIC_PORT = "";  # 端口范围 1000-65535，留空则不启用
    REALITY_PRIVATE = "CClfZsI2vKDN1d3R7LoaDKE639F816jTYKBk3OTCW3A";  # reality 私钥，43个字符
    REALITY_PUBLIC = "lQbxDqzENHyul8jcFw3Qx0IyRGp4_goLWG5RjzCkiX8";  # reality 公钥，43个字符
    LOCAL_IP = "";  # 本地软路由内网地址

    # 节点信息的 Nginx 静态文件服务
    NGINX_PORT = "";  # 端口范围 1000-65535，留空则不启用

    # Argo Tunnel TOKEN 或者 json
    ARGO_AUTH = "your-argo-token";

    # Nezha 监控配置
    NEZHA_SERVER = "monitor.example.com";
    NEZHA_PORT = "443";
    NEZHA_KEY = "your-nezha-key";
    NEZHA_TLS = "--tls";  # 不要可以清空值

    # SSH 配置
    SSH_PASSWORD = "your-secure-password";

    # FRP 配置
    FRP_SERVER_ADDR = "frp.example.com";
    FRP_SERVER_PORT = "7000";
    FRP_AUTH_TOKEN = "your-frp-token";

    # 远程端口配置
    DEBIAN_REMOTE_PORT = "6001";
    UBUNTU_REMOTE_PORT = "6002";
    CENTOS_REMOTE_PORT = "6003";
    ALPINE_REMOTE_PORT = "6004";
  };

  # 使用哪个 nixpkgs 频道
  channel = "stable-25.05"; # 或 "unstable"

  # 添加常用系统工具包
  packages = [
    # 基础系统工具
    pkgs.debianutils        # Debian 系统实用工具集
    pkgs.uutils-coreutils-noprefix  # Rust 实现的核心工具集
    pkgs.gnugrep            # GNU 文本搜索工具
    pkgs.openssl            # SSL/TLS 加密工具
    pkgs.screen             # 终端多窗口管理器
    pkgs.qrencode           # 二维码生成工具

    # 系统监控和管理
    pkgs.procps             # 进程监控工具集（ps, top 等）
    pkgs.nettools           # 网络配置工具集
    pkgs.rsync              # 文件同步工具
    pkgs.psmisc             # 进程管理工具集（killall, pstree 等）
    pkgs.htop               # 交互式进程查看器
    pkgs.iotop              # IO 监控工具

    # 开发工具
    pkgs.gcc                # GNU C/C++ 编译器
    pkgs.gnumake            # GNU 构建工具
    pkgs.cmake              # 跨平台构建系统
    pkgs.python3            # Python 3 编程语言
    pkgs.openssh            # SSH 连接工具
    pkgs.nano               # 简单文本编辑器

    # 文件工具
    pkgs.file               # 文件类型识别工具
    pkgs.tree               # 目录树显示工具
    pkgs.zip                # 文件压缩工具

    # 网络代理工具
    pkgs.cloudflared        # Cloudflare 隧道客户端
    pkgs.xray               # 代理工具
    pkgs.sing-box           # 通用代理平台

    # 监控类
    pkgs.nezha-agent        # 哪吒监控客户端
  ];

  # 服务配置
  services = {
    # 启用 Docker 服务
    docker.enable = true;
  };

  idx = {
    # 搜索扩展程序: https://open-vsx.org/ 并使用 "publisher.id"
    extensions = [
      # 添加您需要的扩展
    ];

    # 启用预览
    previews = {
      enable = true;
      previews = {
        # 预览配置
      };
    };

    # 工作区生命周期钩子
    workspace = {
      # 工作区首次创建时运行
      onCreate = {
        default.openFiles = [ ".idx/dev.nix" "README.md" ];
      };

      # 工作区(重新)启动时运行
      onStart = {
        # 创建配置文件目录
        init-01-mkdir = "
          [ ! -d conf ] && mkdir conf
          [[ $VMESS_PORT$VLESS_PORT$REALITY_PORT$HYSTERIA2_PORT$TUIC_PORT =~ [0-9]+ && ! -d sing-box ]] && mkdir sing-box";

        # 生成随机 UUID
        init-01-set-uuid = "[[ ! $UUID =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]] && cat /proc/sys/kernel/random/uuid > conf/uuid.txt";

        # 生成 Argo Json 配置文件
        init-02-argo-json = "
          if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
            ARGO_JSON=$(sed 's/ //g' <<< \"$ARGO_AUTH\")
            rm -rf conf/tunnel.*
            echo $ARGO_JSON > conf/tunnel.json
            [[ -n $VMESS_PORT || -n $VLESS_PORT || -n $NGINX_PORT ]] && cat > conf/tunnel.yml << EOF
tunnel: $(awk -F '\"' '{print $12}' <<< \"$ARGO_JSON\")
credentials-file: /etc/cloudflared/tunnel.json

ingress:
EOF

            [[ -n $VMESS_PORT ]] && cat >> conf/tunnel.yml << EOF
  - hostname: $ARGO_DOMAIN
    service: https://sing-box:$VMESS_PORT
    path: /$UUID-vmess
    originRequest:
      noTLSVerify: true

EOF

            [[ -n $VLESS_PORT ]] && cat >> conf/tunnel.yml << EOF
  - hostname: $ARGO_DOMAIN
    service: https://sing-box:$VLESS_PORT
    path: /$UUID-vless
    originRequest:
      noTLSVerify: true

EOF

            [[ -n $NGINX_PORT ]] && cat >> conf/tunnel.yml << EOF
  - hostname: $ARGO_DOMAIN
    service: http://nginx:$NGINX_PORT
    path: /$UUID
EOF

            cat >> conf/tunnel.yml << EOF
  - service: http_status:404
EOF
        chmod 644 conf/tunnel.yml conf/tunnel.json
        fi";

        # 检查并创建 nginx 配置
        init-02-nginx = "
          if [[ $VMESS_PORT$VLESS_PORT$REALITY_PORT$HYSTERIA2_PORT$TUIC_PORT =~ [0-9]+ ]]; then
            [[ ! $UUID =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ && -s conf/uuid.txt ]] && UUID=$(cat conf/uuid.txt)
            [ -s sing-box/nginx.conf ] && rm -rf sing-box/nginx.conf
            cat > sing-box/nginx.conf << EOF
user  nginx;
worker_processes  auto;

error_log  /dev/null;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    charset utf-8;

    access_log  /dev/null;

    sendfile        on;

    keepalive_timeout  65;

    #gzip  on;

    server {
        listen       $NGINX_PORT;
        server_name  localhost;

        # 严格匹配 /\$UUID/node 路径
        location = /\$UUID/node {
            alias   /data/node.txt;
            default_type text/plain;
            charset utf-8;
            add_header Content-Type 'text/plain; charset=utf-8';
        }

        # 拒绝其他所有请求
        location / {
            return 403;
        }

        # 错误页面配置
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
EOF
          fi";

        # 检查并创建 SSL 证书
        init-02-ssl-cert = "[[ $VMESS_PORT$VLESS_PORT$REALITY_PORT$HYSTERIA2_PORT$TUIC_PORT =~ [0-9]+ && ! -f sing-box/cert/private.key ]] && (mkdir -p sing-box/cert && openssl ecparam -genkey -name prime256v1 -out sing-box/cert/private.key && openssl req -new -x509 -days 36500 -key sing-box/cert/private.key -out sing-box/cert/cert.pem -subj \"/CN=mozilla.org\")";

        # 检查并创建 sing-box 配置
        init-02-singbox = "
          [ -s sing-box/config.json ] && rm -rf sing-box/config.json
          if [[ $VMESS_PORT$VLESS_PORT$REALITY_PORT$HYSTERIA2_PORT$TUIC_PORT =~ [0-9]+ ]]; then
            if [[ $REALITY_PORT =~ [0-9]+ ]]; then
              if [[ -z $REALITY_PUBLIC || -z $REALITY_PRIVATE ]]; then
                REALITY_KEYPAIR=$(sing-box generate reality-keypair)
                REALITY_PRIVATE=$(awk '/PrivateKey/{print $NF}' <<< \"$REALITY_KEYPAIR\")
                REALITY_PUBLIC=$(awk '/PublicKey/{print $NF}' <<< \"$REALITY_KEYPAIR\")
              fi
              [ -s sing-box/reality_keypair.txt ] && rm -rf sing-box/reality_keypair.txt
              echo -n \"PrivateKey: $REALITY_PRIVATE\nPublicKey: $REALITY_PUBLIC\" > sing-box/reality_keypair.txt
            fi

            [[ ! $UUID =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ && -s conf/uuid.txt ]] && UUID=$(cat conf/uuid.txt)

            cat > sing-box/config.json << EOF
{
    \"dns\":{
        \"servers\":[
            {
                \"type\":\"local\"
            }
        ],
        \"strategy\": \"ipv4_only\"
    },
    \"experimental\": {
        \"cache_file\": {
            \"enabled\": true,
            \"path\": \"/etc/sing-box/cache.db\"
        }
    },
    \"ntp\": {
        \"enabled\": true,
        \"server\": \"time.apple.com\",
        \"server_port\": 123,
        \"interval\": \"60m\"
    },
    \"inbounds\": [
EOF
            [[ $VMESS_PORT =~ [0-9]+ ]] && cat >> sing-box/config.json << EOF
        {
            \"type\":\"vmess\",
            \"tag\":\"vmess-in\",
            \"listen\":\"::\",
            \"listen_port\":$VMESS_PORT,
            \"tcp_fast_open\":false,
            \"proxy_protocol\":false,
            \"users\":[
                {
                    \"uuid\":\"$UUID\",
                    \"alterId\":0
                }
            ],
            \"transport\":{
                \"type\":\"ws\",
                \"path\":\"/$UUID-vmess\",
                \"max_early_data\":2048,
                \"early_data_header_name\":\"Sec-WebSocket-Protocol\"
            },
            \"tls\": {
                \"enabled\": true,
                \"server_name\": \"$ARGO_DOMAIN\",
                \"certificate_path\": \"/etc/sing-box/cert/cert.pem\",
                \"key_path\": \"/etc/sing-box/cert/private.key\"
            },
            \"multiplex\":{
                \"enabled\":true,
                \"padding\":true,
                \"brutal\":{
                    \"enabled\":false,
                    \"up_mbps\":1000,
                    \"down_mbps\":1000
                }
            }
        },
EOF
            [[ $VLESS_PORT =~ [0-9]+ ]] && cat >> sing-box/config.json << EOF
        {
            \"type\": \"vless\",
            \"tag\": \"vless-in\",
            \"listen\": \"::\",
            \"listen_port\": $VLESS_PORT,
            \"users\": [
                {
                    \"uuid\": \"$UUID\",
                    \"flow\": \"\"
                }
            ],
            \"transport\": {
                \"type\": \"ws\",
                \"path\": \"/$UUID-vless\",
                \"max_early_data\": 2048,
                \"early_data_header_name\": \"Sec-WebSocket-Protocol\"
            },
            \"tls\": {
                \"enabled\": true,
                \"server_name\": \"$ARGO_DOMAIN\",
                \"certificate_path\": \"/etc/sing-box/cert/cert.pem\",
                \"key_path\": \"/etc/sing-box/cert/private.key\"
            },
            \"multiplex\": {
                \"enabled\":true,
                \"padding\":true
            }
        },
EOF
            [[ $REALITY_PORT =~ [0-9]+ ]] && cat >> sing-box/config.json << EOF
        {
            \"type\":\"vless\",
            \"tag\":\"reality-in\",
            \"listen\":\"::\",
            \"listen_port\":$REALITY_PORT,
            \"users\":[
                {
                    \"uuid\":\"$UUID\",
                    \"flow\":\"\"
                }
            ],
            \"tls\":{
                \"enabled\":true,
                \"server_name\":\"addons.mozilla.org\",
                \"reality\":{
                    \"enabled\":true,
                    \"handshake\":{
                        \"server\":\"addons.mozilla.org\",
                        \"server_port\":443
                    },
                    \"private_key\":\"$REALITY_PRIVATE\",
                    \"short_id\":[
                        \"\"
                    ]
                }
            },
            \"multiplex\":{
                \"enabled\":true,
                \"padding\":true,
                \"brutal\":{
                    \"enabled\":true,
                    \"up_mbps\":1000,
                    \"down_mbps\":1000
                }
            }
        },
EOF

            [[ $ANYTLS_PORT =~ [0-9]+ ]] && cat >> sing-box/config.json << EOF
        {
            \"type\":\"anytls\",
            \"tag\":\"anytls-in\",
            \"listen\":\"::\",
            \"listen_port\":$ANYTLS_PORT,
            \"users\":[
                {
                    \"password\":\"$UUID\"
                }
            ],
            \"padding_scheme\":[],
            \"tls\":{
                \"enabled\":true,
                \"certificate_path\":\"/etc/sing-box/cert/cert.pem\",
                \"key_path\":\"/etc/sing-box/cert/private.key\"
            }
        },
EOF

            [[ $HYSTERIA2_PORT =~ [0-9]+ ]] && cat >> sing-box/config.json << EOF
        {
            \"type\":\"hysteria2\",
            \"tag\":\"hysteria2-in\",
            \"listen\":\"::\",
            \"listen_port\":$HYSTERIA2_PORT,
            \"users\":[
                {
                    \"password\":\"$UUID\"
                }
            ],
            \"ignore_client_bandwidth\":false,
            \"tls\":{
                \"enabled\":true,
                \"server_name\":\"\",
                \"alpn\":[
                    \"h3\"
                ],
                \"min_version\":\"1.3\",
                \"max_version\":\"1.3\",
                \"certificate_path\":\"/etc/sing-box/cert/cert.pem\",
                \"key_path\":\"/etc/sing-box/cert/private.key\"
            }
        },
EOF
            [[ $TUIC_PORT =~ [0-9]+ ]] && cat >> sing-box/config.json << EOF
        {
            \"type\":\"tuic\",
            \"tag\":\"tuic-in\",
            \"listen\":\"::\",
            \"listen_port\":$TUIC_PORT,
            \"users\":[
                {
                    \"uuid\":\"$UUID\",
                    \"password\":\"$UUID\"
                }
            ],
            \"congestion_control\": \"bbr\",
            \"zero_rtt_handshake\": false,
            \"tls\":{
                \"enabled\":true,
                \"alpn\":[
                    \"h3\"
                ],
                \"certificate_path\":\"/etc/sing-box/cert/cert.pem\",
                \"key_path\":\"/etc/sing-box/cert/private.key\"
            }
        },
EOF

            sed -i '$s/,$//g' sing-box/config.json

            cat >> sing-box/config.json << EOF
    ],
    \"outbounds\": [
        {
            \"type\": \"direct\",
            \"tag\": \"direct\"
        }
    ]
}
EOF

            # 创建 node.txt 文件
            [[ ! $UUID =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ && -s conf/uuid.txt ]] && UUID=$(cat conf/uuid.txt)
            NODE_NAME_1=$(sed \"s/ /%20/g\" <<< \"$NODE_NAME\")
            [ -s sing-box/node.txt ] && rm -rf sing-box/node.txt
            [[ $VMESS_PORT$VLESS_PORT$REALITY_PORT$HYSTERIA2_PORT$TUIC_PORT =~ [0-9]+ ]] && cat > sing-box/node.txt << EOF
浏览器访问节点信息: https://$ARGO_DOMAIN/$UUID/node

*******************************************

┌────────────────┐
│                │
│     V2rayN     │
│                │
└────────────────┘

EOF

            [[ $VMESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
vmess://\$(echo -n '{\"v\":\"2\",\"ps\":\"'$NODE_NAME' vmess\",\"add\":\"'$CDN'\",\"port\":\"443\",\"id\":\"'$UUID'\",\"aid\":\"0\",\"scy\":\"none\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"'$ARGO_DOMAIN'\",\"path\":\"/'$UUID'-vmess\",\"tls\":\"tls\",\"sni\":\"'$ARGO_DOMAIN'\",\"alpn\":\"\",\"fp\":\"chrome\"}' | base64 -w0)

EOF

            [[ $VLESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
vless://$UUID@$CDN:443?encryption=none&security=tls&sni=$ARGO_DOMAIN&fp=chrome&type=ws&host=$ARGO_DOMAIN&path=%2F$UUID-vless#$NODE_NAME_1%20vless

EOF

            [[ $REALITY_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
vless://$UUID@$LOCAL_IP:$REALITY_PORT?encryption=none&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=$REALITY_PUBLIC&type=tcp&headerType=none#$NODE_NAME_1%20reality

EOF

            [[ $ANYTLS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
{
    \"log\":{
        \"level\":\"warn\"
    },
    \"inbounds\":[
        {
            \"listen\":\"127.0.0.1\",
            \"listen_port\":$ANYTLS_PORT,
            \"sniff\":true,
            \"sniff_override_destination\":false,
            \"tag\": \"reality-in\",
            \"type\":\"mixed\"
        }
    ],
    \"outbounds\":[
        {
            \"type\": \"anytls\",
            \"tag\": \"anytls-in\",
            \"server\": \"$LOCAL_IP\",
            \"server_port\": $ANYTLS_PORT,
            \"password\": \"$UUID\",
            \"idle_session_check_interval\": \"30s\",
            \"idle_session_timeout\": \"30s\",
            \"min_idle_session\": 5,
            \"tls\": {
              \"enabled\": true,
              \"insecure\": true,
              \"server_name\": \"\"
            }
        }
    ]
}

EOF

            [[ $HYSTERIA2_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
hysteria2://$UUID@$LOCAL_IP:$HYSTERIA2_PORT/?alpn=h3&insecure=1#$NODE_NAME_1%20hysteria2

EOF

            [[ $TUIC_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
tuic://$UUID:$UUID@$LOCAL_IP:$TUIC_PORT?alpn=h3&congestion_control=bbr#$NODE_NAME_1%20tuic

EOF

            cat >> sing-box/node.txt << EOF
*******************************************

┌────────────────┐
│                │
│    NekoBox     │
│                │
└────────────────┘

EOF

            [[ $VMESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
vmess://\$(echo -n '{\"add\":\"'$CDN'\",\"aid\":\"0\",\"host\":\"'$ARGO_DOMAIN'\",\"id\":\"'$UUID'\",\"net\":\"ws\",\"path\":\"/'$UUID'-vmess\",\"port\":\"443\",\"ps\":\"'$NODE_NAME' vmess\",\"scy\":\"none\",\"sni\":\"'$ARGO_DOMAIN'\",\"tls\":\"tls\",\"type\":\"\",\"v\":\"2\"}' | base64 -w0)

EOF

            [[ $VLESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
vless://$UUID@$CDN:443?security=tls&sni=$ARGO_DOMAIN&fp=chrome&type=ws&path=/$UUID-vless&host=$ARGO_DOMAIN&encryption=none#$NODE_NAME%20vless

EOF

            [[ $REALITY_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
vless://$UUID@$LOCAL_IP:$REALITY_PORT?security=reality&sni=addons.mozilla.org&fp=chrome&pbk=$REALITY_PUBLIC&type=tcp&encryption=none#$NODE_NAME_1%20reality

EOF

            [[ $ANYTLS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
anytls://$UUID@$LOCAL_IP:$ANYTLS_PORT/?insecure=1#$NODE_NAME_1%20anytls

EOF

            [[ $HYSTERIA2_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
hy2://$UUID@$LOCAL_IP:$HYSTERIA2_PORT?insecure=1#$NODE_NAME_1%20hysteria2

EOF

            [[ $TUIC_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
tuic://$UUID:$UUID@$LOCAL_IP:$TUIC_PORT?congestion_control=bbr&alpn=h3&udp_relay_mode=native&allow_insecure=1&disable_sni=1#$NODE_NAME_1%20tuic

EOF

            cat >> sing-box/node.txt << EOF
*******************************************

┌────────────────┐
│                │
│  ShadowRocket  │
│                │
└────────────────┘

EOF
            [[ $VMESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
vmess://\$(echo -n \"none:$UUID@$CDN:443\" | base64 -w0)?remarks=$NODE_NAME_1%20vmess&obfsParam=$ARGO_DOMAIN&path=/$UUID-vmess?ed=2048&obfs=websocket&tls=1&peer=$ARGO_DOMAIN&mux=1&alterId=0

EOF
            [[ $VLESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
vless://\$(echo -n \"auto:$UUID@$CDN:443\" | base64 -w0)?remarks=$NODE_NAME_1%20vless&obfsParam=$ARGO_DOMAIN&path=/$UUID-vless?ed=2048&obfs=websocket&tls=1&peer=$ARGO_DOMAIN&allowInsecure=1&mux=1

EOF

            [[ $REALITY_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
vless://$(echo -n \"auto:$UUID@$LOCAL_IP:$REALITY_PORT\" | base64 -w0)?remarks=$NODE_NAME_1%20reality&obfs=none&tls=1&peer=addons.mozilla.org&mux=1&pbk=$REALITY_PUBLIC

EOF

            [[ $ANYTLS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
anytls://$UUID@$LOCAL_IP:$ANYTLS_PORT?insecure=1&udp=1#$NODE_NAME_1%20anytls

EOF

            [[ $HYSTERIA2_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
hysteria2://$UUID@$LOCAL_IP:$HYSTERIA2_PORT?insecure=1&obfs=none#$NODE_NAME_1%20hysteria2

EOF

            [[ $TUIC_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
tuic://$UUID:$UUID@$LOCAL_IP:$TUIC_PORT?congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#$NODE_NAME_1%20tuic

EOF
            cat >> sing-box/node.txt << EOF
*******************************************

┌────────────────┐
│                │
│   Clash Verge  │
│                │
└────────────────┘

proxies:
EOF
            [[ $VMESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
  - name: \"$NODE_NAME vmess\"
    type: vmess
    server: \"$CDN\"
    port: 443
    uuid: \"$UUID\"
    alterId: 0
    cipher: none
    tls: true
    servername: \"$ARGO_DOMAIN\"
    skip-cert-verify: false
    network: ws
    ws-opts:
      path: \"/$UUID-vmess\"
      headers:
        Host: \"$ARGO_DOMAIN\"
      max-early-data: 2048
      early-data-header-name: Sec-WebSocket-Protocol
    smux:
      enabled: true
      protocol: 'h2mux'
      padding: true
      max-connections: '8'
      min-streams: '16'
      statistic: true
      only-tcp: false
    tfo: false

EOF
            [[ $VLESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
  - name: \"$NODE_NAME vless\"
    type: vless
    server: \"$CDN\"
    port: 443
    uuid: \"$UUID\"
    tls: true
    servername: \"$ARGO_DOMAIN\"
    skip-cert-verify: false
    network: ws
    ws-opts:
      path: \"/$UUID-vless\"
      headers:
        Host: \"$ARGO_DOMAIN\"
      max-early-data: 2048
      early-data-header-name: Sec-WebSocket-Protocol
    smux:
      enabled: true
      protocol: 'h2mux'
      padding: true
      max-connections: '8'
      min-streams: '16'
      statistic: true
      only-tcp: false
    tfo: false

EOF

              [[ $REALITY_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
  - name: \"$NODE_NAME reality\"
    type: vless
    server: $LOCAL_IP
    port: $REALITY_PORT
    uuid: \"$UUID\"
    network: tcp
    udp: true
    tls: true
    client-fingerprint: chrome
    servername: addons.mozilla.org
    reality-opts:
      public-key: $REALITY_PUBLIC
      short-id: \"\"
    smux:
      enabled: true
      protocol: 'h2mux'
      padding: true
      max-connections: '8'
      min-streams: '16'
      statistic: true
      only-tcp: false
    tfo: false

EOF

            [[ $ANYTLS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
  - name: \"$NODE_NAME anytls\"
    type: anytls
    server: $LOCAL_IP
    port: $ANYTLS_PORT
    password: \"$UUID\"
    udp: true
    client-fingerprint: chrome
    idle-session-check-interval: 30
    idle-session-timeout: 30
    skip-cert-verify: true

EOF

            [[ $HYSTERIA2_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
  - name: \"$NODE_NAME hysteria2\"
    type: hysteria2
    server: $LOCAL_IP
    port: $HYSTERIA2_PORT
    password: \"$UUID\"
    up: \"200 Mbps\"
    down: \"1000 Mbps\"
    skip-cert-verify: true

EOF

            [[ $TUIC_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
  - name: \"$NODE_NAME tuic\"
    type: tuic
    server: $LOCAL_IP
    port: $TUIC_PORT
    uuid: \"$UUID\"
    password: \"$UUID\"
    alpn:
      - h3
    disable-sni: true
    reduce-rtt: true
    request-timeout: 8000
    udp-relay-mode: native
    congestion-controller: bbr
    skip-cert-verify: true

EOF
            cat >> sing-box/node.txt << EOF
*******************************************

┌────────────────┐
│                │
│    Sing-box    │
│                │
└────────────────┘

{
    \"outbounds\": [
        {
EOF

            [[ $VMESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
            \"tag\": \"$NODE_NAME vmess\",
            \"type\": \"vmess\",
            \"server\": \"$CDN\",
            \"server_port\": 443,
            \"uuid\": \"$UUID\",
            \"alter_id\": 0,
            \"security\": \"none\",
            \"network\": \"tcp\",
            \"tcp_fast_open\": false,
            \"transport\": {
                \"type\": \"ws\",
                \"path\": \"/$UUID-vmess\",
                \"headers\": {
                    \"Host\": \"$ARGO_DOMAIN\"
                }
            },
            \"tls\": {
                \"enabled\": true,
                \"insecure\": false,
                \"server_name\": \"$ARGO_DOMAIN\",
                \"utls\": {
                    \"enabled\": true,
                    \"fingerprint\": \"chrome\"
                }
            },
            \"multiplex\": {
                \"enabled\": true,
                \"protocol\": \"h2mux\",
                \"max_streams\": 16,
                \"padding\": true
            }
        },
EOF

            [[ $VLESS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
        {
            \"type\": \"vless\",
            \"tag\": \"$NODE_NAME vless\",
            \"server\": \"$CDN\",
            \"server_port\": 443,
            \"uuid\": \"$UUID\",
            \"network\": \"tcp\",
            \"tcp_fast_open\": false,
            \"tls\": {
                \"enabled\": true,
                \"insecure\": false,
                \"server_name\": \"$ARGO_DOMAIN\",
                \"utls\": {
                    \"enabled\": true,
                    \"fingerprint\": \"chrome\"
                }
            },
            \"multiplex\": {
                \"enabled\": true,
                \"protocol\": \"h2mux\",
                \"max_streams\": 16,
                \"padding\": true
            }
        },
EOF

            [[ $REALITY_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
        {
            \"type\": \"vless\",
            \"tag\": \"$NODE_NAME xtls-reality\",
            \"server\": \"$LOCAL_IP\",
            \"server_port\": $REALITY_PORT,
            \"uuid\": \"$UUID\",
            \"flow\": \"\",
            \"packet_encoding\": \"xudp\",
            \"tls\": {
                \"enabled\": true,
                \"server_name\": \"addons.mozilla.org\",
                \"utls\": {
                    \"enabled\": true,
                    \"fingerprint\": \"chrome\"
                },
                \"reality\": {
                    \"enabled\": true,
                    \"public_key\": \"$REALITY_PRIVATE\",
                    \"short_id\": \"\"
                }
            },
            \"multiplex\": {
                \"enabled\": true,
                \"protocol\": \"h2mux\",
                \"max_connections\": 8,
                \"min_streams\": 16,
                \"padding\": true,
                \"brutal\": {
                    \"enabled\": false,
                    \"up_mbps\": 1000,
                    \"down_mbps\": 1000
                }
            }
        },
EOF

            [[ $ANYTLS_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
        {
            \"type\": \"anytls\",
            \"tag\": \"$NODE_NAME anytls\",
            \"server\": \"$LOCAL_IP\",
            \"server_port\": $ANYTLS_PORT,
            \"password\": \"$UUID\",
            \"idle_session_check_interval\": \"30s\",
            \"idle_session_timeout\": \"30s\",
            \"min_idle_session\": 5,
            \"tls\": {
                \"enabled\": true,
                \"insecure\": true,
                \"server_name\": \"\"
            }
        },
EOF

            [[ $HYSTERIA2_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
        {
            \"type\": \"hysteria2\",
            \"tag\": \"$NODE_NAME hysteria2\",
            \"server\": \"$LOCAL_IP\",
            \"server_port\": $HYSTERIA2_PORT,
            \"up_mbps\": 200,
            \"down_mbps\": 1000,
            \"password\": \"$UUID\",
            \"tls\": {
                \"enabled\": true,
                \"insecure\": true,
                \"server_name\": \"\",
                \"alpn\": [
                    \"h3\"
                ]
            }
        },
EOF

            [[ $TUIC_PORT =~ [0-9]+ ]] && cat >> sing-box/node.txt << EOF
        {
            \"type\": \"tuic\",
            \"tag\": \"$NODE_NAME tuic\",
            \"server\": \"$LOCAL_IP\",
            \"server_port\": $TUIC_PORT,
            \"uuid\": \"$UUID\",
            \"password\": \"$UUID\",
            \"congestion_control\": \"bbr\",
            \"udp_relay_mode\": \"native\",
            \"zero_rtt_handshake\": false,
            \"heartbeat\": \"10s\",
            \"tls\": {
                \"enabled\": true,
                \"insecure\": true,
                \"server_name\": \"\",
                \"alpn\": [
                    \"h3\"
                ]
            }
        },
EOF
            sed -i '$s/,$//g' sing-box/node.txt
            cat >> sing-box/node.txt << EOF
    ]
}
EOF

            [ -s sing-box/local_frpc.toml ] && rm -rf sing-box/local_frpc.toml
            [[ -n $FRP_SERVER_ADDR && -n $FRP_SERVER_PORT ]] && cat > sing-box/local_frpc.toml << EOF
serverAddr = \"$FRP_SERVER_ADDR\"
serverPort = $FRP_SERVER_PORT
loginFailExit = false

# 认证配置
auth.method = \"token\"
auth.token = \"$FRP_AUTH_TOKEN\"

# 传输配置
transport.heartbeatInterval = 10
transport.heartbeatTimeout = 30
transport.dialServerKeepalive = 10
transport.dialServerTimeout = 30
transport.tcpMuxKeepaliveInterval = 10
transport.poolCount = 5

EOF

            [[ $REALITY_PORT =~ [0-9]+ ]] && cat >> sing-box/local_frpc.toml << EOF
[[visitors]]
name = \"$NODE_NAME reality_visitor\"
type = \"xtcp\"
serverName = \"$WORKSPACE_SLUG-reality\"
secretKey = \"$UUID\"
bindAddr = \"0.0.0.0\"
bindPort = $REALITY_PORT
keepTunnelOpen = true

EOF

            [[ $ANYTLS_PORT =~ [0-9]+ ]] && cat >> sing-box/local_frpc.toml << EOF
[[visitors]]
name = \"$NODE_NAME anytls_visitor\"
type = \"xtcp\"
serverName = \"$WORKSPACE_SLUG-anytls\"
secretKey = \"$UUID\"
bindAddr = \"0.0.0.0\"
bindPort = $ANYTLS_PORT
keepTunnelOpen = true

EOF

            [[ $HYSTERIA2_PORT =~ [0-9]+ ]] && cat >> sing-box/local_frpc.toml << EOF
[[visitors]]
name = \"$NODE_NAME hysteria_visitor\"
type = \"sudp\"
serverName = \"$WORKSPACE_SLUG-hysteria2\"
secretKey = \"$UUID\"
bindAddr = \"0.0.0.0\"
bindPort = $HYSTERIA2_PORT

EOF

            [[ $TUIC_PORT =~ [0-9]+ ]] && cat >> sing-box/local_frpc.toml << EOF
[[visitors]]
name = \"$NODE_NAME tuic_visitor\"
type = \"sudp\"
serverName = \"$WORKSPACE_SLUG-tuic\"
secretKey = \"$UUID\"
bindAddr = \"0.0.0.0\"
bindPort = $TUIC_PORT

EOF
          fi";

        # 检查并创建 docker compose 配置文件
        init-02-compose = "
          # 根据 ARGO_AUTH 的内容，自行判断是 Json 还是 Token
          if [[ $ARGO_AUTH =~ TunnelSecret ]]; then
            ARGO_ARGS=\"tunnel --edge-ip-version 4 --config /etc/cloudflared/tunnel.yml run\"
          elif [[ $ARGO_AUTH =~ .*[a-z0-9=]{120,250}$ ]]; then
            ARGO_TOKEN=$(awk '{print $NF}' <<< \"$ARGO_AUTH\")
            ARGO_ARGS=\"tunnel --edge-ip-version 4 run --token $ARGO_TOKEN\"
          fi

          cat > docker-compose.yml << 'EOF'
services:
EOF
          [[ $DEBIAN_REMOTE_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  debian:
    image: debian:latest
    container_name: debian
    hostname: debian
    networks:
      - idx
    volumes:
      - debian_data:/data
    tty: true
    restart: unless-stopped
    command: |
      bash -c \"
        export DEBIAN_FRONTEND=noninteractive &&
        apt update && apt install -y openssh-server iproute2 &&
        echo \"root:$SSH_PASSWORD\" | chpasswd &&
        sed -i 's/#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        mkdir -p /var/run/sshd &&
        service ssh start &&
        tail -f /dev/null
      \"

EOF
          [[ $UBUNTU_REMOTE_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  ubuntu:
    image: ubuntu:latest
    container_name: ubuntu
    hostname: ubuntu
    networks:
      - idx
    volumes:
      - ubuntu_data:/data
    tty: true
    restart: unless-stopped
    command: |
      bash -c \"
        export DEBIAN_FRONTEND=noninteractive &&
        apt update && apt install -y openssh-server &&
        echo \"root:$SSH_PASSWORD\" | chpasswd &&
        sed -i 's/#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        mkdir -p /var/run/sshd &&
        service ssh start &&
        tail -f /dev/null
      \"

EOF
          [[ $CENTOS_REMOTE_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  centos9:
    image: quay.io/centos/centos:stream9
    container_name: centos9
    hostname: centos9
    networks:
      - idx
    volumes:
      - centos9_data:/data
    tty: true
    restart: unless-stopped
    command: |
      sh -c \"
        dnf install -y openssh-server passwd iproute procps-ng &&
        echo \"root:$SSH_PASSWORD\" | chpasswd &&
        mkdir -p /run/sshd &&
        ssh-keygen -A &&
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        /usr/sbin/sshd -D &
        tail -f /dev/null
      \"

EOF
          [[ $ALPINE_REMOTE_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  alpine:
    image: alpine:latest
    container_name: alpine
    hostname: alpine
    networks:
      - idx
    volumes:
      - alpine_data:/data
    tty: true
    restart: unless-stopped
    command: |
      sh -c \"
        apk update && apk add --no-cache openssh-server openssh-sftp-server &&
        echo \"root:$SSH_PASSWORD\" | chpasswd &&
        sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        mkdir -p /run/sshd &&
        ssh-keygen -A &&
        /usr/sbin/sshd &&
        tail -f /dev/null
      \"

EOF

          [[ -n $FRP_SERVER_ADDR && $FRP_SERVER_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  frpc:
    image: snowdreamtech/frpc
    container_name: frpc
    networks:
      - idx
    volumes:
      - ./conf/frpc.toml:/frp/frpc.toml:ro
    command: -c /frp/frpc.toml
    restart: unless-stopped

EOF

          if [[ $VMESS_PORT$VLESS_PORT$REALITY_PORT$HYSTERIA2_PORT$TUIC_PORT =~ [0-9]+ ]]; then
            grep -q '.' <<< $ARGO_ARGS && cat >> docker-compose.yml << EOF
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    command: $ARGO_ARGS
    networks:
      - idx
    volumes:
      - ./conf/tunnel.yml:/etc/cloudflared/tunnel.yml:ro
      - ./conf/tunnel.json:/etc/cloudflared/tunnel.json:ro
    restart: unless-stopped

EOF

            cat >> docker-compose.yml << 'EOF'
  sing-box:
    image: fscarmen/sing-box:pre
    container_name: sing-box
    networks:
      - idx
    volumes:
      - ./sing-box:/etc/sing-box
    command: run -c /etc/sing-box/config.json
    restart: unless-stopped

EOF
            [[ $NGINX_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  nginx:
    image: nginx:alpine
    container_name: nginx
    networks:
      - idx
    volumes:
      - ./sing-box/node.txt:/data/node.txt:ro
      - ./sing-box/nginx.conf:/etc/nginx/nginx.conf:ro
    restart: unless-stopped

EOF
          fi

          grep -q '.' <<< $NEZHA_SERVER && cat >> docker-compose.yml << EOF
  nezha-agent:
    image: fscarmen/nezha-agent:latest
    container_name: nezha-agent
    pid: host        # 使用主机 PID 命名空间
    volumes:
      - /:/host:ro     # 挂载主机根目录
      - /proc:/host/proc:ro  # 挂载主机进程信息
      - /sys:/host/sys:ro    # 挂载主机系统信息
      - /etc:/host/etc:ro    # 挂载主机配置
    environment:
      - NEZHA_SERVER=$NEZHA_SERVER
      - NEZHA_PORT=$NEZHA_PORT
      - NEZHA_KEY=$NEZHA_KEY
      - NEZHA_TLS=$NEZHA_TLS
    command: -s $NEZHA_SERVER:$NEZHA_PORT -p $NEZHA_KEY $NEZHA_TLS
    restart: unless-stopped

EOF

          cat >> docker-compose.yml << 'EOF'
networks:
  idx:
    driver: bridge
EOF

          [[ $DEBIAN_REMOTE_PORT =~ [0-9]+ ]] || [[ $UBUNTU_REMOTE_PORT =~ [0-9]+ ]] || [[ $CENTOS_REMOTE_PORT =~ [0-9]+ ]] || [[ $ALPINE_REMOTE_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'

volumes:
EOF
          [[ $DEBIAN_REMOTE_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  debian_data:
EOF
          [[ $UBUNTU_REMOTE_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  ubuntu_data:
EOF
          [[ $CENTOS_REMOTE_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  centos9_data:
EOF
          [[ $ALPINE_REMOTE_PORT =~ [0-9]+ ]] && cat >> docker-compose.yml << 'EOF'
  alpine_data:
EOF";

        # 检查并创建 frpc 配置
        init-02-frpc = "[[ ! $UUID =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ && -s conf/uuid.txt ]] && UUID=$(cat conf/uuid.txt)
          [[ -n $FRP_SERVER_ADDR && $FRP_SERVER_PORT =~ [0-9]+ ]] && cat > frpc.toml << EOF
# 通用配置
serverAddr = \"$FRP_SERVER_ADDR\"
serverPort = $FRP_SERVER_PORT
loginFailExit = false

# 认证配置
auth.method = \"token\"
auth.token = \"$FRP_AUTH_TOKEN\"

# 传输配置
transport.heartbeatInterval = 10
transport.heartbeatTimeout = 30
transport.dialServerKeepalive = 10
transport.dialServerTimeout = 30
transport.tcpMuxKeepaliveInterval = 10
transport.poolCount = 5

# 代理配置
EOF
          [[ $DEBIAN_REMOTE_PORT =~ [0-9]+ ]] && cat >> frpc.toml << EOF
[[proxies]]
name = \"$WORKSPACE_SLUG-debian_ssh\"
type = \"tcp\"
localIP = \"debian\"
localPort = 22
remotePort = $DEBIAN_REMOTE_PORT

EOF
          [[ $UBUNTU_REMOTE_PORT =~ [0-9]+ ]] && cat >> frpc.toml << EOF
[[proxies]]
name = \"$WORKSPACE_SLUG-ubuntu_ssh\"
type = \"tcp\"
localIP = \"ubuntu\"
localPort = 22
remotePort = $UBUNTU_REMOTE_PORT

EOF
          [[ $CENTOS_REMOTE_PORT =~ [0-9]+ ]] && cat >> frpc.toml << EOF
[[proxies]]
name = \"$WORKSPACE_SLUG-centos9_ssh\"
type = \"tcp\"
localIP = \"centos9\"
localPort = 22
remotePort = $CENTOS_REMOTE_PORT

EOF
          [[ $ALPINE_REMOTE_PORT =~ [0-9]+ ]] && cat >> frpc.toml << EOF
[[proxies]]
name = \"$WORKSPACE_SLUG-alpine_ssh\"
type = \"tcp\"
localIP = \"alpine\"
localPort = 22
remotePort = $ALPINE_REMOTE_PORT

EOF

          [[ $REALITY_PORT =~ [0-9]+ ]] && cat >> frpc.toml << EOF
[[proxies]]
name = \"$WORKSPACE_SLUG-reality\"
type = \"xtcp\"
secretKey = \"$UUID\"
localIP = \"sing-box\"
localPort = $REALITY_PORT

EOF

          [[ $ANYTLS_PORT =~ [0-9]+ ]] && cat >> frpc.toml << EOF
[[proxies]]
name = \"$WORKSPACE_SLUG-anytls\"
type = \"xtcp\"
secretKey = \"$UUID\"
localIP = \"sing-box\"
localPort = $ANYTLS_PORT

EOF

          [[ $HYSTERIA2_PORT =~ [0-9]+ ]] && cat >> frpc.toml << EOF
[[proxies]]
name = \"$WORKSPACE_SLUG-hysteria2\"
type = \"sudp\"
secretKey = \"$UUID\"
localIP = \"sing-box\"
localPort = $HYSTERIA2_PORT

EOF

          [[ $TUIC_PORT =~ [0-9]+ ]] && cat >> frpc.toml << EOF
[[proxies]]
name = \"$WORKSPACE_SLUG-tuic\"
type = \"sudp\"
secretKey = \"$UUID\"
localIP = \"sing-box\"
localPort = $TUIC_PORT

EOF

    # 把 frpc 配置文件移到 conf 工作目录
    rm -rf conf/frpc.toml
    mv frpc.toml conf/";

        # 启动服务（在初始化完成后）
        start-compose = "docker compose up -d";
        start-node = "cat sing-box/node.txt";
      };
    };
  };
}
