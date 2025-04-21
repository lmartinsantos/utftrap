ExUnit.start()

defmodule UTFtrap.TestHelpers do
  @moduledoc """
  Helper functions and test data for UTFtrap tests.
  """

  @doc """
  Returns a list of sample texts in different languages and formats.
  """
  def sample_texts do
    [
      # English
      "This is a simple test text.",
      "This    is    a    test    with    multiple    spaces.",
      "This is\ta test\nwith special characters.",

      # Russian
      "Это простой тестовый текст.",
      "Это    тест    с    множественными    пробелами.",
      "Это\тест\nс специальными символами.",

      # Chinese
      "这是一个简单的测试文本。",
      "这是一个    测试    文本    带有    多个    空格。",
      "这是一个\t测试\n带有特殊字符。",

      # Arabic
      "هذا نص اختبار بسيط.",
      "هذا    نص    اختبار    مع    مسافات    متعددة.",
      "هذا\تنص\nاختبار مع رموز خاصة.",

      # Japanese
      "これは簡単なテストテキストです。",
      "これは    テスト    テキスト    です    複数の    スペース。",
      "これは\tテスト\nテキスト特殊文字付き。"
    ]
  end

  @doc """
  Returns a list of sample tracking IDs in different formats.
  """
  def sample_tracking_ids do
    [
      "TRACK_001",
      "track_2024_001",
      "ID123456789",
      "tracking_id_123!@#$%^&*()",
      "track-2024-001",
      "track.2024.001",
      "track_2024_001_extra_long_id_for_testing",
      # Empty string
      ""
    ]
  end

  @doc """
  Returns a list of sample numbers for testing.
  """
  def sample_numbers do
    [
      0,
      1,
      -1,
      42,
      -42,
      1_000,
      -1_000,
      1_000_000,
      -1_000_000,
      9_999_999,
      -9_999_999
    ]
  end

  @doc """
  Simulates a copy-paste operation by converting the text to a charlist and back.
  """
  def simulate_copy_paste(text, times \\ 1) do
    Enum.reduce(1..times, text, fn _, acc ->
      acc |> to_string() |> String.to_charlist() |> List.to_string()
    end)
  end

  @doc """
  Returns a list of different types of Unicode spaces.
  """
  def unicode_spaces do
    [
      # Space
      "\u0020",
      # No-break space
      "\u00A0",
      # Figure space
      "\u2007",
      # Narrow no-break space
      "\u202F",
      # Ideographic space
      "\u3000",
      # Zero-width space
      "\u200B",
      # Zero-width non-joiner
      "\u200C",
      # Zero-width joiner
      "\u200D",
      # Left-to-right mark
      "\u200E",
      # Right-to-left mark
      "\u200F"
    ]
  end

  @doc """
  Returns a list of sample texts with RTL/LTR mixed content.
  """
  def sample_bidirectional_texts do
    [
      # Arabic with English
      "هذا نص يحتوي على English text",
      "مرحبا! Hello! كيف حالك?",
      "الرجاء الضغط على Submit button",

      # Hebrew with English
      "זהו טקסט בעברית עם English text",
      "שלום! Hello! מה שלומך?",
      "לחץ על Submit button להמשך",

      # Mixed Arabic and Hebrew
      "هذا نص بالعربية וזה טקסט בעברית",
      "مرحبا! שלום! كيف حالك? מה שלומך?",
      "الرجاء الضغط على כפתור השליחה",

      # Numbers and special characters
      "חשבון #1234 - حساب #5678",
      "מחיר: $99.99 - السعر: ٩٩.٩٩$",
      "טלפון: 050-1234567 - هاتف: ٠٥٠-١٢٣٤٥٦٧",

      # URLs and paths
      "Visit \u202B https://example.com/עברית \u202C for more info",
      "Open \u202B C:\\Users\\משתמש\\Documents \u202C folder",
      "Download from \u202B https://example.com/عربي/עברית \u202C",

      # Dates and times
      "Date: \u202B ١٢/٣/٢٠٢٤ \u202C (12/3/2024)",
      "Time: \u202B ١٥:٣٠ \u202C (15:30)",
      "Meeting at \u202B ٩:٠٠ صباحاً \u202C (9:00 AM)",

      # Complex nested content
      "English \u202B Arabic \u202B Hebrew \u202C English \u202C More English",
      "Start \u202B Middle \u202B End \u202C Back \u202C Done",
      "Left \u202B Center \u202B Right \u202C Left \u202C Done",

      # Explicit directional marks
      "Hello \u200E\u200F\u200E\u200F World",
      "Text \u200E\u200F\u200E\u200F More text",
      "Start \u200E\u200F\u200E\u200F End"
    ]
  end

  @doc """
  Returns a list of bidirectional tracking IDs.
  """
  def sample_bidirectional_ids do
    [
      "TRACK_עברית_001",
      "track_عربي_2024_001",
      "ID123עברית456",
      "tracking_id_عربي_123!@#$%^&*()",
      "track-2024-עברית-001",
      "track.2024.عربي.001",
      "track_2024_001_עברית_extra_long",
      # Empty string
      ""
    ]
  end

  @doc """
  Returns a list of sample HTML texts for testing.
  """
  def sample_html_texts do
    [
      # Simple HTML
      "<p>This is a test</p>",
      "<div>Simple content</div>",
      "<span>Inline content</span>",

      # HTML with attributes
      "<div class=\"test\" data-id=\"123\">Content</div>",
      "<p style=\"color: red;\">Styled content</p>",
      "<input type=\"text\" value=\"test\"/>",

      # Nested HTML
      "<div><p><span>Nested content</span></p></div>",
      "<article><header><h1>Title</h1></header><main>Content</main></article>",
      "<nav><ul><li>Item 1</li><li>Item 2</li></ul></nav>",

      # HTML with comments
      "<!-- comment -->Content<!-- another comment -->",
      "<div><!-- nested comment -->Content</div>",
      "<!-- start --><p>Content</p><!-- end -->",

      # Self-closing tags
      "<p>Content<br/>with break</p>",
      "<img src=\"test.jpg\" alt=\"test\"/>",
      "<input type=\"text\"/>",

      # HTML entities
      "<p>Content &amp; more</p>",
      "<div>&lt;escaped&gt; content</div>",
      "<span>&quot;quoted&quot; content</span>",

      # Complex structures
      """
      <div class="container">
        <header>
          <h1>Title</h1>
          <nav><ul><li>Menu</li></ul></nav>
        </header>
        <main>
          <article>
            <p>Content</p>
            <img src="test.jpg" alt="test"/>
          </article>
        </main>
        <footer>Footer</footer>
      </div>
      """,

      # RTL content
      "<div dir=\"rtl\">هذا نص اختبار</div>",
      "<p dir=\"rtl\">זהו טקסט בעברית</p>",
      "<span dir=\"rtl\">نص عربي</span>",

      # Mixed RTL/LTR
      "<div>English <span dir=\"rtl\">نص عربي</span> more English</div>",
      "<p>Left <span dir=\"rtl\">Right</span> Left</p>",
      "<div dir=\"rtl\">RTL <span dir=\"ltr\">LTR</span> RTL</div>",

      # Script and style tags
      "<script>console.log('test');</script>",
      "<style>.test { color: red; }</style>",
      "<script src=\"test.js\"></script>"
    ]
  end

  @doc """
  Returns a list of HTML-specific tracking IDs.
  """
  def sample_html_ids do
    [
      "TRACK_HTML_001",
      "track_div_2024_001",
      "ID123<span>456</span>",
      "tracking_id_<p>123</p>",
      "track-2024-<div>-001",
      "track.2024.<span>.001",
      "track_2024_001_<b>extra</b>",
      # Empty string
      ""
    ]
  end
end
