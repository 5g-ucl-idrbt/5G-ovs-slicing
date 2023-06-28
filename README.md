# 5G-ovs-integration
## refer these links to setup core (in VM) and gNB (bear metal)
core: https://github.com/subhrendu1987/oai-core
gNB: https://github.com/subhrendu1987/oai-gnodeb-b210
## adding ovs file to oai-setup
```
clone the repo and paste the docker-compose file and createLink.sh file in the oai-core/docker-compose path
``` 
## in core
```
sudo docker pull openvswitch/ovs:2.11.2_debian
sudo docker tag openvswitch/ovs:2.11.2_debian openvswitch/ovs:latest
sudo docker pull osrg/ryu
sudo docker pull tomcat
cd oai-core/docker-compose
sudo docker compose -f docker-compose-basic-nrf-ovs.yaml up -d
sudo docker ps -a
```
## in gnb
```
sudo docker compose -f ci-scripts/yaml_files/sa_b200_gnb/docker-compose.yml up -d
sudo docker ps -a
```
## in core

    * Create Links
```
sudo bash createLink.sh oai-spgwu s1
sudo bash createLink.sh h2 s1
```
   * Create bridge in s1
```
sudo docker exec s1 ovs-vsctl add-br br0
sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}'   ## List interface names; Use Outputs as inputs of next CMD separately
sudo docker exec s1 ovs-vsctl add-port br0 <INTF1>
sudo docker exec s1 ovs-vsctl add-port br0 <INTF2>
sudo docker exec s1 ovs-vsctl set-fail-mode br0 secure
```
   * Add IP to h1 and h2
```
C1_IF=$(sudo ip netns exec h1 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec h1 ip a add 10.0.0.1/30 dev ${C1_IF}
C2_IF=$(sudo ip netns exec h2 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec h2 ip a add 10.0.0.2/30 dev ${C2_IF}
sudo ip netns exec h1 ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec h2 ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C2_IF}
```

* Add controller to the ovs
```
sudo docker exec s1 ovs-vsctl set-controller br0 tcp:172.18.0.4:6653
```
* Inside the ryu container
```
cd ryu/ryu/app
ryu-manager --observe-links simple_switch.py 
```
* Test
```
sudo docker exec h1 ping -c3 10.0.0.2
sudo docker exec h2 ping -c3 10.0.0.1
```
### in spgwu ###
```
sysctl net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT
ip route add default via 10.0.0.2 dev <dev_name> 
ip route del default via 192.168.70.129 dev eth0 
```
