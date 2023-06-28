# 5G-ovs-integration
## refer these links to setup core (in VM) and gNB (bear metal)
core: https://github.com/subhrendu1987/oai-core
gNB: https://github.com/subhrendu1987/oai-gnodeb-b210
## adding ovs file to oai-setup
```
clone the repo and paste the docker-compose file in the oai-core/docker-compose path
``` 
## in core
```
cd oai-core/docker-compose
sudo docker compose -f docker-compose-basic-nrf-ovs.yaml up -d
```
### in spgwu ###
```
sysctl net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT
ip route add default via 10.0.0.2 dev <dev_name> 
ip route del default via 192.168.70.129 dev eth0 
```
