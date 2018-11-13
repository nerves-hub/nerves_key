defmodule ATECC508A.DateTest do
  use ExUnit.Case
  doctest ATECC508A

  @datasheet_issue_date %DateTime{
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

  @datasheet_expire_date %DateTime{
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

  @datasheet_encoded_dates <<0x75, 0x3E, 0x0E>>

  test "decodes the date in the spec" do
    {issue_date, expire_date} = ATECC508A.Date.decode(@datasheet_encoded_dates)

    assert DateTime.compare(issue_date, @datasheet_issue_date) == :eq

    assert DateTime.compare(expire_date, @datasheet_expire_date) == :eq
  end

  test "encodes the date in the spec" do
    assert ATECC508A.Date.encode(@datasheet_issue_date, @datasheet_expire_date) ==
             @datasheet_encoded_dates
  end

  test "checks date validity" do
    assert ATECC508A.Date.valid_dates?(@datasheet_issue_date, @datasheet_expire_date)

    date_with_minutes = %DateTime{
      year: 2014,
      month: 10,
      day: 15,
      hour: 16,
      minute: 1,
      second: 0,
      microsecond: {0, 0},
      std_offset: 0,
      utc_offset: 0,
      zone_abbr: "UTC",
      time_zone: "Etc/UTC"
    }

    refute ATECC508A.Date.valid_dates?(date_with_minutes, @datasheet_expire_date)
  end
end
