# block-Tor-ips
Block Tor exit nodes using ipset or iptables.

I recommend using `ipset`. Because `iptables` has pretty bad performance for large IP pools (even checking 1000 IPs is hard for iptables)

But [ipset](https://ipset.netfilter.org/) is desined to block large IP pools.

## Variables

There are a few variables which you may want to take a look at.
Variables at `.env` are used to provide URL to fetch IPS, iptables chain name or ipset set name.

## Usage

To use this script you must have root privilages.

For iptables mode, run:

```
block-tor.sh iptables
```

To use this script for ipset mode, run:

```
block-tor.sh ipset
```
