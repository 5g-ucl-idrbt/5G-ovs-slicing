#!/bin/bash

cat << "EOF"


 .________ ________   ____ ____________ .____      .___________ _______________________________
 |   ____//  _____/  |    |   \_   ___ \|    |     |   \______ \\______   \______   \__    ___/
 |____  \/   \  ___  |    |   /    \  \/|    |     |   ||    |  \|       _/|    |  _/ |    |   
 /       \    \_\  \ |    |  /\     \___|    |___  |   ||    `   \    |   \|    |   \ |    |   
/______  /\______  / |______/  \______  /_______ \ |___/_______  /____|_  /|______  / |____|   
       \/        \/                   \/        \/             \/       \/        \/           
 .________ ________         .__  .__       .__                                                 
 |   ____//  _____/    _____|  | |__| ____ |__| ____    ____                                   
 |____  \/   \  ___   /  ___/  | |  |/ ___\|  |/    \  / ___\                                  
 /       \    \_\  \  \___ \|  |_|  \  \___|  |   |  \/ /_/  >                                 
/______  /\______  / /____  >____/__|\___  >__|___|  /\___  /                                  
       \/        \/       \/             \/        \//_____/                                   

EOF

# creating links with the createlink.sh file
sudo bash createLink.sh oai-spgwu s1
sudo bash createLink.sh server s1
sudo bash createLink.sh router s1
echo "***************LINKS ARE CREATED**************"

# del bridge in s1 if it already exits
sudo docker exec s1 ovs-vsctl del-br br0
echo "********************CHECKING/DELETING EXISTING BRIDGE********************"
# creating bridge adding ports to bridge
BRIDGE_NAME="br0"
PORTS=$(sudo ip netns exec s1 ifconfig -a | grep -E "dcp[0-9]+" | awk -F':' '{print $1}')

sudo docker exec s1 ovs-vsctl add-br $BRIDGE_NAME

for PORT in $PORTS; do
    sudo docker exec s1 ovs-vsctl add-port $BRIDGE_NAME $PORT
done

sudo docker exec s1 ovs-vsctl set-fail-mode $BRIDGE_NAME secure

echo "*********************BRIDGE IS CREATED AND PORTS ARE ADDED************************"



#INTF1=$(sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
#sudo docker exec s1 ovs-vsctl add-port br0 $INTF1
#INTF2=$(sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
#sudo docker exec s1 ovs-vsctl add-port br0 $INTF2
#INTF3=$(sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
#sudo docker exec s1 ovs-vsctl add-port br0 $INTF3
#sudo docker exec s1 ovs-vsctl set-fail-mode br0 secure

# Add IPs
C1_IF=$(sudo ip netns exec oai-spgwu ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
sudo ip netns exec oai-spgwu ip a add 10.0.0.1/24 dev ${C1_IF}
C2_IF=$(sudo ip netns exec server ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
sudo ip netns exec server ip a add 10.0.0.2/24 dev ${C2_IF}
C3_IF=$(sudo ip netns exec router ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
sudo ip netns exec router ip a add 10.0.0.3/24 dev ${C3_IF}
echo "***************************IPS ARE ADDED TO SPGWU,SERVER & ROUTER **************************"

sudo ip netns exec oai-spgwu ip r add 10.0.0.3/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec oai-spgwu ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec server ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C2_IF}
sudo ip netns exec router ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C3_IF}
echo "******************************ROUTES ARE ADDED TO SPGWU,SERVER & ROUTER****************************"
# Add controller to the ovs
sudo docker exec s1 ovs-vsctl set-controller br0 tcp:172.18.0.4:6653

echo "***********************RYU CONTROLLER IS SET ************************"

#spgwu configs
sudo docker exec oai-spgwu apt update
sudo docker exec oai-spgwu apt install -y iputils-ping
sudo docker exec oai-spgwu apt install -y tcpdump
sudo docker exec oai-spgwu apt install -y iproute2
sudo docker exec oai-spgwu apt install -y iptables
sudo docker exec oai-spgwu sysctl net.ipv4.ip_forward=1
sudo docker exec oai-spgwu iptables -P FORWARD ACCEPT
sudo docker exec oai-spgwu ip route del default via 192.168.70.129 dev eth0
sudo ip netns exec oai-spgwu ip route add default via 10.0.0.3 dev ${C1_IF}
#sudo docker exec <container_name_or_id> sh -c 'command1 && command2 && command3'
echo "*************************SPGWU CONFIGURATION IS DONE*******************************"

#server configs
sudo docker exec server apt update
sudo docker exec server apt install -y iputils-ping
sudo docker exec server apt install -y tcpdump
sudo docker exec server apt install -y iproute2
sudo docker exec server apt install -y iptables
sudo docker exec server apt install -y net-tools
sudo docker exec server apt-get install -y python3
sudo docker exec server apt install -y wget
sudo docker exec server ip route del default via 192.168.70.129 dev eth0
sudo ip netns exec server ip r add 12.1.1.0/24 via 10.0.0.1 dev ${C2_IF}
echo "**************************SERVER CONFIGURATION IS DONE************************"

#router configs
sudo docker exec router apt update
sudo docker exec router apt install -y iputils-ping
sudo docker exec router apt install -y tcpdump
sudo docker exec router apt install -y iproute2
sudo docker exec router apt install -y iptables 
sudo docker exec router apt install -y net-tools
sudo ip netns exec router ip r add 12.1.1.0/24 via 10.0.0.1 dev ${C3_IF}
echo "************************ROUTER CONFIGURATION IS DONE***********************"


#github:abhic137
