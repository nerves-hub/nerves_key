# ATECC508A

## Device configuration

See Table 2-5 in the ATECC508A data sheet for documentation on the configuration zone.
This software expects the following configuration to be programmed (unspecified bytes
are either not programmable or kept as their defaults):

Bytes  | Name        | Value  | Description
-------|-------------|--------|------------
14     | I2C_Enable  | 01     | I2C mode
16     | I2C_Address | B0     | I2C address of the module. The default is 0xC0, so it's easy to check for unconfigured modules
18     | OTPmode     | AA     | OTP is in read-only mode
19     | ChipMode    | 00     | Default mode
20-51  | SlotConfig  | N/A    | See the next table
92-95  | X509Format  | 00..00 | Unused
96-127 | KeyConfig   | N/A    | See next table

The slots will be programmed as follows. This definition is compatible with the
Microchip Standard TLS Configuration, but only a few slots are actually used.

Slot | Description                       | SlotConfig | KeyConfig | Primary properties
-----|-----------------------------------|------------|-----------|-------------------
0    | Device private key                | 8F 20      | 33 00     | Private key; lockable
1    | Unused                            | C4 44      | 1C 00     | Microchip default
2    | Unused                            | 87 20      | 13 00     | Microchip default
3    | Unused                            | 87 20      | 13 00     | Microchip default
4    | Unused                            | 8F 8F      | 5C 00     | Microchip default
5    | Unused                            | C4 36      | 1C 00     | Microchip default
6    | Unused                            | 9F 8F      | 1C 00     | Microchip default
7    | Unused                            | 8F 44      | 1C 00     | Microchip default
8    | Unused                            | 0F 0F      | 3C 00     | Microchip default
9    | Unused                            | C4 44      | 3C 00     | Microchip default
10   | Device certificate                | 0F 0F      | 3C 00     | Clear read/write; lockable
11   | Signer public key                 | 0F 0F      | 30 00     | Clear read/write; lockable
12   | Signer certificate                | 0F 0F      | 3C 00     | Clear read/write; lockable
13   | Signer serial number              | 0F 0F      | 3C 00     | Clear read/write; lockable
14   | NervesHub root certificate SHA256 | 0F 0F      | 3C 00     | Clear read/write; lockable
15   | Unused                            | 0F 0F      | 3C 00     | Microchip default

The ATECC508A includes a 64 byte OTP (one-time programmable) memory. It has the following
layout:

Bytes  | Name              | Contents
-------|-------------------|--------------------------
0-3    | Magic             | 4e 72 76 73
4-5    | Flags             | TBD. Set to 0
6-15   | Board name        | 10 byte name for the board in ASCII (set unused bytes to 0)
16-31  | Mfg serial number | 16 byte manufacturer-assigned serial number in ASCII (set unused bytes to 0)
32-63  | User              | These are unassigned

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `atecc508a` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:atecc508a, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/atecc508a](https://hexdocs.pm/atecc508a).
