### Packer-Vsphere-6.7
- Auto create vm template by packer via static ip address.

### Version：
- v1.0

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

### Release：
- 1.模板机构建完成
- 2.网卡配置正常写入(通过模板创建虚拟机的时候，会有多个网卡文件存在的问题)
- 3.磁盘配置生效(bios boot 只有1m大小)
- 4.APT源更新生效（main\updates\security）全部生效----问题已解决
- 5."app"用户被创建，且可免密登录 ----问题已解决
- 6.基础必要软件安装htop、vim这些 ----问题已解决

### Network Configuration：
```code
# write_files:
# - path: /etc/netplan/00-installer-config.yaml
#   content: |
#     # This is the network config written by 'subiquity'
#     network:
#       version: 2
#       ethernets:
#         ens33:
#           addresses:
#           - 172.16.1.250/24           
#           routes:
#           - to: default
#             via: 172.16.1.254
#           nameservers:
#             addresses:
#             - 114.114.114.114
#             search: []
```
