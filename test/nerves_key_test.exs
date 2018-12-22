defmodule NervesKeyTest do
  use ExUnit.Case

  import X509.ASN1

  test "create signer cert" do
    {cert, _key} = NervesKey.create_signing_key_pair()
    validity(notBefore: nb, notAfter: na) = X509.Certificate.validity(cert)
    assert year(na) - year(nb) == 1

    {cert, _key} = NervesKey.create_signing_key_pair(years_valid: 5)
    validity(notBefore: nb, notAfter: na) = X509.Certificate.validity(cert)
    assert year(na) - year(nb) == 5
  end

  defp year({:utcTime, [a, b | _]}) do
    [a, b]
    |> to_string()
    |> String.to_integer()
  end
end
