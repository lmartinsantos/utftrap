defmodule UTFtrap.Decoder do
  @moduledoc """
  Handles decoding operations for UTFtrap.
  """
  @header "\u200F\u200F\u200F\u200E\u200E\u200E"
  @footer "\u200F\u200F\u200E\u200E"

  @doc """
  Decodes a hidden message from text containing Unicode directional marks.
  Returns the decoded string or empty string if no valid message is found.
  """
  def decode(encoded_text) do
    case decode_message(encoded_text) do
      {:ok, binary} ->
        text = binary_to_string(binary)
        text

      :error ->
        ""
    end
  end

  # Private helper functions

  defp decode_message(encoded_text) do
    with {:ok, %{header: @header, length: _length, payload: payload, footer: @footer}} <-
           split_parts(encoded_text) do
      {:ok, decode_binary(payload)}
    else
      :error -> :error
    end
  end

  defp split_parts(encoded_text) do
    case String.contains?(encoded_text, @header) and String.contains?(encoded_text, @footer) do
      false ->
        :error

      true ->
        [_pre, with_payload] = String.split(encoded_text, @header, parts: 2)
        length_encoded = String.slice(with_payload, 0, 16)
        length_decoded = decode_binary(length_encoded)
        length = bin16tonumber(length_decoded)
        payload = String.slice(with_payload, 16..(16 + length))
        {:ok, %{header: @header, length: length, payload: payload, footer: @footer}}
    end
  end

  defp decode_binary(binary) do
    binary
    |> String.graphemes()
    |> Enum.map(fn s ->
      case s do
        "\u200F" -> "0"
        "\u200E" -> "1"
      end
    end)
    |> Enum.join("")
  end

  defp bin16tonumber(binary_string) do
    binary_string
    |> String.to_integer(2)
  end

  defp binary_to_string(binary) do
    binary
    |> String.graphemes()
    |> Enum.chunk_every(8)
    |> Enum.map(&Enum.join/1)
    |> Enum.map(&String.to_integer(&1, 2))
    |> List.to_string()
    |> String.trim_trailing("\u0000")
  end
end
