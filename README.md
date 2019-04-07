# NervesKey

[![CircleCI](https://circleci.com/gh/nerves-hub/nerves_key.svg?style=svg)](https://circleci.com/gh/nerves-hub/nerves_key)
[![Hex version](https://img.shields.io/hexpm/v/nerves_key.svg "Hex version")](https://hex.pm/packages/nerves_key)

The NervesKey is a configured [ATECC508A or ATECC608A Crypto
Authentication](https://www.microchip.com/wwwproducts/en/ATECC508A) chip that's
used for authenticating devices with NervesHub and other cloud services. At a
high level, it is simple HSM that protects one private key by requiring all
operations on that key to occur inside chip. The project provides access to the
chip from Elixir and makes configuration decisions to make working with the
device easier. It has the following features:

1. Provision blank ATECC508A/608A devices - this includes private key generation
2. Storage for serial number and one-time calibration data (useful if primary
   storage is on a removable MicroSD card)
3. Support for Microchip's compressed X.509 certificate format to work with
   Microchip's C libraries
4. Support for signing device certificates so that devices can be included in a
   PKI
5. Support for storing a small amount of run-time configuration in unused data
   EEPROM slots
6. Support auxillary device/signer certificate storage to support pre-production
   experimentation without needing to lock down certificates

It cannot be stressed enough that the NervesKey library locks down the
ATECC508A/608A during the provisioning process. This is a feature and is
required for normal operation, but if you're getting started, make sure that you
have a few extra parts just in case.

See [hw/hw.md](hw/hw.md) for information on pre-built hardware modules.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `nerves_key` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nerves_key, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/nerves_key](https://hexdocs.pm/nerves_key).

## General use

NervesKeys need to be provisioned before they can be used. That's a one-time
step that could already have been done for you. If not, see subsequent sections
for how that works.

To use any of the NervesKey APIs, you will need a "transport" to communicate
with the ATECC508A/608A that's doing all of the work. Currently the only
supported transport is I2C. The following line would be run on your Nerves
device (like a Raspberry Pi, BeagleBone or your own custom hardware):

```elixir
iex> {:ok, i2c} = ATECC508A.Transport.I2C.init([])
```

Check if your NervesKey has been provisioned:

```elixir
iex> NervesKey.provisioned?(i2c)
true
```

If you get `false`, go to the provisioning sections. If you received an error,
check that the NervesKey has a good connection to your hardware. If you have a
custom board, you may need to pass parameters to
`ATECC508A.Transport.I2C.init/1` to set the correct I2C bus.

NervesKeys are provisioned with serial numbers. In production, these can be of
your choosing.

```elixir
iex> NervesKey.manufacturer_sn(i2c)
"ABC12345"
```

Of course, the more interesting part of the NervesKeys are its storage of device
private keys and their certificates. For the common case, it stores two X.509
certificates: one for the device and one for the certificate that signed the
device certificate. The signer certificate is usually uploaded to the servers
that the device will connect to so that it can authenticate the device. Here's
how to get both of the certificates:

```elixir
iex> NervesKey.device_cert(i2c)
{:OTPCertificate, ...}

# Put this in a convenient form:
iex> X509.Certificate.to_pem(v()) |> IO.puts
-----BEGIN CERTIFICATE-----
stuff
stuff
stuff
-----END CERTIFICATE-----

iex> NervesKey.signer_cert(i2c)
{:OTPCertificate, ...}
```

The next step is to tell Erlang's SSL library that you want to use the NervesKey
when connecting to the server. For that, you'll need
[nerves_key_pkcs11](https://github.com/nerves-hub/nerves_key_pkcs11). This code
is somewhat tedious but hopefully the following code fragment will help:

```elixir
   {:ok, engine} = NervesKey.PKCS11.load_engine()
   {:ok, i2c} = ATECC508A.Transport.I2C.init([])

   signer_cert = X509.Certificate.to_der(NervesKey.signer_cert(i2c))
   cert = X509.Certificate.to_der(NervesKey.device_cert(i2c))
   key = NervesKey.PKCS11.private_key(engine, {:i2c, 1})
   cacerts = [signer_cert] ++ Keyword.get(opts, :trusted_certs, [])

   Tortoise.Supervisor.start_child(
     server: {
       Tortoise.Transport.SSL,
       verify: :verify_peer,
       host: Keyword.get(opts, :host),
       cert: cert,
       key: key,
       cacerts: cacerts,
       versions: [:"tlsv1.2"],
     })
```

## Preparing for provisioning

The ATECC508A/608A in the NervesKey needs to be provisioned before it can be
used.  Before you can do that, you'll need the following:

1. A signing certificate and its private certificate (in other contexts, this is
   called a certificate authority)
2. A serial number for your device
3. A name for the device

The signing certificate and serial number are very important. After the
provisioning process, they are locked down and cannot be changed without
replacing the ATECC508A/608A. The device name is purely informational unless you
choose to use it in your software.

NervesKeys support an auxillary set of certificates that identify the device.
These are writable after the provisioning process. Since they're writable, they
can be provisioned and updated at any time. As such, they're not programmed in
the first-time provisioning process.

### Signing certificates

Part of the provisioning process creates an X.509 certificate for the NervesKey
that can be used to authenticate TLS connections. This certificate is signed by
a "signer certificate". You will eventually need to upload the signer
certificate to NervesHub or AWS IoT or wherever you would like to authenticate
devices.

Due to memory limitations, the ATECC508A/608A has a way to compress X.509
certificates on chip. See [ATECC Compressed Certificate
Definition](https://www.microchip.com/wwwAppNotes/AppNotes.aspx?appnote=en591852).
To comply with the limitations of compressible certificates, NervesKey provides
a mix task to create them:

```sh
$ mix nerves_key.signer create nerveskey_prod_signer1
Created signing cert, nerveskey_prod_signer1.cert and private key, nerveskey_prod_signer1.key.

Please store nerveskey_prod_signer1.key in a safe place.

nerveskey_prod_signer1.cert is ready to be uploaded to the servers that need
to authenticate devices signed by the private key.
```

There is no magic in the compressible certificates. They're just limited in what
they can contain. You can inspect them with `openssl x509 -in
nerveskey_prod_signer1.cert -text`.

Check with your IoT service on how the signer certificate is used. If it's only
used for first-time device registration, then the signer certificate may not
need a long expiration time. You may also be interested in creating more than
one signing certificate if you have more than one manufacturing facility.

### Manufacturer serial numbers

Be aware that there are a lot of things called serial numbers. In an attempt to
minimize confusion, we'll refer to the serial number that identifies the device
to humans and other machines as the "manufacturer serial number". This string
(it need not be a number) is commonly printed on a label on a device. It may be
embedded in a barcode. Other serial numbers exist - the ATECC508A/608A has a 9
byte one and X.509 certificates have ones. Those serial numbers have guarantees
on uniqueness. It is up to the device manufacturer to make sure that the
"manufacturer serial number" is unique. People generally want to do this for
their own sanity.

The NervesKey saves the manufacturing serial number in the one-time programmable
memory on the ATECC508A/608A and also in the device's X.509 certificate. The
device's X.509 certificate is signed, so cloud servers can trust the
manufacturer serial number.

At this point, you're the manufacturer. Decide how you'd like your serial
numbers to look. Whatever you pick, it must fit in 16-bytes. Representing the
serial number is ASCII is commonly done. If you don't want to deal with this, do
what we do (Base32-encode the ATECC508A/608A's globally unique identifier):

```elixir
iex> {:ok, i2c} = ATECC508A.Transport.I2C.init([])
{:ok, {ATECC508A.Transport.I2C, {#Reference<0.879310498.269090821.27261>, 96}}}
iex> NervesKey.default_info(i2c)
%NervesKey.ProvisioningInfo{
  board_name: "NervesKey",
  manufacturer_sn: "AER245UNQOY4T3Q"
}
```

## Provisioning

Now that you have a signing certificate, the signer's private key, and a
manufacturer serial number, you can provision a NervesKey or the ATECC508A/608A
acting as a NervesKey in your device.  Usually there's some custom manufacturing
support software that performs this step. We'll provision at the iex prompt.

Use `sftp` to copy the signer certificate and private key to your device. We'll
put them `/tmp` so that they disappear on reboot:

```sh
$ sftp nerves.local
Connected to nerves.local.
sftp> cd /tmp
sftp> put nerveskey_prod_signer1.*
Uploading nerveskey_prod_signer1.cert to /tmp/nerveskey_prod_signer1.cert
nerveskey_prod_signer1.cert                                              100%  636    78.3KB/s   00:00
Uploading nerveskey_prod_signer1.key to /tmp/nerveskey_prod_signer1.key
nerveskey_prod_signer1.key                                               100%  228    78.3KB/s   00:00
sftp> exit
```

Next, go to the IEx prompt on the device and run the following:

```elixir
# Customize these or use `NervesKey.default_info/1` for defaults
cert_name="nerveskey_prod_signer1"
manufacturer_sn = "N1234"
board_name = "NervesKey"

# These lines should be copy/paste
signer_cert = File.read!("/tmp/#{cert_name}.cert") |> X509.Certificate.from_pem!;true
signer_key = File.read!("/tmp/#{cert_name}.key") |> X509.PrivateKey.from_pem!();true

{:ok, i2c} = ATECC508A.Transport.I2C.init([])
provision_info = %NervesKey.ProvisioningInfo{manufacturer_sn: manufacturer_sn, board_name: board_name}

# Double-check what you typed above before running this
NervesKey.provision(i2c, provision_info, signer_cert, signer_key)
```

If the last line returns `:ok` after about 2 seconds, then celebrate. You
successfully programmed a NervesKey. You can't program it again. If you try,
you'll get an error.

## Provisioning an auxiliary certificate

If a situation arises where the originally provisioned certificate can't be
used, it's possible to store a second certificate on the device. This second
certificate uses the same private key as the first certificate. (It is assumed
that the algorithmic and physical protections on the first private key are
sufficient that storing two different private keys doesn't add value.) Use cases
include:

1. Recovering from expiration or loss of the original signer key
2. Experimentation
3. Fixing errors in the original certificates

The auxiliary certificate is stored in writable memory on the ATECC508A/608A.

The NervesKey must be provisioned before the auxiliary certificate can be
written. Assuming that's been done, copy the signer certificate and private key
to your device similar to what you did before. Then run the following at the IEx
prompt:

```elixir
# Customize these
cert_name="nerveskey_prod_signer1"

# These lines should be copy/paste
signer_cert = File.read!("/tmp/#{cert_name}.cert") |> X509.Certificate.from_pem!;true
signer_key = File.read!("/tmp/#{cert_name}.key") |> X509.PrivateKey.from_pem!();true

{:ok, i2c} = ATECC508A.Transport.I2C.init([])
NervesKey.provision_aux_certificates(i2c, signer_cert, signer_key)
```

## Settings

The NervesKey has bytes left over for storing a few settings. The
`NervesKey.put_settings/2` and `NervesKey.get_settings/1` APIs let you store and
retrieve a map. Since the storage is limited and relatively slow, this is
intended for settings that rarely change or may be tightly coupled with
certificates already being stored in the NervesKey.

Internally, `NervesKey` calls `:erlang.term_to_binary` to convert the map to raw
bytes and then it spreads it across ATECC508A slots for storage. This means that
the keys used in the map take up space too.

## Support

If you run into problems, please help us improve this project by filing an
[issue](https://github.com/nerves-hub/nerves_key/issues/new).

## ATECC508A configuration

This section describes the ATECC508A/608A configuration used for the
[NervesKey](https://github.com/nerves-hub/nerves_key). This information isn't
needed for using the library.

See Table 2-5 in the ATECC508A data sheet for documentation on the configuration
zone.  This software expects the following configuration to be programmed
(unspecified bytes are either not programmable or kept as their defaults):

Bytes  | Name        | Value  | Description
-----  | ----------- | ------ | -----------
14     | I2C_Enable  | 01     | I2C mode
16     | I2C_Address | C0     | I2C address of the module (default)
18     | OTPmode     | AA     | OTP is in read-only mode
19     | ChipMode    | 00     | Default mode
20-51  | SlotConfig  | N/A    | See the next table
92-95  | X509Format  | 00..00 | Unused
96-127 | KeyConfig   | N/A    | See next table

The slots are programmed as follows. This definition is organized to be similar
to the Microchip Standard TLS Configuration to minimize changes to other
software. Unused slots are configured so that applications can use them as they
would an EEPROM.

Slot | Description              | SlotConfig | KeyConfig | Primary properties
---- | ------------------------ | ---------- | --------- | ------------------
0    | Device private key       | 87 20      | 33 00     | Private key, read only; lockable
1    | Unused                   | 0F 0F      | 1C 00     | Clear read/write; not lockable
2    | Unused                   | 0F 0F      | 1C 00     | Clear read/write; not lockable
3    | Unused                   | 0F 0F      | 1C 00     | Clear read/write; not lockable
4    | Unused                   | 0F 0F      | 1C 00     | Clear read/write; not lockable
5    | Settings (Part 3)        | 0F 0F      | 1C 00     | Clear read/write; not lockable
6    | Settings (Part 2)        | 0F 0F      | 1C 00     | Clear read/write; not lockable
7    | Settings (Part 1)        | 0F 0F      | 1C 00     | Clear read/write; not lockable
8    | Settings (Part 0)        | 0F 0F      | 3C 00     | Clear read/write; lockable
9    | Aux device certificate   | 0F 0F      | 3C 00     | Clear read/write; lockable
10   | Device certificate       | 0F 2F      | 3C 00     | Clear read only; lockable
11   | Signer public key        | 0F 2F      | 30 00     | P256; Clear read only; lockable
12   | Signer certificate       | 0F 2F      | 3C 00     | Clear read only; lockable
13   | Signer serial number +   | 0F 2F      | 3C 00     | Clear read only; lockable
14   | Aux signer public key    | 0F 0F      | 3C 00     | Clear read/write; lockable
15   | Aux signer certificate   | 0F 0F      | 3C 00     | Clear read/write; lockable

+ The signer serial number slot is currently unused since the signer's cert is
  computed from the public key

The ATECC508A includes a 64 byte OTP (one-time programmable) memory. It has the
following layout:

Bytes  | Name              | Contents
------ | ----------------- | -------------------------
0-3    | Magic             | 4e 72 76 73
4-5    | Flags             | TBD. Set to 0
6-15   | Board name        | 10 byte name for the board in ASCII (set unused bytes to 0)
16-31  | Mfg serial number | 16 byte manufacturer-assigned serial number in ASCII (set unused bytes to 0)
32-63  | User              | These are unassigned
