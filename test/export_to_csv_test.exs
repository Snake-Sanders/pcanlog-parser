defmodule ExportToCsvTest do
  use ExUnit.Case
  require PcanlogParse.Examples.ExportToCsv
  alias PcanlogParse.Examples.ExportToCsv, as: Exporter

  test "scale duty cycle" do
    assert Exporter.scale_duty_cycle("7FFF") == "50"
    assert Exporter.scale_duty_cycle("FFFF") == "100"
    assert Exporter.scale_duty_cycle("0000") == "0"
  end

  test "maps CAN payload into a Map" do
    record =
      "157FFF000033F700"
      |> Exporter.process_databyte()

    assert is_map(record)

    assert :pin in Map.keys(record)
    assert record.pin == "15"

    assert :duty_cycle in Map.keys(record)
    # 0000
    assert record.duty_cycle == "50"

    assert :current in Map.keys(record)
    # 0000
    assert record.current == "0"

    assert :time in Map.keys(record)
    # 0x33F7 is 13303
    assert record.time == "13303"
  end

  # @tag :skip
  test "group entries by pin number" do
    # note: the original order is different from the result
    # "Pin" (1 byte), "Duty cycle" (2 bytes), "Current" (2 bytes), "Time" (2 bytes), _reserved (1 byte)
    data = [
      "150000000033F700",
      "140000000033F700",
      "150000000033F800",
      "140000000033F800",
      "150000000033F900",
      "140000000033F900",
      "150000000033FA00",
      "140000000033FA00",
      "150000000033FB00",
      "140000000033FB00"
    ]

    groups = Exporter.convert_to_csv(data)
    first_group = List.first(groups)

    assert List.first(first_group["14"]) == ["Pin", "Time", "Duty cycle", "Current"]
    assert List.last(first_group["14"]) == ["14", "13307", "0", "0"]
  end

  # @tag :skip
  test "covert demo csv file" do
    assert :ok == Exporter.convert("test/samples/pcan_log_v1_1.trc")
  end
end
