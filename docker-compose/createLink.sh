#!/bin/bash
## sudo bash createLink.sh <C1_name> <C2_Name>
C1_NAME=$1
C2_NAME=$2
##############################################################
createNS(){
	C_ID=$1
	#echo "Creating namespace for ${C_ID}"
	pid=$(docker inspect -f '{{.State.Pid}}' ${C_ID})
	CNAME=$(basename $(docker inspect --format='{{.Name}}' ${C_ID}))
	echo "Name=${CNAME}, PID=${pid}"
	mkdir -p /var/run/netns/
	ln -sfT /proc/$pid/ns/net /var/run/netns/${CNAME}
	#ip netns exec ${CNAME} ip a
	echo "Namespace ${CNAME} Created for ${C_ID}"
}
#################################
addLink(){
	C1=$1
	C2=$2
	LINK_ID="dcp"$(grep -m1 -ao '[0-9]' /dev/urandom | sed s/0/10/ | head -n1)
	#echo "Provide Interface Name of ${C1} (e.g. dcp100):"
	#read C1_IF
	#echo "Provide Interface Name of ${C2} (e.g. dcp100):"
	#read C2_IF
	#ip netns exec ${CONTAINER_ID}) ip a
	echo "Creating Link ID (${LINK_ID})..."
	ip link add veth1_l type veth peer veth1_r
	ip link set veth1_l netns ${C1}
	ip link set veth1_r netns ${C2}
	ip netns exec ${C1} ip l set veth1_l name ${LINK_ID}
	ip netns exec ${C2} ip l set veth1_r name ${LINK_ID}
	ip netns exec ${C1} ip l set ${LINK_ID} up
	ip netns exec ${C2} ip l set ${LINK_ID} up
#	ip netns exec ${C1} ip a add 10.0.0.1/30 dev ${C1_IF}
#	ip netns exec ${C2} ip a add 10.0.0.2/30 dev ${C2_IF}
#	ip netns exec ${C1} ip r add 10.0.0.2/32 via 0.0.0.0 dev ${C1_IF}
#	ip netns exec ${C2} ip r add 10.0.0.1/32 via 0.0.0.0 dev ${C2_IF}


}
##############################################################
C1_ID=$(docker inspect --format="{{.Id}}" ${C1_NAME})
createNS ${C1_ID}
C2_ID=$(docker inspect --format="{{.Id}}" ${C2_NAME})
createNS ${C2_ID}
##########
addLink ${C1_NAME} ${C2_NAME}


##############################################################
## sudo rm /var/run/netns/* 	#Cleanup
## ip -c link show type veth 	# List veth
## ethtool -S veth1 			#veth peering info
