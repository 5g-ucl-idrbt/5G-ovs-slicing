# 5G-ovs-integration
### in spgwu ###
```
sysctl net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT
ip route add default via 10.0.0.2 dev <dev_name> 
ip route del default via 192.168.70.129 dev eth0 
```
