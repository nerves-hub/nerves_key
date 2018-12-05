# ATECC508A

## Device configuration

See Table 2-5 in the ATECC508A data sheet for documentation on the configuration zone.
This software expects the following configuration to be programmed (unspecified bytes
are either not programmable or kept as their defaults):

Bytes  | Name        | Value  | Description
-------|-------------|--------|------------
14     | I2C_Enable  | 01     | I2C mode
16     | I2C_Address | C0     | I2C address of the module (default)
18     | OTPmode     | AA     | OTP is in read-only mode
19     | ChipMode    | 00     | Default mode
20-51  | SlotConfig  | N/A    | See the next table
92-95  | X509Format  | 00..00 | Unused
96-127 | KeyConfig   | N/A    | See next table

The slots will be programmed as follows. This definition is organized to be similar to
the Microchip Standard TLS Configuration for the used slots to minimize changes to
software. Unused slots are configured so that applications can use them as they would
an EEPROM.

Slot | Description                       | SlotConfig | KeyConfig | Primary properties
-----|-----------------------------------|------------|-----------|-------------------
0    | Device private key                | 8F 20      | 33 00     | Private key, read only; lockable
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
13   | Signer serial number*             | 0F 2F      | 3C 00     | Clear read only; lockable
14   | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable
15   | Unused                            | 0F 0F      | 3C 00     | Clear read/write; lockable

* The signer serial number slot is currently unused since the signer's cert is computed from the
  public key

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
