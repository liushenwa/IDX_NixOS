# IDX 多容器代理服务部署项目
Documentation: [English version](https://github.com/fscarmen2/IDX_NixOS/blob/main/README_EN.md) | 中文版

## 目录
- [项目概述](#项目概述)
- [项目特点](#项目特点)
- [项目组件详解](#项目组件详解)
  - [容器环境](#1-容器环境)
  - [网络代理服务](#2-网络代理服务)
  - [网络穿透服务](#3-网络穿透服务)
  - [监控服务](#4-监控服务)
- [部署步骤](#部署步骤)
  - [下载项目](#1-下载项目)
  - [修改配置](#2-修改配置)
  - [保存文件](#3-保存文件)
  - [部署到 IDX](#4-部署到-idx)
  - [验证部署](#5-验证部署)
  - [注意事项](#注意事项)
- [OpenWrt FRPC 快速部署](#openwrt-frpc-快速部署)
  - [OpenWRT 部署步骤](#openwrt-部署步骤)
  - [卸载](#卸载)
  - [OpenWRT 注意事项](#openwrt-注意事项)

## 项目概述

本项目是一个基于 IDX 开发环境的多容器代理服务部署解决方案，集成了多种网络工具和服务，包括 Sing-Box、Cloudflare Argo Tunnel、FRP 内网穿透以及多种 Linux 容器环境。项目通过 Nix 配置文件自动化部署和管理，提供了一套完整的网络代理和远程访问解决方案。

## 项目特点

1. **多容器环境**：同时部署 Debian、Ubuntu、CentOS 和 Alpine 四种 Linux 容器
2. **网络代理服务**：集成 Sing-Box 提供6种协议支持
3. **内网穿透**：通过 Cloudflare Argo Tunnel 和 FRP 实现内网服务的外网访问
4. **服务监控**：集成哪吒监控 (Nezha) 代理，实时监控服务状态
5. **自动化部署**：利用 IDX 的 Nix 配置实现一键部署和启动
6. **安全访问**：所有容器均配置 SSH 远程访问，支持密码认证

## 项目组件详解

### 1. 容器环境

项目部署了四种主流 Linux 容器，每个容器都配置了 SSH 服务，可通过密码远程登录：

- **Debian**：通用 Linux 环境，适合大多数应用部署
- **Ubuntu**：友好的用户界面，丰富的软件包支持
- **CentOS 9**：企业级稳定性，适合长期运行的服务
- **Alpine**：轻量级容器，占用资源少

### 2. 网络代理服务

使用 Sing-Box 提供高性能的网络代理服务：

- **协议支持**：VMess + WebSocket + TLS， VLESS + WebSocket + TLS， VLESS + Reality，AnyTLS，Hysteria2，TUIC
- **多客户端支持**：自动生成 Clash、V2rayN、NekoBox、Shadowrocket 和 SingBox 配置

### 3. 网络穿透服务

- **Cloudflare Argo Tunnel**：将内部服务安全暴露到公网，无需公网 IP
- **FRP 内网穿透**：为每个容器的 SSH 服务提供外网访问端口

### 4. 监控服务

- **哪吒监控 (Nezha)**：实时监控服务器状态，包括 CPU、内存、网络等指标

## 通过 IDX 的 import 文件部署

为了更好地管理配置，您可以将配置拆分为多个文件，然后通过 IDX 的 import 功能导入。这种方法有以下优点：

1. **模块化配置**：将大型配置文件拆分为更小、更易管理的部分
2. **环境隔离**：可以为不同环境（开发、测试、生产）创建不同的配置
3. **配置重用**：共享配置可以在多个项目中重用
          
### 部署步骤

1. **下载项目**
   - 下载项目压缩包文件到本地

2. **修改配置**
   - 打开 `.idx/dev.nix` 文件
   - 根据文件中的注释说明修改相应参数
   - **重要提示**：除了 `env` 区域外的其他配置，建议初学者保持默认设置，避免出错

3. **保存文件**
   - 保存修改后的 `.idx/dev.nix` 文件
   - 确保压缩包中包含所有必要文件

4. **部署到 IDX**
   - 访问 https://idx.google.com
   - 创建新的 `custom workspace`
   - 上传修改后的项目压缩包
   - 等待约 2 分钟，系统将自动完成部署

5. **验证部署**
   - 部署完成后，可以通过配置的域名访问服务
   - 使用配置的端口和密码访问各个容器
   - 查看哪吒监控面板确认服务状态

### 注意事项
- 请确保修改的参数格式正确，保持引号完整
- 敏感信息（如密码、令牌）建议使用强密码
- 部署完成后请及时测试所有服务是否正常运行

## OpenWrt FRPC 快速部署

本项目提供了一键部署脚本，可以在 OpenWrt 系统上快速部署和管理 FRP 客户端。

### OpenWRT 部署步骤

1. **下载并执行安装脚本**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/fscarmen2/IDX_NIXOS/main/install-frpc.sh)
```

2. **配置 FRPC**
   - 脚本会提示您输入 FRPC 配置内容
   - 输入完成后按 Ctrl+D 保存

3. **服务管理**
   - 启动服务：`/etc/init.d/idx-frpc start`
   - 停止服务：`/etc/init.d/idx-frpc stop`
   - 重启服务：`/etc/init.d/idx-frpc restart`

### 卸载

如需卸载 FRPC 服务，只需执行以下命令：
```bash
uninstall-idx-frpc
```

此命令会：
- 停止 FRPC 服务
- 删除所有配置文件
- 移除服务脚本
- 清理日志文件

### OpenWRT 注意事项

1. 确保系统已安装 curl 或 wget
2. 配置文件会保存在 `/etc/frpc/idx-frpc.toml`
3. 日志文件位置：`/var/log/idx-frpc.log`
4. 支持配置文件热重载
5. 进程异常退出会自动重启