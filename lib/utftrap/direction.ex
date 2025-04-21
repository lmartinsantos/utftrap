defmodule UTFtrap.Direction do
  @moduledoc """
  Handles text direction detection and correction for UTFtrap.
  """

  # Left-to-Right Mark
  @ltr_mark "\u200E"
  # Right-to-Left Mark
  @rtl_mark "\u200F"

  # Unicode ranges for RTL scripts
  @rtl_ranges [
    # Hebrew
    {0x0590, 0x05FF},
    # Arabic
    {0x0600, 0x06FF},
    # Arabic Supplement
    {0x0750, 0x077F},
    # Arabic Extended-A
    {0x08A0, 0x08FF},
    # Arabic Presentation Forms-A
    {0xFB50, 0xFDFF},
    # Arabic Presentation Forms-B
    {0xFE70, 0xFEFF},
    # Meroitic Hieroglyphs
    {0x10800, 0x1083F},
    # Meroitic Cursive
    {0x10840, 0x1085F},
    # Kharoshthi
    {0x10860, 0x1087F},
    # Old North Arabian
    {0x10880, 0x108AF},
    # Nabataean
    {0x108E0, 0x108FF},
    # Phoenician
    {0x10900, 0x1091F},
    # Lydian
    {0x10920, 0x1093F},
    # Meroitic Hieroglyphs
    {0x10980, 0x1099F},
    # Meroitic Cursive
    {0x109A0, 0x109FF},
    # Kharoshthi
    {0x10A00, 0x10A5F},
    # Old South Arabian
    {0x10A60, 0x10A7F},
    # Old North Arabian
    {0x10A80, 0x10A9F},
    # Manichaean
    {0x10AC0, 0x10AFF},
    # Avestan
    {0x10B00, 0x10B3F},
    # Inscriptional Parthian
    {0x10B40, 0x10B5F},
    # Inscriptional Pahlavi
    {0x10B60, 0x10B7F},
    # Psalter Pahlavi
    {0x10B80, 0x10BAF},
    # Old Turkic
    {0x10C00, 0x10C4F},
    # Rumi Numeral Symbols
    {0x10E60, 0x10E7F},
    # Old Sogdian
    {0x10F00, 0x10F2F},
    # Sogdian
    {0x10F30, 0x10F6F},
    # Elymaic
    {0x10FE0, 0x10FFF},
    # MenDe Kikakui
    {0x1E800, 0x1E8DF},
    # Adlam
    {0x1E900, 0x1E95F},
    # Indic Siyaq Numbers
    {0x1EC70, 0x1ECBF},
    # Ottoman Siyaq Numbers
    {0x1ED00, 0x1ED4F},
    # Arabic Mathematical Alphabetic Symbols
    {0x1EE00, 0x1EEFF},
    # Segmented Digit Display
    {0x1FBF0, 0x1FBF9}
  ]

  # Unicode ranges for LTR scripts
  @ltr_ranges [
    # Basic Latin - Uppercase
    {0x0041, 0x005A},
    # Basic Latin - Lowercase
    {0x0061, 0x007A},
    # Latin-1 Supplement
    {0x00C0, 0x00FF},
    # Latin Extended-A
    {0x0100, 0x017F},
    # Latin Extended-B
    {0x0180, 0x024F},
    # Greek and Coptic
    {0x0370, 0x03FF},
    # Cyrillic
    {0x0400, 0x04FF},
    # Cyrillic Supplement
    {0x0500, 0x052F},
    # Armenian
    {0x0530, 0x058F},
    # CJK Unified Ideographs
    {0x4E00, 0x9FFF},
    # Hiragana
    {0x3040, 0x309F},
    # Katakana
    {0x30A0, 0x30FF},
    # Hangul Syllables
    {0xAC00, 0xD7AF}
  ]

  # Unicode ranges for neutral characters
  @neutral_ranges [
    # Space, punctuation, numbers
    {0x0020, 0x0040},
    # More punctuation
    {0x005B, 0x0060},
    # More punctuation and symbols
    {0x007B, 0x00BF},
    # General Punctuation
    {0x2000, 0x206F},
    # Superscripts and Subscripts
    {0x2070, 0x209F},
    # Currency Symbols
    {0x20A0, 0x20CF},
    # Letterlike Symbols
    {0x2100, 0x214F},
    # Number Forms
    {0x2150, 0x218F},
    # Arrows
    {0x2190, 0x21FF},
    # Mathematical Operators
    {0x2200, 0x22FF},
    # Miscellaneous Technical
    {0x2300, 0x23FF},
    # Control Pictures
    {0x2400, 0x243F},
    # Optical Character Recognition
    {0x2440, 0x245F},
    # Enclosed Alphanumerics
    {0x2460, 0x24FF},
    # Box Drawing
    {0x2500, 0x257F},
    # Block Elements
    {0x2580, 0x259F},
    # Geometric Shapes
    {0x25A0, 0x25FF},
    # Miscellaneous Symbols
    {0x2600, 0x26FF},
    # Dingbats
    {0x2700, 0x27BF},
    # Miscellaneous Mathematical Symbols-A
    {0x27C0, 0x27EF},
    # Supplemental Arrows-A
    {0x27F0, 0x27FF},
    # Braille Patterns
    {0x2800, 0x28FF},
    # Supplemental Arrows-B
    {0x2900, 0x297F},
    # Miscellaneous Mathematical Symbols-B
    {0x2980, 0x29FF},
    # Supplemental Mathematical Operators
    {0x2A00, 0x2AFF},
    # Miscellaneous Symbols and Arrows
    {0x2B00, 0x2BFF}
  ]

  @doc """
  Detects the text direction of a string.
  Returns :ltr, :rtl, or :neutral based on the dominant direction.
  """
  def detect(text) do
    # Remove HTML tags before processing
    clean_text = remove_html_tags(text)

    # If text is empty after cleaning, return neutral
    if String.trim(clean_text) == "" do
      :neutral
    else
      # Count explicit direction marks
      ltr_mark_count = count_direction_chars(clean_text, @ltr_mark)
      rtl_mark_count = count_direction_chars(clean_text, @rtl_mark)

      # Count characters in RTL, LTR, and neutral scripts
      rtl_char_count = count_chars_in_ranges(clean_text, @rtl_ranges)
      ltr_char_count = count_chars_in_ranges(clean_text, @ltr_ranges)
      neutral_char_count = count_chars_in_ranges(clean_text, @neutral_ranges)

      # Combine explicit marks and script-based direction
      total_rtl = rtl_mark_count + rtl_char_count
      total_ltr = ltr_mark_count + ltr_char_count

      # If there are any directional characters, use their direction
      cond do
        total_rtl > 0 and total_rtl > total_ltr -> :rtl
        total_ltr > 0 and total_ltr >= total_rtl -> :ltr
        neutral_char_count > 0 -> :neutral
        true -> :neutral
      end
    end
  end

  @doc """
  Adds direction correction marks to the text if needed.
  """
  def add_correction(text, original_direction) do
    # For RTL text, add an RTL mark at the beginning and end
    case original_direction do
      :rtl -> @rtl_mark <> text <> @rtl_mark
      _ -> text
    end
  end

  defp count_direction_chars(text, char) do
    text
    |> String.graphemes()
    |> Enum.count(&(&1 == char))
  end

  defp count_chars_in_ranges(text, ranges) do
    text
    |> String.graphemes()
    |> Enum.count(fn char ->
      code_point = :unicode.characters_to_list(char) |> List.first()

      Enum.any?(ranges, fn {start, stop} ->
        code_point >= start and code_point <= stop
      end)
    end)
  end

  defp remove_html_tags(text) do
    text
    # Replace tags with spaces
    |> String.replace(~r/<[^>]*>/, " ")
    # Normalize spaces
    |> String.replace(~r/\s+/, " ")
  end
end
