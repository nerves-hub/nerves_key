# Run `mix dialyzer --format short` for strings
[
  {"lib/nerves_key.ex:20:unknown_type Unknown type: X509.ASN1.record/1."},
  {"lib/nerves_key.ex:33:unknown_type Unknown type: :public_key.ec_private_key/0."},
  {"lib/nerves_key.ex:33:unknown_type Unknown type: :public_key.rsa_private_key/0."},
  {"lib/nerves_key/data.ex:9:unknown_type Unknown type: :public_key.ec_public_key/0."},
  {"lib/nerves_key/data.ex:9:unknown_type Unknown type: :public_key.rsa_public_key/0."},
  {"lib/nerves_key/data.ex:20:unknown_type Unknown type: X509.ASN1.record/1."}
]
