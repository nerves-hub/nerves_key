# Changelog

## v0.1.2

* Bug fixes
  * Lock the private key slot so that a genkey can't replace its contents

## v0.1.1

* Bug fixes
  * Fix signature failure issues by encoding the raw public key before constructing
    the subject_key_id and authority_key_id for calls to `NervesKey.signer_cert/1`
    and `NervesKey.device_cert/1`

## v0.1.0

Initial release
