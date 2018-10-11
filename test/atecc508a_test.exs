defmodule ATECC508ATest do
  use ExUnit.Case
  doctest ATECC508A

  test "decodes the date in the spec" do
    {issue_date, expire_date} = ATECC508A.Date.decode(<<0x75, 0x3E, 0x0E>>)

    assert DateTime.compare(issue_date, %DateTime{
             year: 2014,
             month: 10,
             day: 15,
             hour: 16,
             minute: 0,
             second: 0,
             microsecond: {0, 0},
             std_offset: 0,
             utc_offset: 0,
             zone_abbr: "UTC",
             time_zone: "Etc/UTC"
           })

    assert DateTime.compare(expire_date, %DateTime{
             year: 2028,
             month: 10,
             day: 15,
             hour: 16,
             minute: 0,
             second: 0,
             microsecond: {0, 0},
             std_offset: 0,
             utc_offset: 0,
             zone_abbr: "UTC",
             time_zone: "Etc/UTC"
           })
  end

  test "encodes the date in the spec" do
    issue_date = %DateTime{
      year: 2014,
      month: 10,
      day: 15,
      hour: 16,
      minute: 0,
      second: 0,
      microsecond: {0, 0},
      std_offset: 0,
      utc_offset: 0,
      zone_abbr: "UTC",
      time_zone: "Etc/UTC"
    }

    expire_date = %DateTime{
      year: 2028,
      month: 10,
      day: 15,
      hour: 16,
      minute: 0,
      second: 0,
      microsecond: {0, 0},
      std_offset: 0,
      utc_offset: 0,
      zone_abbr: "UTC",
      time_zone: "Etc/UTC"
    }

    assert ATECC508A.Date.encode(issue_date, expire_date) == <<0x75, 0x3E, 0xE>>
  end
end
