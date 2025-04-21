defmodule UTFtrap.CLI do
  @moduledoc """
  Command-line interface for UTFtrap.
  """

  @doc """
  Main entry point for the CLI application.
  """
  def main(args) do
    args
    |> parse_args()
    |> process()
  end

  @doc """
  Parse command line arguments.
  """
  def parse_args(args) do
    {opts, args, _} =
      OptionParser.parse(args,
        strict: [
          encode: :boolean,
          decode: :boolean,
          input: :string,
          output: :string,
          message: :string,
          help: :boolean
        ],
        aliases: [
          e: :encode,
          d: :decode,
          i: :input,
          o: :output,
          m: :message,
          h: :help
        ]
      )

    {opts, args}
  end

  @doc """
  Process the parsed arguments and execute the appropriate command.
  """
  def process({opts, _args}) do
    cond do
      Keyword.get(opts, :help) ->
        print_help()
        :ok

      Keyword.get(opts, :encode) ->
        encode_file(opts)

      Keyword.get(opts, :decode) ->
        decode_file(opts)

      true ->
        print_help()
        :ok
    end
  end

  @doc """
  Encode a message in a file.
  """
  def encode_file(opts) do
    input = Keyword.get(opts, :input)
    output = Keyword.get(opts, :output)
    message = Keyword.get(opts, :message)

    cond do
      is_nil(input) or is_nil(output) or is_nil(message) ->
        IO.puts("Error: --input, --output, and --message are required for encoding")
        :error

      true ->
        case UTFtrap.File.encode_file(input, output, message) do
          {:ok, _path} ->
            :ok

          {:error, reason} ->
            IO.puts("Error encoding message: #{inspect(reason)}")
            :error
        end
    end
  end

  @doc """
  Decode a message from a file.
  """
  def decode_file(opts) do
    input = Keyword.get(opts, :input)

    cond do
      is_nil(input) ->
        IO.puts("Error: --input is required for decoding")
        :error

      true ->
        case UTFtrap.File.decode_file(input) do
          {:ok, message} ->
            IO.puts(message)
            :ok

          {:error, reason} ->
            IO.puts("Error decoding message: #{inspect(reason)}")
            :error
        end
    end
  end

  @doc """
  Print help information.
  """
  def print_help do
    IO.puts("""
    UTFtrap - A stealthy content fingerprinting tool

    Usage:
      utftrap [options]

    Options:
      -e, --encode              Encode a message in a file
      -d, --decode              Decode a message from a file
      -i, --input FILE          Input file path
      -o, --output FILE         Output file path (for encoding)
      -m, --message MESSAGE     Message to encode
      -h, --help                Show this help message

    Examples:
      # Encode a message in a file
      utftrap --encode --input input.txt --output output.txt --message "secret message"

      # Decode a message from a file
      utftrap --decode --input encoded.txt
    """)
  end
end
