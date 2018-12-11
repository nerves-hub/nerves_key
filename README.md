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

## ATECC508A device configuration

See Table 2-5 in the ATECC508A data sheet for documentation on the
configuration zone.  This software expects the following configuration to be
programmed (unspecified bytes are either not programmable or kept as their
defaults):

Bytes  | Name        | Value  | Description
-------|-------------|--------|------------
14     | I2C_Enable  | 01     | I2C mode
16     | I2C_Address | C0     | I2C address of the module (default)
18     | OTPmode     | AA     | OTP is in read-only mode
19     | ChipMode    | 00     | Default mode
20-51  | SlotConfig  | N/A    | See the next table
92-95  | X509Format  | 00..00 | Unused
96-127 | KeyConfig   | N/A    | See next table

The slots will be programmed as follows. This definition is organized to be
similar to the Microchip Standard TLS Configuration for the used slots to
minimize changes to software. Unused slots are configured so that applications
can use them as they would an EEPROM.

Slot | Description                       | SlotConfig | KeyConfig | Primary properties
-----|-----------------------------------|------------|-----------|-------------------
0    | Device private key                | 87 20      | 33 00     | Private key, read only; lockable
1    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
2    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
3    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
4    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
5    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
6    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
7    | Unused                            | 0F 0F      | 1C 00     | Clear read/write; not lockable
8    | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable
9    | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable
10   | Device certificate                | 0F 2F      | 3C 00     | Clear read only; lockable
11   | Signer public key                 | 0F 2F      | 30 00     | P256; Clear read only; lockable
12   | Signer certificate                | 0F 2F      | 3C 00     | Clear read only; lockable
13   | Signer serial number+             | 0F 2F      | 3C 00     | Clear read only; lockable
14   | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable
15   | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable

+ The signer serial number slot is currently unused since the signer's cert is
  computed from the public key

The ATECC508A includes a 64 byte OTP (one-time programmable) memory. It has the
following layout:

Bytes  | Name              | Contents
-------|-------------------|--------------------------
0-3    | Magic             | 4e 72 76 73
4-5    | Flags             | TBD. Set to 0
6-15   | Board name        | 10 byte name for the board in ASCII (set unused bytes to 0)
16-31  | Mfg serial number | 16 byte manufacturer-assigned serial number in ASCII (set unused bytes to 0)
32-63  | User              | These are unassigned
