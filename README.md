# NervesKey

[![CircleCI](https://circleci.com/gh/nerves-hub/nerves_key.svg?style=svg)](https://circleci.com/gh/nerves-hub/nerves_key)
[![Hex version](https://img.shields.io/hexpm/v/nerves_key.svg "Hex version")](https://hex.pm/packages/nerves_key)

The NervesKey is a configured [ATECC508A Crypto
Authentication](https://www.microchip.com/wwwproducts/en/ATECC508A) chip that's
used for authenticating devices with NervesHub and other cloud services. At a
high level, it is simple HSM that protects one private key by requiring all
operations on that key to occur inside chip. The project provides access to the
chip from Elixir and makes configuration decisions to make working with the
device easier. It has the following features:

1. Provision blank ATECC508A devices - this includes private key generation
2. Storage for serial number and one-time calibration data (useful if primary
   storage is on a removable MicroSD card)
3. Support for Microchip's compressed X.509 certificate format for interop with
   C libraries
4. Support for signing device certificates so that devices can be included in a
   PKI
5. Support for storing a small amount of run-time configuration in unused data
   slots

It cannot be stressed enough that if you are provisioning ATECC508A or ATECC608A
chips with this library that you keep in mind that the chips are essentially
one-time programmable. Mistakes are corrected by replacing the chip or the
entire NervesKey.

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

## Preparing for provisioning

The ATECC508A in the NervesKey needs to be provisioned before it can be used.
Before you can do that, you'll need a signing certificate and some information
about your device.

### Signing certificates

Part of the provisioning process creates an X.509 certificate for the NervesKey
that can be used to authenticate TLS connections. This certificate is signed by
a "signer certificate". This is called a certificate authority in other contexts. You
will eventually need to upload the signer certificate to NervesHub or AWS IoT or
wherever you would like to authenticate devices.

Due to memory limitations, the ATECC508A has a way to compress X.509
certificates on chip. See [ATECC Compressed Certificate
Definition](https://www.microchip.com/wwwAppNotes/AppNotes.aspx?appnote=en591852). To
comply with the limitations of compressible certificates, NervesKey provides a
mix task:

```sh
$ mix nerves_key.signer create nerveskey_prod_signer1
Created signing cert, nerveskey_prod_signer1.cert and private key, nerveskey_prod_signer1.key.

Please store nerveskey_prod_signer1.key in a safe place.

nerveskey_prod_signer1.cert is ready to be uploaded to the servers that need
to authenticate devices signed by the private key.
```

Check with your IoT service on how the signer certificate is used. If it's only
used for first time device registration, then the signer certificate may not
need a long expiration time. You may also be interested in creating more than
one signing certificate if you have more than one manufacturing facility.

### Manufacturer serial numbers

Be aware that there are a lot of things called serial numbers. In an attempt to
minimize confusion, we'll refer to the serial number that identifies the device
to humans and other machines as the "manufacturer serial number". This string
(it need not be a number) is commonly printed on a label on a device. It may be
embedded in a barcode. Other serial numbers exist - the ATECC508A has a 9 byte
one and X.509 certificates have ones. Those serial numbers have guarantees on
uniqueness. It is up to the device manufacturer to make sure that the
"manufacturer serial number" is unique. People generally want to do this for
their own sanity.

The NervesKey saves the manufacturing serial number in the one-time programmable
memory on the ATECC508A and also in the devices X.509 certificate. The device's
X.509 certificate is signed, so cloud servers can trust the manufacturer serial
number.

At this point, you're the manufacturer. Decide how you'd like your serial
numbers to look. Whatever you pick, it must fit in a 16-bytes when represented
in ASCII (UTF-8 might work).

## Provisioning

Now that you have a signing certificate, the signer's private key, and a
manufacturer serial number, you can provision a NervesKey or the ATECC508A
acting as a NervesKey in your device.  Usually there's some custom manufucturing
support software that performs this step. We'll provision at the iex prompt.

Use `sftp` to push the signer certificate and private key to your device. We'll
put them `/tmp` so that they disappear on reboot:

```sh
$ sftp nerves.local
Connected to nerves.local.
sftp> cd /tmp
sftp> put nerveskey_prod_signer1.*
cert and private key, nerveskey_prod_signer1.key
Uploading nerveskey_prod_signer1.cert to /tmp/nerveskey_prod_signer1.cert
nerveskey_prod_signer1.cert                                              100%  840    78.3KB/s   00:00
Uploading nerveskey_prod_signer1.key to /tmp/nerveskey_prod_signer1.key
nerveskey_prod_signer1.key                                               100%  840    78.3KB/s   00:00
sftp> exit
```

Next, go to the IEx prompt on the device and run the following:

```elixir
signer_cert = File.read!("/tmp/nerveskey_prod_signer1.cert") |> X509.Certificate.from_pem!
signer_key = File.read!("/tmp/nerveskey_prod_signer1.key") |> X509.PrivateKey.from_pem!()

manufacturer_sn = "NK-1234"
board_name = "NervesKey"

{:ok, i2c} = ATECC508A.Transport.I2C.init([])
provision_info = %NervesKey.ProvisioningInfo{manufacturer_sn: manufacturer_sn, board_name: board_name}
:ok = NervesKey.provision(i2c, provision_info, signer_cert, signer_key)
```

## Support

If you run into problems, please help us improve this project by filing an
[issue](https://github.com/nerves-hub/nerves_key/issues/new).

