defmodule PcanlogParser do
  @moduledoc """
  Documentation for `PcanlogParser`.
  Reads a P-CAN log file and returns a list of Maps, one map per log entry
  """

  def parse_file(file_path) do
    data =
      file_path
      |> File.read!()
      |> parse_log()

    {:ok, data}
  end

  def parse_log(data) when is_bitstring(data) do
    # removes the comments from the file content, these are starting with a semicolon ';'
    # parses each line entry and converst it to a Map

    lines = String.split(data, "\n")
    version = get_version(List.first(lines))

    lines
    |> Enum.drop_while(fn line -> String.starts_with?(line, ";") end)
    |> Enum.filter(fn line -> String.length(line) > 0 end)
    |> Enum.map(fn line -> parse_line(line, version) end)
  end

  def parse_line(line, :v1_1) when is_bitstring(line) do
    line
    |> String.trim("\r")
    |> String.split(" ", trim: true)
    |> check_tokens_length(13)
    |> parse_tokens_v1_1()
  end

  def parse_line(line, :v2_0) when is_bitstring(line) do
    line
    |> String.trim("\r")
    |> String.split(" ", trim: true)
    |> check_tokens_length(14)
    |> parse_tokens_v2_0()
  end

  # expected ;$FILEVERSION=1.1 or ;$FILEVERSION=2.0
  # returns :v1_1 or :v2_0
  defp get_version(line) when is_bitstring(line) do
    [";$FILEVERSION", version_number] = String.split(line, "=")

    ("v" <> String.replace(version_number, ".", "_"))
    |> String.trim()
    |> String.to_atom()
  end

  defp check_tokens_length(tokens, amount) when is_list(tokens) do
    token_length = length(tokens)

    case token_length do
      ^amount ->
        tokens

      _other ->
        {:error,
         "Token length expected #{amount}, got #{token_length}. Tokens: #{Enum.join(tokens, ', ')}"}
    end
  end

  defp parse_tokens_v1_1(tokens) when is_list(tokens) do
    [t_msg_numb, time_offset, type, can_id, data_length, b0, b1, b2, b3, b4, b5, b6, b7] = tokens

    Map.new()
    |> Map.put(:msg_numb, String.replace_suffix(t_msg_numb, ")", ""))
    |> Map.put(:time_offset, time_offset)
    |> Map.put(:type, type)
    |> Map.put(:can_id, can_id)
    |> Map.put(:data_length, data_length)
    |> Map.put(:data_bytes, b0 <> b1 <> b2 <> b3 <> b4 <> b5 <> b6 <> b7)
  end

  defp parse_tokens_v2_0(tokens) when is_list(tokens) do
    [t_msg_numb, time_offset, type, can_id, rx_tx, data_length, b0, b1, b2, b3, b4, b5, b6, b7] =
      tokens

    Map.new()
    |> Map.put(:msg_numb, t_msg_numb)
    |> Map.put(:time_offset, time_offset)
    |> Map.put(:type, type)
    |> Map.put(:can_id, can_id)
    |> Map.put(:rx_tx, rx_tx)
    |> Map.put(:data_length, data_length)
    |> Map.put(:data_bytes, b0 <> b1 <> b2 <> b3 <> b4 <> b5 <> b6 <> b7)
  end
end
