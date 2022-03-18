defmodule PcanlogParse.Examples.ExportToCsv do
  require PcanlogParser
  require CSV

  alias PcanlogParser, as: Parser

  @moduledoc """
  Documentation for `PcanlogParser.Examples.ExportToCsv`.
  This is an example of usage for PcanlogParser. It parses a P-CAN log file and exports the Payload as CSV data
  """

  # converts a P-CAN log into a CSV file, it process the CAN payload for this specific example
  def convert(file_path) when is_bitstring(file_path) do
    if not File.exists?(file_path) do
      {:error, "The file #{file_path} does not exist"}
    else
      # entries =
      file_path
      |> File.read!()
      |> Parser.parse_log()
      |> Enum.map(fn entry -> entry.data_bytes end)
      |> convert_to_csv()
      |> Enum.each(fn dic -> write_file(dic) end)
    end
  end

  def write_file(dic) when is_map(dic) do
    if length(Map.keys(dic)) != 1, do: {:error, "unexpected dictionary with more than one key"}

    [pin] = Map.keys(dic)
    %{^pin => data} = dic
    file_name = "#{pin}.csv"
    file = File.open!(file_name, [:write, :utf8])

    data
    |> CSV.encode()
    |> Enum.each(&IO.write(file, &1))
  end

  def convert_to_csv(data) when is_list(data) do
    data
    |> Enum.map(&process_databyte/1)
    |> Enum.group_by(fn dic -> dic.pin end)
    |> Enum.map(fn {pin, entries} -> %{pin => serialize(entries)} end)
  end

  # converts the maps into a list of values
  def serialize(data_bytes) when is_list(data_bytes) do
    list =
      data_bytes
      |> Enum.map(fn d -> [d.pin, d.time, d.duty_cycle, d.current] end)

    [["Pin", "Time", "Duty cycle", "Current"]] ++ list
  end

  # Expects data of the type "1400000000340E00" and returns a Map with the parsed field
  # this is the CAN payload, the values and fields are just for testing and are not part of any standard.
  def process_databyte(data) when is_bitstring(data) do
    bytes =
      data
      |> String.split("", trim: true)
      |> Enum.chunk_every(2)
      |> Enum.map(fn x -> Enum.join(x) end)

    [pin, dc_high, dc_low, curr_high, curr_low, time_high, time_low, _rest] = bytes

    %{
      pin: pin,
      duty_cycle: scale_duty_cycle(dc_high <> dc_low),
      current: hex_to_int(curr_high <> curr_low),
      time: hex_to_int(time_high <> time_low)
    }
  end

  # Expects a hexadecimal number as string and returns its integer value as string
  # i.e.: "F0" -> "240"
  defp hex_to_int(hex) when is_bitstring(hex) do
    hex
    |> String.to_integer(16)
    |> Integer.to_string()
  end

  # scales the 16 bits value of the duty cycle.
  # FFFFh to 100% and 7FFFh to 50% and all the values in between
  def scale_duty_cycle(hex_duty) do
    int_duty = String.to_integer(hex_duty, 16)

    [duty_int, _duty_dec] =
      (int_duty * 100 / 0xFFFF)
      |> Float.ceil()
      |> Float.to_string()
      |> String.split(".")

    duty_int
  end
end
