from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import CONFIG_DISPATCHER, MAIN_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.ofproto import ofproto_v1_3
from ryu.lib.packet import packet
from ryu.lib.packet import ethernet
from ryu.lib.packet import ether_types
from ryu.lib.packet import tcp
from ryu.lib.packet import ipv4
import json

class TrafficSlicing(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(TrafficSlicing, self).__init__(*args, **kwargs)
        self.mac_to_port = {}
        self.allowed_ue_ip = "12.1.1.51"

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

        # Check if the packet is TCP and has the destination port 9999
        if pkt.get_protocol(tcp.tcp) and pkt.get_protocol(tcp.tcp).dst_port == 9999:
            ip_pkt = pkt.get_protocol(ipv4.ipv4)
            if ip_pkt and ip_pkt.src == self.allowed_ue_ip:
                # Allow the UE device to access the server
                match = datapath.ofproto_parser.OFPMatch(
                    in_port=in_port,
                    eth_type=ether_types.ETH_TYPE_IP,
                    ip_proto=0x06,
                    ipv4_dst="10.0.0.2",
                )
                actions = [
                    parser.OFPActionSetField(eth_dst=dst_mac),
                    parser.OFPActionOutput(self.mac_to_port[dst_mac]),
                ]
                self.add_flow(datapath, 2, match, actions)
                self._send_package(msg, datapath, in_port, actions)
            else:
                # Deny access for other IPs
                match = datapath.ofproto_parser.OFPMatch(in_port=in_port)
                actions = []  # Empty actions will drop the packet
                self.add_flow(datapath, 0, match, actions)
                self._send_package(msg, datapath, in_port, actions)
        else:
            # Handle other traffic scenarios (ARP, ICMP, etc.)
            # Your existing code for handling these cases
            pass

