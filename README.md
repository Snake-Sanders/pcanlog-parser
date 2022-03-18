# P-CAN log Parser

A simple parser that reads P-CAN viewer log .trc files and maps each entry into a elixir Map collection.
This gives the first step for starting manipulating the data.
Supports log versions: 1.1 and 2.0

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pcanlog_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pcanlog_parser, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pcanlog_parser](https://hexdocs.pm/pcanlog_parser).

