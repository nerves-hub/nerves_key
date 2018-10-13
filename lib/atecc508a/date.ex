defmodule ATECC508A.Date do
  @moduledoc """
  Handle the ATECC508's encoded dates
  """

  @doc """
  Decode an issue date/expiration bitstring
  """
  @spec decode(ATECC508A.encoded_dates()) :: {DateTime.t(), DateTime.t()}
  def decode(<<raw_year::5, month::4, day::5, hour::5, expire_years::5>>) do
    issue_date = %DateTime{
      year: raw_year + 2000,
      month: month,
      day: day,
      hour: hour,
      minute: 0,
      second: 0,
      microsecond: {0, 0},
      std_offset: 0,
      utc_offset: 0,
      zone_abbr: "UTC",
      time_zone: "Etc/UTC"
    }

    expire_date =
      if expire_years != 0 do
        %DateTime{issue_date | year: issue_date.year + expire_years}
      else
        # Special "no expiration date"
        max_date()
      end

    {issue_date, expire_date}
  end

  @doc """
  Encode an issue date/expiration bitstring

  This function can easily lose precision on the dates and times since
  so little is encoded. If accepting arbitrary datetimes, you'll want
  to check that the conversion didn't truncate in strange ways.

  Important: the max issue year is 2031!!
  """
  @spec encode(DateTime.t(), DateTime.t()) :: ATECC508A.encoded_dates()
  def encode(issue_date, expire_date) do
    expire_years = calc_expire_years(issue_date, expire_date)
    issue_year = calc_issue_year(issue_date.year)

    <<issue_year::5, issue_date.month::4, issue_date.day::5, issue_date.hour::5, expire_years::5>>
  end

  defp max_date() do
    # See RFC 5280 4.1.2.5.2
    %DateTime{
      year: 9999,
      month: 12,
      day: 31,
      hour: 23,
      minute: 59,
      second: 59,
      microsecond: {0, 0},
      std_offset: 0,
      utc_offset: 0,
      zone_abbr: "UTC",
      time_zone: "Etc/UTC"
    }
  end

  defp calc_issue_year(year) when year < 2000, do: 0
  defp calc_issue_year(year) when year > 2031, do: 31
  defp calc_issue_year(year), do: year - 2000

  defp calc_expire_years(issue_date, expire_date) do
    delta_years = expire_date.year - issue_date.year
    # delta_years has to fit in 5 bytes and 0 = doesn't expire
    cond do
      delta_years < 1 -> 1
      delta_years > 31 -> 0
      true -> delta_years
    end
  end
end
