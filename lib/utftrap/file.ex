defmodule UTFtrap.File do
  @moduledoc """
  Provides functionality to encode messages in files and write them to new files.
  """

  alias UTFtrap

  @doc """
  Encodes a message in the content of a file and writes it to a new file.

  ## Parameters

    * `input_path` - Path to the input file
    * `output_path` - Path where the encoded file should be written
    * `message` - The message to encode in the file content
    * `opts` - Optional parameters:
      * `:chunk_size` - Size of chunks to read from the file (default: 1024)

  ## Returns

    * `{:ok, output_path}` on success
    * `{:error, reason}` on failure

  ## Examples

      iex> UTFtrap.File.encode_file("input.txt", "output.txt", "secret message")
      {:ok, "output.txt"}
  """
  @spec encode_file(String.t(), String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, term()}
  def encode_file(input_path, output_path, message, opts \\ []) do
    _chunk_size = Keyword.get(opts, :chunk_size, 1024)

    with {:ok, content} <- File.read(input_path),
         encoded_content = UTFtrap.encode(content, message),
         :ok <- File.write(output_path, encoded_content) do
      {:ok, output_path}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Decodes a message from an encoded file.

  ## Parameters

    * `path` - Path to the encoded file
    * `opts` - Optional parameters:
      * `:chunk_size` - Size of chunks to read from the file (default: 1024)

  ## Returns

    * `{:ok, message}` on success
    * `{:error, reason}` on failure

  ## Examples

      iex> UTFtrap.File.decode_file("encoded.txt")
      {:ok, "secret message"}
  """
  @spec decode_file(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def decode_file(path, opts \\ []) do
    _chunk_size = Keyword.get(opts, :chunk_size, 1024)

    with {:ok, content} <- File.read(path) do
      decoded = UTFtrap.decode_hidden(content)
      {:ok, decoded}
    else
      {:error, reason} -> {:error, reason}
    end
  end


end
