defmodule NervesKey.DataTest do
  use ExUnit.Case

  alias NervesKey.Data

  @device_sn <<1, 2, 3, 4, 5, 6, 7, 8, 9>>

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

  test "slot contents" do
    device_cert = X509.Certificate.from_pem!(@device_cert_pem)
    signer_cert = X509.Certificate.from_pem!(@signer_cert_pem)
    slot_contents = Data.slot_data(@device_sn, device_cert, signer_cert)

    assert slot_contents ==
             [
               {1, <<0::unit(8)-size(36)>>},
               {2, <<0::unit(8)-size(36)>>},
               {3, <<0::unit(8)-size(36)>>},
               {4, <<0::unit(8)-size(36)>>},
               {5, <<0::unit(8)-size(36)>>},
               {6, <<0::unit(8)-size(36)>>},
               {7, <<0::unit(8)-size(36)>>},
               {8, <<0::unit(8)-size(416)>>},
               {9, <<0::unit(8)-size(72)>>},
               {10,
                <<113, 7, 255, 104, 99, 105, 147, 75, 58, 234, 29, 210, 19, 78, 43, 106, 83, 232,
                  174, 27, 236, 197, 190, 201, 22, 141, 236, 0, 85, 56, 206, 19, 242, 159, 158,
                  147, 205, 185, 201, 41, 136, 191, 30, 227, 141, 139, 115, 220, 136, 153, 241,
                  65, 81, 174, 53, 125, 192, 218, 243, 43, 219, 221, 44, 65, 248, 132, 1, 0, 0, 0,
                  176, 0>>},
               {11,
                <<5, 167, 236, 111, 234, 212, 182, 77, 254, 156, 250, 236, 228, 50, 0, 37, 136,
                  255, 43, 7, 224, 217, 183, 174, 101, 223, 90, 115, 68, 250, 169, 158, 46, 11,
                  52, 149, 142, 118, 250, 123, 52, 47, 93, 3, 212, 120, 10, 182, 9, 150, 247, 40,
                  2, 88, 231, 122, 150, 176, 91, 213, 100, 211, 228, 193, 0, 0, 0, 0, 0, 0, 0,
                  0>>},
               {12,
                <<139, 151, 27, 84, 252, 6, 28, 180, 219, 142, 53, 120, 19, 67, 228, 227, 122, 82,
                  143, 243, 222, 241, 230, 179, 150, 26, 228, 6, 104, 40, 238, 141, 77, 32, 52,
                  120, 121, 181, 24, 204, 20, 18, 29, 79, 89, 159, 6, 162, 5, 53, 109, 73, 180,
                  211, 94, 102, 225, 194, 43, 3, 37, 15, 59, 38, 150, 18, 129, 0, 0, 16, 160,
                  0>>},
               {13, <<0::unit(8)-size(72)>>},
               {14, <<0::unit(8)-size(72)>>},
               {15, <<0::unit(8)-size(72)>>}
             ]
  end
end
