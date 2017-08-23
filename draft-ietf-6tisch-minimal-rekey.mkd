---
title: Minimal Security rekeying mechanism for 6TiSCH
abbrev: 6tisch-minimal-rekey
docname: draft-richardson-6tisch-minimal-rekey-02

# stand_alone: true

ipr: trust200902
area: Internet
wg: 6TiSCH Working Group
kw: Internet-Draft
cat: std

coding: us-ascii
pi:
  toc: yes
  sortrefs: yes
  symrefs: yes
  tocdepth: 2

author:
      -
        ins: M. Richardson
        name: Michael Richardson
        org: Sandelman Software Works
        email: mcr+ietf@sandelman.ca

normative:
  RFC2119:
  RFC7252:
  RFC7049:
  I-D.ietf-cose-msg:
  I-D.ietf-core-comi:
  I-D.ietf-core-object-security:

informative:
  I-D.ietf-6tisch-minimal-security:
  I-D.ietf-6tisch-dtsecurity-secure-join:
  I-D.ietf-6tisch-6top-protocol:
  I-D.ietf-anima-bootstrapping-keyinfra:
  I-D.ietf-6tisch-terminology:
  IEEE8021542015:
    title: "IEEE Std 802.15.4-2015 Standard for Low-Rate Wireless Personal Area Networks (WPANs)"
    author:
      ins: "IEEE standard for Information Technology"
    date: 2015


--- abstract

This draft describes a mechanism to rekey the networks used by 6TISCH nodes.
It leverages the security association created during an enrollment protocol.
The rekey mechanism permits incremental deployment of new sets of keys,
followed by a rollover to a new key.

--- middle

# Introduction        {#introduction}

6TiSCH networks of nodes often use a pair of keys, K1/K2 to authenticate beacons (K1),
encrypt broadcast traffic (K1) and encrypt unicast traffic (K2).  These keys need to
occasionally be refreshed for a number of reasons:

* cryptographic hygiene: the keys must be replaced before the ASN roles over or there could be repeated use of the same key.
* to remove nodes from the group: replacing the keys excludes any nodes that are suspect, or which are known to have left the network
* to recover short-addresses: if the JRC is running out of short (2-byte) addresses, it can rekey the network in order to garbage collect the set of addresses.

This protocol uses the CoMI {{I-D.ietf-core-comi}} to present the set of 127 key pairs.

In addition to providing for rekey, this protocol includes access to the allocated short-address.

# Terminology          {#terminology}

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in {{RFC2119}}. These words
may also appear in this document in lowercase, absent their normative meanings.

The reader is expected to be familiar with the terms and concepts defined in
{{I-D.ietf-6tisch-terminology}}, {{RFC7252}},
{{I-D.ietf-core-object-security}}, and {{I-D.ietf-anima-bootstrapping-keyinfra}}.

# Tree diagram notation {#treedigram}

A simplified graphical representation of the data models is used in
this document. The meaning of the symbols in these diagrams is as
follows:

* Brackets "[" and "]" enclose list keys.
* Braces "{" and "}" enclose feature names, and indicate that the
named feature must be present for the subtree to be present.
* Abbreviations before data node names: "rw" (read-write) represents
configuration data and "ro" (read-only) represents state data.
* Symbols after data node names: "?" means an optional node, "!"
means a presence container, and "*" denotes a list and leaf-list.
* Parentheses enclose choice and case nodes, and case nodes are also
marked with a colon (":").
* Ellipsis ("...") stands for contents of subtrees that are not
shown.

# An approach to rekeying

Rekeying of the network requires that all nodes be updated with the new keys.
This can take time as the network is constrained, and this management traffic is
not highest priority.

The JRC must reach out to all nodes that it is aware of.  As the JRC has originally provided the keys
via either zero-touch {{I-D.ietf-6tisch-dtsecurity-secure-join}} or
{{I-D.ietf-6tisch-minimal-security}} protocol, and in each case, the JRC assigned the short-address
to the node, so it knows about all the nodes.

The data model presented in this document provides for up to 127 K1/K2 keys, as each key
requires a secKeyId, which is allocated from a 255-element palette provides by {{IEEE8021542015}}.
Keys are to be updated in pairs, and the pairs are associated in the following way: the K1 key
is always the odd numbered key (1,3,5), and the K2 key is the even numbered key that follows (2,4,6).
A secKeyId value of 0 is invalid, and the secKeyId value of 255 is unused in this process.

Nodes MAY support up to all 127 key pair slots, but MUST support a minimum of 6 keys (3 slot-pairs).
When fewer than 127 are supported, the node MUST support secKeyId values from 1 to 254 in
a sparse array fashion.

A particular key slot-pair is considered active, and this model provides a mechanism to query and also
to explicitely set the active pair.

Nodes decrypt any packets for which they have keys, but MUST continue to send using only the
keypair which is considered active.  Receipt of a packet which is encrypted (or authenticated in
the case of a broadcast) with a secKeyId larger (taking consideration that secKeyId wraps at 254) than
the active slot-pair causes the node to change active slot pairs.

This mechanism permits the JRC to provision new keys into all the nodes while the network continues to
use the existing keys. When the JRC is certain that all (or enough) nodes have been provisioned
with the new keys, then the JRC causes a packet to be sent using the new key.  This can
be the JRC sending the next Enhanced Beacon or unicast traffic using the new key if the JRC
is also a regular member of the LLN.  In the likely case that the JRC has no direct connection
to the LLN, then the JRC updates the active key to the new key pair using a CoMI message.

The frame goes out with the new keys, and upon receipt (and decryption) of the new frame all
receiving nodes will switch to the new active key.  Beacons or unicast traffic leaving those
nodes will then update additional peers, and the network will switch over in a flood-fill
fashion.

((EDNOTE: do we need an example?))

# YANG models

## Tree diagram

A diagram of the two YANG modules looks like:


~~~~
module: ietf-6tisch-symmetric-keying
    +--rw ietf6tischkeypairs* [counter]
    |  +--rw counter           uint16
    |  +--rw ietf6tischkey1
    |  |  +--rw secKeyDescriptor
    |  |  |  +--rw secKey?   binary
    |  |  +--rw secKeyIndex?        uint8
    |  +--rw ietf6tischkey2
    |     +--rw secKeyDescriptor
    |     |  +--rw secKey?   binary
    |     +--rw secKeyIndex?        uint8
    +--ro secKeyUsage
       +--ro txPacketsSent?       uint32
       +--ro rxPacketsSuccess?    uint32
       +--ro rxPacketsReceived?   uint32

module: ietf-6tisch-short-address
    +--ro ietf6shortaddresses
       +--ro shortaddress    binary
       +--ro validuntil      uint32
       +--ro effectiveat?    uint32

~~~~
{: #fig-tree title='Tree diagrams of two rekey modules' align="left"}


## YANG model for keys

~~~~~~~~
{::include ietf-6tisch-symmetric-keying.yang}
~~~~~~~~

## YANG model for short-address

~~~~~~~~
{::include ietf-6tisch-short-address.yang}
~~~~~~~~

# Security of CoMI link

The CoMI resources presented here are protected by OSCOAP
({{I-D.ietf-core-object-security}}), secured using the EDHOC
connection used for joining.  A unique application key is generated using
an additional key generation process with the unique label "6tisch-rekey".

# Rekey of master connection

Should the OSCOAP connection need to be rekeyed, a new EDHOC process will be
necessary.  This will need access to trusted authentication keys, either the
PSK used from a one-touch process, or the locally significant domain
certificates installed during a zero-touch process.

# Privacy Considerations

The rekey protocol itself runs over a network encrypted with the K2 key. The
end to end protocol from JRC to node is also encrypted using OSCOAP, so the
keys are not visible, nor is the keying traffic distinguished in anyway to an
observer.

As the secKeyId is not confidential in the underlying 802.15.4 frames, an
observer can determine what sets of keys are in use, and when a rekey is
activated by observing the change in the secKeyId.

The absolute value of the monitonically increasing secKeyId could provide
some information as to the age of the network.

# Security Considerations

This protocol permits the underlying network keys to be set.
Access to all of the portions of this interface MUST be restricted to an
ultimately trusted peer, such as the JRC.

An implementation SHOULD not permit reading the network keys. Those fields
should be write-only.

The OSCOAP security for this interface is initialized by a join mechanism,
and so depends upon the initial credentials provided to the node.  The
initial network keys would have been provided during the join process; this
protocol permits them to be updated.

# IANA Considerations

This document allocates a SID number for the YANG model.
There is no IANA action required for this document.

# Acknowledgments

--- back

# Example

Example COMI requests/responses.
