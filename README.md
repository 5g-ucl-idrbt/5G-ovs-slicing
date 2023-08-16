# 5G-ovs-integration with MEC & slicing capability

## Refer these links to setup core and Physical gNB
In developv4 branch we are using physical devices to test the setup core version v1.5.1, while developv2 and developv3 use simulated environment. 
In the develop branch we are using version 1.4.0 of OAI core. Here in developv2 and developv3 we are using version 1.5.1 from master branch.

for core: ```https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed``` 

```
cd
git clone https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed.git
```
## Adding ovs file to oai-setup
Clone the repo and paste the docker-compose file and createLink.sh file in the oai-cn5g-fed/docker-compose path
```
cd
git clone https://github.com/abhic137/5G-ovs-integration.git
cd 5G-ovs-integration
git branch -a
git checkout developv4
cd 5G-ovs-integration/docker-compose
cp run.sh createLink.sh docker-compose-basic-nrf-ovs.yaml ~/oai-cn5g-fed/docker-compose
cp oai_db3.sql ~/oai-cn5g-fed/docker-compose/database

``` 
## In core
```
sudo docker pull openvswitch/ovs:2.11.2_debian
sudo docker tag openvswitch/ovs:2.11.2_debian openvswitch/ovs:latest
```
```
cd oai-cn5g-fed/docker-compose
sudo docker compose -f docker-compose-basic-nrf-ovs.yaml up -d
sudo docker ps -a
```
## Run the script file to create bridge, connections and to add IPs & routes 
```
cd oai-cn5g-fed/docker-compose
chmod +x run.sh
sudo ./run.sh
```
<!--
   * Create Links
```
sudo bash createLink.sh oai-spgwu s1
sudo bash createLink.sh server s1
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
sudo ip netns exec server ip a add 10.0.0.2/24 dev ${C2_IF}
C3_IF=$(sudo ip netns exec router ifconfig -a | grep -E "dcp.*"| awk -F':' '{print $1}')
sudo ip netns exec router ip a add 10.0.0.3/24 dev ${C3_IF}

sudo ip netns exec oai-spgwu ip r add 10.0.0.3/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec oai-spgwu ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec server ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C2_IF}
sudo ip netns exec router ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C3_IF}
```

* Add controller to the ovs
```
sudo docker exec s1 ovs-vsctl set-controller br0 tcp:172.18.0.4:6653
```
-->
## Running the Ryu code
* Inside the ryu container
  Here we are running a simple switch program, we can run any custom program in the same manner.
```
sudo docker exec ryu ryu-manager --observe-links ryu/ryu/app/simple_switch.py 
```
OR
```
sudo docker exec -it ryu bash
cd ryu/ryu/app
ryu-manager --observe-links simple_switch.py 
```
# Slicing
## For running the slicing code go to ryu docker
```
sudo docker exec -it ryu bash
cd ryu/ryu/app
```
Before running the ryu code, change the IP address of the server and router in the code. And also change the MAC addresses accordingly. to take IP and mac address of the server,router & oai-spgwu
On line no 105 change MAC address of server(10.0.0.2) On line no 106 change MAC address of server(10.0.0.2) On line no 124 change MAC address of router(10.0.0.3) On line no 125 change MAC address of oai-spgwu

in the ryu docker 
```
nano ryucode.py

```
In the other terminal copy the MACs of the server,router and spgwu and paste it in the ryucode.py
```
sudo docker exec server ifconfig
```
```
sudo docker exec router ifconfig
```
```
sudo docker exec oai-spgwu ifconfig
```
In order to run the RYU code
```
ryu-manager --observe-links ryucode.py 

```
<!--
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
## Inside the server docker
```
sudo docker exec -it server bash
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
ifconfig # copy the dcp dev name
ip route add 12.1.1.0/24 via 10.0.0.1 dev <DEV_NAME>

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
ifconfig # copy the dcp dev name
ip route add 12.1.1.0/24 via 10.0.0.1 dev <DEV_NAME>

```
-->
## For getting internet connection in the UE
```
sudo docker exec -it router bash
ifconfig
iptables -A FORWARD -i <dcp_INT> -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o <dcp_INT> -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

```
## Test to check if the ovs is properly configured
```
sudo docker exec oai-spgwu ping -c3 10.0.0.2
sudo docker exec oai-spgwu ping -c3 10.0.0.3
sudo docker exec server ping -c3 10.0.0.1
sudo docker exec router ping -c3 10.0.0.1
```
## Hosting a simple python server in server docker
```
sudo docker exec server python3 -m http.server 9999
```
OR
```
sudo docker exec -it server bash

python3 -m http.server 9999


```
## Commmands to be executed in Core VM in order to connect to the gNB
```
sudo sysctl net.ipv4.ip_forward=1
sudo iptables -P FORWARD ACCEPT
sudo ip route add 192.168.71.194 via <GNB Baremetal IP>
sudo ip route add 12.1.1.0/24 via 192.168.70.134 # Forward packets to Mobiles from external sources
```
To check if the devices are connected to core follow the AMF logs
```
sudo docker logs --follow oai-amf
```
# Setting up gNB
Clone this repo  and follow the instructions ref: https://github.com/5g-ucl-idrbt/oai-gnodeb-b210
## Commands to be executed in gNB

```
sudo sysctl net.ipv4.ip_forward=1
sudo iptables -P FORWARD ACCEPT
sudo ip route add 192.168.70.128/26 via <Bridge IP of Core VM>
```
```
cd ci-scripts/yaml_files/sa_b200_gnb/
sudo docker-compose up -d
```
```
sudo docker exec -it sa-b210-gnb bash
```
```
bash bin/entrypoint.sh
/opt/oai-gnb/bin/nr-softmodem -O /opt/oai-gnb/etc/gnb.conf $USE_ADDITIONAL_OPTIONS
```


<!--
# Testing with GNBSIM instead of physical USRP and UE

# For attaching 1 gNB and 1 UE
```
cd oai-cn5g-fed/docker-compose
sudo docker-compose -f docker-compose-gnbsim.yaml up -d gnbsim
sudo docker ps -a
```
For getting the IP of UE
```
sudo docker logs gnbsim
```

## Ping tests and curl tests 
```
sudo docker exec -it gnbsim bash
```
```
apt update
apt install -y curl
```
Here 12.1.1.2 is the ip of the UE (we can get it by looking into amf logs or in gnbsim logs)
```
#ping -I 12.1.1.2 8.8.8.8
ping -I 12.1.1.2 10.0.0.1
ping -I 12.1.1.2 10.0.0.2
ping -I 12.1.1.2 10.0.0.3

```
### checking connectivity with ther tomcat server (Python server)
```
curl --interface 12.1.1.2 http://10.0.0.2:8888
```
<!--### checking the connectivity to the server (tomcat)
```
curl --interface 12.1.1.2 http://192.168.150.115:8888

```
-->
<!--
# For attaching 2 gnbs and 2 Ues respectively
```
sudo docker-compose -f docker-compose-gnbsim.yaml up -d gnbsim gnbsim2
sudo docker ps -a
```
To know the Ip of the UEs

```
sudo docker logs gnbsim
sudo docker logs gnbsim2
```
-->

Ping tests to perform in UE 
```
ping 8.8.8.8
```
```
ping 10.0.0.1
ping 10.0.0.2
ping 10.0.0.3
```

## To verify that the UE is going through the router towards the internet
```
sudo docker exec -it router bash
ifconfig 
tcpdump -i <interface_name> #interface starting with dcp 
```
## To verify that the UE is reaching the server
```
sudo docker exec -it server bash
ifconfig
tcpdump -i <interface_name> #interface starting with dcp
```
## To do the network slicing:follow the following steps
To update the mac_to_port dictionary, you need to ping the server and router from the UE.
```
ping 10.0.0.2
```
```
ping 10.0.0.3
```
IF you want to see what is being saved in the dictionary, you can create a json file named as mac_to_port in the same folder you are running ryu controller, and if not needed, remove the line from the code where it is being saved in json file(i.e., line no 27 & 28)


## To verify that network slicing is working
Run simple python server on server.
NOTE: Always run the python server on the port 9999 (according to the RYU code)
```
python -m http.server 9999
```
Run simple python server on router
```
python -m http.server 9988
```
Now if you will do the wget command by the ip of router but the tcp_port on which the server is running, it will be replied by server and not router. You can also verify it on the terminal, from where you got the reply.
To do the wget command. Run following command in gnbsim
```
wget --bind-address= <UE_ip_address> <router_ip_address>:9999
```
And if we give some other tcp_port, it will be replied by router
```
wget --bind-address= <UE_ip_address> <router_ip_address>:9988
```
So, you can observe in the terminal(router & server) that even if the ip was same but was answered by differenrt systems.

# For stopping the processes
```
sudo docker-compose down
```
```
sudo docker compose -f docker-compose-basic-nrf-ovs.yaml down
```

