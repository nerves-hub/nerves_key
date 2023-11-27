defmodule NervesKey.CacheTest do
  use ExUnit.Case

  defmodule TestTransport do
    @behaviour ATECC508A.Transport
    def init(args), do: {:ok, args}

    def request(_id, _payload, _timeout, _response_payload_len), do: {:error, :not_implemented}

    def transaction(_id, _callback), do: {:error, :not_implemented}

    def detected?(_), do: false
    def info(_), do: %{bus_name: "test-bus", address: 0x60}
  end

  @device_cert_pem """
  -----BEGIN CERTIFICATE-----
  MIIBcTCCARegAwIBAgIQSlaC4WQcrXJkvzd/7MHNLzAKBggqhkjOPQQDAjARMQ8w
  DQYDVQQDDAZTaWduZXIwHhcNNzAwMTAxMDAwMDAwWhcNMDEwMTAxMDAwMDAwWjAP
  MQ0wCwYDVQQDDAQxMjM0MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE6/+DAO5Y
  LE1w2a2XsaA76ZjpB1gbT7hfFCRVOl20l+DpbTKO9GJ4FypUo7tJ5cMh7UfnZ50n
  +rGRtMHfFEsB+KNTMFEwCQYDVR0TBAIwADAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0l
  BAwwCgYIKwYBBQUHAwIwHwYDVR0jBBgwFoAUNP5pRVEBapHsdQPO8hBj4vUjBi8w
  CgYIKoZIzj0EAwIDSAAwRQIgcQf/aGNpk0s66h3SE04ralPorhvsxb7JFo3sAFU4
  zhMCIQDyn56TzbnJKYi/HuONi3PciJnxQVGuNX3A2vMr290sQQ==
  -----END CERTIFICATE-----
  """

  @signer_cert_pem """
  -----BEGIN CERTIFICATE-----
  MIIBpzCCAU2gAwIBAgIQXj1tCj6UcebW9KzyMQuWozAKBggqhkjOPQQDAjARMQ8w
  DQYDVQQDDAZTaWduZXIwHhcNMTgxMjA0MjAwMDAwWhcNMTkxMjA0MjAwMDAwWjAR
  MQ8wDQYDVQQDDAZTaWduZXIwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQFp+xv
  6tS2Tf6c+uzkMgAliP8rB+DZt65l31pzRPqpni4LNJWOdvp7NC9dA9R4CrYJlvco
  AljnepawW9Vk0+TBo4GGMIGDMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/
  BAQDAgGGMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQU
  NP5pRVEBapHsdQPO8hBj4vUjBi8wHwYDVR0jBBgwFoAUNP5pRVEBapHsdQPO8hBj
  4vUjBi8wCgYIKoZIzj0EAwIDSAAwRQIhAIuXG1T8Bhy02441eBND5ON6Uo/z3vHm
  s5Ya5AZoKO6NAiBNIDR4ebUYzBQSHU9ZnwaiBTVtSbTTXmbhwisDJQ87Jg==
  -----END CERTIFICATE-----
  """

  test "cache" do
    device_cert = X509.Certificate.from_pem!(@device_cert_pem)
    signer_cert = X509.Certificate.from_pem!(@signer_cert_pem)

    assert NervesKey.Cache.device_cert({TestTransport, []}) == nil
    :ok = NervesKey.Cache.cache_device_cert({TestTransport, []}, device_cert)
    assert NervesKey.Cache.device_cert({TestTransport, []}) == {:ok, device_cert}

    assert NervesKey.Cache.signer_cert({TestTransport, []}) == nil
    :ok = NervesKey.Cache.cache_signer_cert({TestTransport, []}, signer_cert)
    assert NervesKey.Cache.signer_cert({TestTransport, []}) == {:ok, signer_cert}
  end
end
