defmodule UTFtrap do
  @moduledoc """
  A module for encoding and decoding hidden messages using Unicode directional marks.
  """

  @doc """
  Encodes a string into a hidden message using Unicode directional marks.
  The message is placed between the last two words of the cover text.
  """
  def encode(cover_text, string) when is_binary(string) do
    UTFtrap.Encoder.encode(cover_text, string)
  end

  @doc """
  Decodes a hidden message from text containing Unicode directional marks.
  Returns the decoded string or empty string if no valid message is found.
  """
  def decode_hidden(encoded_text) do
    UTFtrap.Decoder.decode(encoded_text)
  end

  @doc """
  Detects the text direction of a string.
  Returns :ltr, :rtl, or :neutral based on the dominant direction.
  """
  def detect_text_direction(text) do
    UTFtrap.Direction.detect(text)
  end
end
