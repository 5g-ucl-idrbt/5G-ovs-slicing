#!/bin/bash


# creating links with the createlink.sh file
sudo bash createLink.sh oai-spgwu s1
sudo bash createLink.sh server s1
sudo bash createLink.sh router s1
# del bridge in s1 if it already exits
sudo docker exec s1 ovs-vsctl del-br br0

# creating bridge adding ports to bridge
BRIDGE_NAME="br0"
PORTS=$(sudo ip netns exec s1 ifconfig -a | grep -E "dcp[0-9]+" | awk -F':' '{print $1}')

sudo docker exec s1 ovs-vsctl add-br $BRIDGE_NAME

for PORT in $PORTS; do
    sudo docker exec s1 ovs-vsctl add-port $BRIDGE_NAME $PORT
done

sudo docker exec s1 ovs-vsctl set-fail-mode $BRIDGE_NAME secure




#INTF1=$(sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
#sudo docker exec s1 ovs-vsctl add-port br0 $INTF1
#INTF2=$(sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
#sudo docker exec s1 ovs-vsctl add-port br0 $INTF2
#INTF3=$(sudo ip netns exec s1 ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
#sudo docker exec s1 ovs-vsctl add-port br0 $INTF3
#sudo docker exec s1 ovs-vsctl set-fail-mode br0 secure

# Add IP to oai-spgwu and tomcat
C1_IF=$(sudo ip netns exec oai-spgwu ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
sudo ip netns exec oai-spgwu ip a add 10.0.0.1/24 dev ${C1_IF}
C2_IF=$(sudo ip netns exec server ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
sudo ip netns exec tomcat ip a add 10.0.0.2/24 dev ${C2_IF}
C3_IF=$(sudo ip netns exec router ifconfig -a | grep -E "dcp.*" | awk -F':' '{print $1}')
sudo ip netns exec router ip a add 10.0.0.3/24 dev ${C3_IF}

sudo ip netns exec oai-spgwu ip r add 10.0.0.3/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec oai-spgwu ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C1_IF}
sudo ip netns exec server ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C2_IF}
sudo ip netns exec router ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C3_IF}

# Add controller to the ovs
sudo docker exec s1 ovs-vsctl set-controller br0 tcp:172.18.0.4:6653






#github:abhic137
