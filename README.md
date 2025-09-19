A small project exploring sending and receiving raw packets using ethernet.

# Build

This project can be built with zig. It was developed using zig 0.15.1

```
zig build
```

# Run

If you don't want to run the binaries with sudo, you can use setcap to give them
the appropriate capabilities:

```
sudo setcap 'cap_net_raw+ep' ./zig-out/bin/ethernet_send
sudo setcap 'cap_net_raw+ep' ./zig-out/bin/ethernet_listen
```

Otherwise run the binaries with `sudo`

Each binary expects a single argument, which is the network interface to send or
listen on. e.g.

```
./zig-out/bin/ethernet_send veth0
./zig-out/bin/ethernet_listen veth1
```

# Virtual patch cable

For the purposes of a small demo, a "virtual patch cable" can be created.

```
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth0 up
sudo ip link set veth1 up
```

Now you can use these virtual devices with the demo.
