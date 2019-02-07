# Changelog

## v0.4.0

* New features
  * Add `NervesKey.detected?/1` to check whether a NervesKey is actually
    installed.

* Bug fixes
  * Clear out the entire auxiliary certificate slots to avoid any confusion for
    whether the certificates are present.

## v0.3.2

* New features
  * Add helper functions for detecting and clearing out auxiliary certificates

## v0.3.1

* New features
  * Add helper for provisioning NervesKeys using a default serial number

## v0.3.0

* New features
  * Support a auxiliary device certificate that can be updated after the
    provisioning step. This supports use cases where the provisioning
    certificate's private key isn't available or won't work.
  * Add `provisioned?/1` to quickly check whether a device has been provisioned

## v0.2.0

* New features
  * Support setting signer key expiration dates
  * Add a convenience method for getting the manufacturing serial number

* Bug fixes
  * Fixed configuration compatibility checking - Thanks to Peter Marks for this
    fix.

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
