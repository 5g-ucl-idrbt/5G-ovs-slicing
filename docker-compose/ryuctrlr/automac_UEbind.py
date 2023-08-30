from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import CONFIG_DISPATCHER, MAIN_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.ofproto import ofproto_v1_3
from ryu.lib.packet import packet
from ryu.lib.packet import ethernet
from ryu.lib.packet import ether_types
from ryu.lib.packet import udp
from ryu.lib.packet import tcp
from ryu.lib.packet import icmp
from ryu.lib.packet import ipv4
from ryu.lib.packet import arp
import json

class TrafficSlicing(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(TrafficSlicing, self).__init__(*args, **kwargs)
        self.mac_to_port = {}
 
    def update_mac_to_port(self, mac_address, port):
        self.mac_to_port[mac_address] = port

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def switch_features_handler(self, ev):
        datapath = ev.msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        match = parser.OFPMatch()
        actions = [
            parser.OFPActionOutput(ofproto.OFPP_CONTROLLER, ofproto.OFPCML_NO_BUFFER)
        ]
        self.add_flow(datapath, 0, match, actions)

    def add_flow(self, datapath, priority, match, actions):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        inst = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS, actions)]
        mod = parser.OFPFlowMod(
            datapath=datapath, priority=priority, match=match, instructions=inst
        )
        datapath.send_msg(mod)

    def _send_package(self, msg, datapath, in_port, actions):
        data = None
        ofproto = datapath.ofproto
        if msg.buffer_id == ofproto.OFP_NO_BUFFER:
            data = msg.data

        out = datapath.ofproto_parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=msg.buffer_id,
            in_port=in_port,
            actions=actions,
            data=data,
        )
        datapath.send_msg(out)

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def _packet_in_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        in_port = msg.match["in_port"]

        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocol(ethernet.ethernet)

        if eth.ethertype == ether_types.ETH_TYPE_LLDP:
            return
        dst_mac = eth.dst
        src_mac = eth.src
        
        
        if (pkt.get_protocol(tcp.tcp) and pkt.get_protocol(tcp.tcp).dst_port == 9999 and pkt.get_protocol(ipv4.ipv4).src=="12.1.1.2"):     #### change the UE Ip accordingly which you want in the slice & change the port according to the servers hosted port ####
            port = pkt.get_protocol(tcp.tcp).dst_port
            match = datapath.ofproto_parser.OFPMatch(
                in_port=in_port,
                tcp_dst=pkt.get_protocol(tcp.tcp).dst_port,
                tcp_src=pkt.get_protocol(tcp.tcp).src_port,
                eth_type=ether_types.ETH_TYPE_IP,
                ip_proto=0x06,
            )

            actions = [
                parser.OFPActionSetField(ipv4_dst="10.0.0.2"),    ### change the IP of the server (you also have to change the ip in the run.sh file) ###
                parser.OFPActionSetField(eth_dst=dst_mac),
                parser.OFPActionOutput(self.mac_to_port[dst_mac])
            ]
            self.add_flow(datapath, 2, match, actions)
            self._send_package(msg, datapath, in_port, actions)
            
        elif (pkt.get_protocol(tcp.tcp) and pkt.get_protocol(tcp.tcp).src_port == 9999): ### change the port according to the servers hosted port ###
            match = datapath.ofproto_parser.OFPMatch(
                in_port=in_port,
                eth_type=ether_types.ETH_TYPE_IP,
                tcp_dst=pkt.get_protocol(tcp.tcp).dst_port,
                tcp_src=pkt.get_protocol(tcp.tcp).src_port,
                ip_proto=0x06, 
            )

            actions = [
                parser.OFPActionSetField(ipv4_src="10.0.0.3"),  ### change the IP of the router (you also have to change the ip in the run.sh file) ###
                parser.OFPActionSetField(eth_src=src_mac),
                parser.OFPActionOutput(self.mac_to_port[dst_mac])
            ]
            self.add_flow(datapath, 2, match, actions)
            self._send_package(msg, datapath, in_port, actions)
            
        elif (pkt.get_protocol(tcp.tcp) and pkt.get_protocol(tcp.tcp).src_port != 9999 and pkt.get_protocol(tcp.tcp).dst_port != 9999):   ### change the port according to the servers hosted port ###
            out_port = self.mac_to_port[dst_mac]

            match = datapath.ofproto_parser.OFPMatch(
                in_port=in_port,
                eth_type=ether_types.ETH_TYPE_IP,
                tcp_dst=pkt.get_protocol(tcp.tcp).dst_port,
                tcp_src=pkt.get_protocol(tcp.tcp).src_port,
                ip_proto=0x06, 
            )

            actions = [parser.OFPActionOutput(out_port)]
            self.add_flow(datapath, 2, match, actions)
            self._send_package(msg, datapath, in_port, actions)
            
        elif pkt.get_protocol(arp.arp):
            arp_pkt = pkt.get_protocol(arp.arp)
            src_mac = arp_pkt.src_mac
            self.update_mac_to_port(src_mac, in_port)
            out_port = ofproto.OFPP_FLOOD
            actions = [datapath.ofproto_parser.OFPActionOutput(out_port)]
            match = datapath.ofproto_parser.OFPMatch(
                in_port=in_port,
                eth_dst=dst_mac,
                eth_src=src_mac
            )
            self._send_package(msg, datapath, in_port, actions)
            
        elif pkt.get_protocol(icmp.icmp):
            out_port = self.mac_to_port[dst_mac]
            match = datapath.ofproto_parser.OFPMatch(
                in_port=in_port,
                eth_dst=dst_mac,
                eth_src=src_mac,
                ip_proto=0x01
            )
            actions = [datapath.ofproto_parser.OFPActionOutput(out_port)]
            self.add_flow(datapath, 1, match, actions)
            self._send_package(msg, datapath, in_port, actions)

        elif pkt.get_protocol(udp.udp):
            out_port = self.mac_to_port[dst_mac]
            match = datapath.ofproto_parser.OFPMatch(
                in_port=in_port,
                eth_dst=dst_mac,
                eth_src=src_mac,
                ip_proto=0x11
            )
            actions = [datapath.ofproto_parser.OFPActionOutput(out_port)]
            self._send_package(msg, datapath, in_port, actions)
            
        else:
            print("reached end")
