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
one-time programmable. The methods to provision the chip lock the configuration,
OTP, and data portions of the chip are very easy to call, but there's no
going back.

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

## Provisioning

The ATECC508A needs to be provisioned before it can be used for the first time.
This step initializes the ATECC508A configuration, creates a new device certificate,
and locks the one time programmable memory. Provisioning will require the following
parameters

  * manufacturer_sn - The serial number of the device
  * board_name - A string identifier of the version of the hardware board
  * signer_cert - The CA certificate to sign the device certificate
  * signer_key - The private key for the signer_cert

Provisioning needs to happen at runtime since the process requires communication
with the ATECC508A. In the following example, we are reading the signer certificate
and key from files on the disk. These files were moved onto the device
prior to running this routine.

```elixir
signer_cert = File.read!("/root/signer.cert") |> X509.Certificate.from_pem!
signer_key = File.read!("/root/signer.key") |> X509.PrivateKey.from_pem!()

manufacturer_sn = "1234"
board_name = "NervesKey"

{:ok, i2c} = ATECC508A.Transport.I2C.init([])
provision_info = %NervesKey.ProvisioningInfo{manufacturer_sn: manufacturer_sn, board_name: board_name}
:ok = NervesKey.provision(i2c, provision_info, signer_cert, signer_key)
```
