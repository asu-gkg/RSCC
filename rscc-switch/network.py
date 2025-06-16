from p4utils.mininetlib.network_API import NetworkAPI

net = NetworkAPI()

# Network general options
net.setLogLevel('info')
net.setCompiler(p4rt=True)

# Network definition
# Spine switches
net.addP4RuntimeSwitch('spine1')
net.addP4RuntimeSwitch('spine2')

# Leaf switches
net.addP4RuntimeSwitch('leaf1')
net.addP4RuntimeSwitch('leaf2')
net.addP4RuntimeSwitch('leaf3')
net.addP4RuntimeSwitch('leaf4')

net.setP4SourceAll('rscc.p4')

# Hosts
net.addHost('h1')
net.addHost('h2')
net.addHost('h3')
net.addHost('h4')
net.addHost('h5')
net.addHost('h6')
net.addHost('h7')
net.addHost('h8')

# Links between spine and leaf switches
net.addLink("spine1", "leaf1")
net.addLink("spine1", "leaf2")
net.addLink("spine1", "leaf3")
net.addLink("spine1", "leaf4")
net.addLink("spine2", "leaf1")
net.addLink("spine2", "leaf2")
net.addLink("spine2", "leaf3")
net.addLink("spine2", "leaf4")

# Links between leaf switches and hosts
net.addLink("leaf1", "h1")
net.addLink("leaf1", "h2")
net.addLink("leaf2", "h3")
net.addLink("leaf2", "h4")
net.addLink("leaf3", "h5")
net.addLink("leaf3", "h6")
net.addLink("leaf4", "h7")
net.addLink("leaf4", "h8")

net.setBwAll(10)

# Assignment strategy
net.l3()

# Nodes general options
net.disablePcapDumpAll()
net.enableLogAll()
net.enableCli()
net.startNetwork()