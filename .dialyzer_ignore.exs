# Run `mix dialyzer --format short` for strings
[
  {"lib/x509/certificate.ex:20:23:unknown_type Unknown type: X509.ASN1.record/1."},
  {"lib/x509/private_key.ex:33:57:unknown_type Unknown type: :public_key.ec_private_key/0."},
  {"lib/x509/public_key.ex:9:56:unknown_type Unknown type: :public_key.ec_public_key/0."}
]
