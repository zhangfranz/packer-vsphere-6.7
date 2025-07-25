### Packer-Vsphere-6.7
- Auto create vm template by packer via static ip address.
- Date: 2025-07-25

### Version：
- Packer verison: v1.0
- OS system version: Ubuntu-22.04

### Command：
- 初始化
```code
packer init ubuntu-22.04-tpl.pkr.hcl
```
- 效验配置是否正确
```code
packer validate ubuntu-22.04-tpl.pkr.hcl
```
- 开始构建镜像或者模板
```code
packer build ubuntu-22.04-tpl.pkr.hcl
```
- 开启构建debug模式
```code
packer build -debug ubuntu-22.04-tpl.pkr.hcl
```

### Function：
- APT私有源支持
- 网卡配置支持(去除cloud-init的预配置)
- 磁盘分区配置支持(bios\boot\swap\root分区)
- 默认账户配置（app/Packer123!;app免密切root权限;开启root远程登录）
- 系统描述符Limit优化配置
- NTP预装配置(配置公司NTP私有时间同步地址)
- 静默预装基础组件包(iputils-ping telnet net-tools dnsutils nmap htop iotop iftop vim wget tree parted expect open-vm-tools cron tcpdump tmux ntp ntpdate)
- 支持不依赖DHCP的静态IP和DNS注入
- 支持离线ISO注入

### File Hierarchy：
```code
./http
├── meta-data
└── user-data
./release.md
./ubuntu-22.04-tpl.pkr.hcl
```
