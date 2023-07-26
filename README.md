# 5G-ovs-integration
## Refer these links to setup core (in VM) and gNB (Bare-metal)
* [core:](https://github.com/subhrendu1987/oai-core)
* [gNB:](https://github.com/subhrendu1987/oai-gnodeb-b210)
## Adding ovs file to oai-setup
```
clone the repo and paste the docker-compose file and createLink.sh file in the oai-core/docker-compose path
``` 
## In core
```
sudo docker pull openvswitch/ovs:2.11.2_debian
sudo docker tag openvswitch/ovs:2.11.2_debian openvswitch/ovs:latest

cd oai-core/docker-compose
sudo docker compose -f docker-compose-basic-nrf-ovs.yaml up -d
sudo docker ps -a
```
## In gnb
```
sudo docker compose -f ci-scripts/yaml_files/sa_b200_gnb/docker-compose.yml up -d
sudo docker ps -a
```
## In core

   * Create Links
```
sudo bash createLink.sh oai-spgwu s1
sudo bash createLink.sh tomcat s1
sudo bash createLink.sh router s1
```
   * Create bridge in s1
```
sudo docker exec s1 ovs-vsctl add-br br0
sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}'   ## List interface names; Use Outputs as inputs of next CMD separately
sudo docker exec s1 ovs-vsctl add-port br0 <INTF1>
sudo docker exec s1 ovs-vsctl add-port br0 <INTF2>
sudo docker exec s1 ovs-vsctl add-port br0 <INTF3>
sudo docker exec s1 ovs-vsctl set-fail-mode br0 secure
```
   * Add IP to oai-spgwu and tomcat
```
C1_IF=$(sudo ip netns exec oai-spgwu ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec oai-spgwu ip a add 10.0.0.1/24 dev ${C1_IF}
C2_IF=$(sudo ip netns exec tomcat ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec tomcat ip a add 10.0.0.2/24 dev ${C2_IF}
C3_IF=$(sudo ip netns exec router ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec router ip a add 10.0.0.3/24 dev ${C3_IF}

sudo ip netns exec oai-spgwu ip r add 10.0.0.3/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec oai-spgwu ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec tomcat ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C2_IF}
sudo ip netns exec router ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C3_IF}
```

* Add controller to the ovs
```
sudo docker exec s1 ovs-vsctl set-controller br0 tcp:172.18.0.4:6653
```
* Inside the ryu container
```
sudo docker exec -it ryu bash
cd ryu/ryu/app
ryu-manager --observe-links simple_switch.py 
```

## In spgwu 
```
sudo docker exec -it oai-spgwu bash
```
```
apt update
apt install -y iputils-ping
apt install -y tcpdump
apt install -y iproute2
apt install -y iptables
```
```
sysctl net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT
ip route del default via 192.168.70.129 dev eth0
ifconfig #copy the port name starting with dcp and paste it in the <dev_name> in nextline
ip route add default via 10.0.0.3 dev <dev_name> #this will help UE to reach the internet through the router pc 
 
```
## Inside the tomcat docker
```
sudo docker exec -it tomcat bash
```
```
apt update
apt install -y iputils-ping
apt install -y tcpdump
apt install -y iproute2
apt install -y iptables
apt install -y net-tools
```
```
ip route del default via 192.168.70.129 dev eth0
ip route add 12.1.1.0/24 via 192.168.70.134 dev eth0

```
## Inside the router docker
```
sudo docker exec -it router bash
```
```
apt update
apt install -y iputils-ping
apt install -y tcpdump
apt install -y iproute2
apt install -y iptables
apt install -y net-tools
```
```
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
ip route add 12.1.1.0/24 via 192.168.70.134 dev eth0
```
## Test to check if the ovs is properly configured
```
sudo docker exec oai-spgwu ping -c3 10.0.0.2
sudo docker exec oai-spgwu ping -c3 10.0.0.3
sudo docker exec tomcat ping -c3 10.0.0.1
sudo docker exec router ping -c3 10.0.0.1
```
## Test to check if the UE is able to hit the internet and tomcat server
```
##in UE
ping 8.8.8.8 # to check the connectivity to the internet
ping 10.0.0.1 # pinging spgwu
ping 10.0.0.2 # pinging tomcat
ping 10.0.0.3 # pingindg router
curl 192.168.138.224:8888 # to check the connectivity to the server
```
## To verify that the UE is going through the router towards the internet
```
sudo docker exec -it router bash
ifconfig 
tcpdump -i <interface_name> #interface starting with dcp 
```
## To verify that the UE is reaching the server
```
sudo docker exec -it tomcat bash
ifconfig
tcpdump -i <interface_name> #interface starting with dcp
```
