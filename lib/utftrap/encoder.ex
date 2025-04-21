defmodule UTFtrap.Encoder do
  @moduledoc """
  Handles encoding operations for UTFtrap.
  """
  alias UTFtrap.Direction
  alias UTFtrap.Insertion
  @header "\u200F\u200F\u200F\u200E\u200E\u200E"
  @footer "\u200F\u200F\u200E\u200E"
  # LTR mark
  @ltr_mark "\u200E"
  # RTL mark
  @rtl_mark "\u200F"

  def encode(cover_text, data) when is_binary(data) do
    binary_data = string_to_binary(data)
    length_binary = bytes_length(binary_data)
    length_binary_binary = Integer.to_string(length_binary, 2) |> String.pad_leading(16, "0")
    encoded_length_binary = encode_binary(length_binary_binary)
    encoded_data = encode_binary(binary_data)

    # Detect original direction
    original_direction = Direction.detect(cover_text)

    # Find insertion point
    {before, rest} = Insertion.find_insertion_point(cover_text)

    # Add direction correction if needed
    encoded_data = add_direction_correction(encoded_data, original_direction)

    # Create the encoded text with header and footer
    before <> @header <> encoded_length_binary <> encoded_data <> @footer <> rest
  end

  @doc """
  Adds a direction correction mark to the end of the text if needed.
  """
  def add_direction_correction(text, original_direction) do
    # Detect the current direction of the encoded text
    current_direction = Direction.detect(text)

    # Add correction if the direction has changed
    case {original_direction, current_direction} do
      {:ltr, :rtl} -> text <> @ltr_mark
      {:rtl, :ltr} -> text <> @rtl_mark
      _ -> text
    end
  end

  defp string_to_bytes(string) do
    string
    |> :binary.bin_to_list()
  end

  defp byte_to_binary(byte) do
    byte
    |> Integer.to_string(2)
    |> String.pad_leading(8, "0")
  end

  defp string_to_binary(string) do
    string
    |> string_to_bytes()
    |> Enum.map(&byte_to_binary/1)
    |> Enum.join()
  end

  defp bytes_length(binary_data) do
    binary_data
    |> String.length()
  end

  defp encode_binary(binary) do
    binary
    |> String.graphemes()
    |> Enum.map(fn s ->
      case s do
        "0" -> "\u200F"
        "1" -> "\u200E"
      end
    end)
    |> Enum.join("")
  end
end
