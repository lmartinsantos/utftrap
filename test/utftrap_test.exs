defmodule UTFtrapTest do
  use ExUnit.Case
  doctest UTFtrap
  alias UTFtrap.TestHelpers

  describe "string encoding/decoding" do
    test "works with HTML containing script tags" do
      text = "<script>console.log('test');</script><p>This is a test</p>"
      string = "tracking_id_123"
      encoded = UTFtrap.encode(text, string)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == string
    end
  end

  describe "text direction detection and correction" do
    test "detects LTR text direction" do
      text = "This is a left-to-right text"
      assert UTFtrap.detect_text_direction(text) == :ltr
    end

    test "detects RTL text direction" do
      text = "هذا نص من اليمين إلى اليسار"
      assert UTFtrap.detect_text_direction(text) == :rtl
    end

    test "detects neutral text direction" do
      text = "12345 !@#$%"
      assert UTFtrap.detect_text_direction(text) == :neutral
    end

    test "adds direction correction for LTR text" do
      # Create a text that would be interpreted as RTL after encoding
      text = "This is a test"
      data = "tracking_id"

      # Encode the data
      encoded = UTFtrap.encode(text, data)

      # Check that the encoded text has the correct direction
      assert UTFtrap.detect_text_direction(encoded) == :ltr

      # Verify that the data can still be decoded
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
    end

    test "adds direction correction for RTL text" do
      # Create a text that would be interpreted as LTR after encoding
      text = "هذا نص اختبار"
      data = "tracking_id"

      # Encode the data
      encoded = UTFtrap.encode(text, data)

      # Check that the encoded text has the correct direction
      assert UTFtrap.detect_text_direction(encoded) == :rtl

      # Verify that the data can still be decoded
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
    end

    test "handles mixed RTL and LTR content" do
      # Text with both Arabic and English
      text = "This is English هذا عربي"
      data = "test_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
    end

    test "handles text with explicit direction marks" do
      # Text with explicit LTR mark
      text_with_ltr = "\u200EThis is LTR text"
      assert UTFtrap.detect_text_direction(text_with_ltr) == :ltr

      # Text with explicit RTL mark
      text_with_rtl = "\u200Fهذا نص RTL"
      assert UTFtrap.detect_text_direction(text_with_rtl) == :rtl
    end

    test "handles text with multiple direction changes" do
      text = "English هذا عربي then back to English ثم عربي"
      data = "test_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
    end

    test "handles text with numbers in different contexts" do
      # Numbers in LTR context
      ltr_with_numbers = "Version 12.34"
      assert UTFtrap.detect_text_direction(ltr_with_numbers) == :ltr

      # Numbers in RTL context
      rtl_with_numbers = "النسخة 12.34"
      assert UTFtrap.detect_text_direction(rtl_with_numbers) == :rtl

      # Only numbers with some punctuation
      only_numbers = "12.34 (5,6)"
      assert UTFtrap.detect_text_direction(only_numbers) == :neutral
    end

    test "handles text with special characters" do
      # Special chars with LTR
      ltr_special = "Test: @#$%^&*"
      assert UTFtrap.detect_text_direction(ltr_special) == :ltr

      # Special chars with RTL
      rtl_special = "اختبار: @#$%^&*"
      assert UTFtrap.detect_text_direction(rtl_special) == :rtl

      # Only special chars
      only_special = "@#$%^&* ()"
      assert UTFtrap.detect_text_direction(only_special) == :neutral
    end

    test "handles empty and whitespace text" do
      # Empty string
      assert UTFtrap.detect_text_direction("") == :neutral

      # Only spaces
      assert UTFtrap.detect_text_direction("   ") == :neutral

      # Only newlines and tabs
      assert UTFtrap.detect_text_direction("\n\t\r") == :neutral
    end

    test "handles text with Unicode spaces and invisible characters" do
      # Text with various Unicode spaces
      text_with_spaces = "Test\u00A0text\u2007with\u202Fspaces"
      assert UTFtrap.detect_text_direction(text_with_spaces) == :ltr

      # RTL text with Unicode spaces
      rtl_with_spaces = "نص\u00A0عربي\u2007مع\u202Fفراغات"
      assert UTFtrap.detect_text_direction(rtl_with_spaces) == :rtl
    end

    test "handles text with HTML tags" do
      # LTR text with HTML
      ltr_html = "<div>This is <b>HTML</b> text</div>"
      assert UTFtrap.detect_text_direction(ltr_html) == :ltr

      # RTL text with HTML
      rtl_html = "<div>هذا نص <b>HTML</b> عربي</div>"
      assert UTFtrap.detect_text_direction(rtl_html) == :rtl
    end

    test "preserves direction in nested content" do
      # Nested RTL in LTR
      nested_text = "Start <span>English هذا عربي more English</span> end"
      data = "test_123"
      encoded = UTFtrap.encode(nested_text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
    end
  end

  describe "insertion point detection" do
    test "finds insertion point in plain text" do
      text = "This is a test text with multiple spaces"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that the text is still readable by checking word boundaries
      words = String.split(text)

      Enum.each(words, fn word ->
        # Remove any direction marks or invisible chars for comparison
        clean_encoded = String.replace(encoded, ~r/[\x{200E}\x{200F}\x{202A}-\x{202E}]/u, "")
        assert String.contains?(clean_encoded, word)
      end)
    end

    test "finds insertion point in HTML text" do
      text = "<div>This is a <b>test</b> text</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that HTML structure is preserved by checking tag pairs
      assert_html_structure(text, encoded)
    end

    test "avoids inserting in script tags" do
      text = "<script>console.log('test');</script><p>This is a test</p>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that script content is preserved exactly
      assert String.contains?(encoded, "<script>console.log('test');</script>")
      # Verify that paragraph structure is preserved
      assert_html_structure(text, encoded)
    end

    test "handles nested HTML structures" do
      text = "<div><p>This is a <span>test</span> text</p></div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that nested structure is preserved
      assert_html_structure(text, encoded)
    end

    test "handles text with no spaces" do
      text = "ThisIsATestTextWithNoSpaces"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
    end

    test "handles empty text" do
      text = ""
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
    end

    test "handles text with only HTML tags" do
      text = "<div></div><p></p>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
    end

    test "handles HTML with complex attributes" do
      text =
        "<div class=\"container\" data-test=\"value\" style=\"color: red;\" id=\"test-id\">This is a test</div>"

      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that attributes are preserved
      assert String.contains?(encoded, "class=\"container\"")
      assert String.contains?(encoded, "data-test=\"value\"")
      assert String.contains?(encoded, "style=\"color: red;\"")
      assert String.contains?(encoded, "id=\"test-id\"")
    end

    test "handles HTML with nested quotes in attributes" do
      text =
        "<div title=\"This is a 'quoted' text\" data-info=\"Some \"nested\" quotes\">Content</div>"

      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that quotes in attributes are preserved
      assert String.contains?(encoded, "title=\"This is a 'quoted' text\"")
      assert String.contains?(encoded, "data-info=\"Some \"nested\" quotes\"")
    end

    test "handles HTML with escaped characters in attributes" do
      text = "<div data-escaped=\"&lt;div&gt; &amp; &quot;test&quot;\">Content</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that escaped characters are preserved
      assert String.contains?(encoded, "data-escaped=\"&lt;div&gt; &amp; &quot;test&quot;\"")
    end

    test "handles HTML with self-closing tags" do
      text = "<div>Before <img src=\"test.jpg\" alt=\"test\"/> After</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that self-closing tags are preserved
      assert String.contains?(encoded, "<img src=\"test.jpg\" alt=\"test\"/>")
    end

    test "handles HTML with void elements" do
      text = "<div>Before <br> <hr/> <input type=\"text\"> After</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that void elements are preserved
      assert String.contains?(encoded, "<br>")
      assert String.contains?(encoded, "<hr/>")
      assert String.contains?(encoded, "<input type=\"text\">")
    end

    test "handles HTML with comments" do
      text = "<div><!-- This is a comment -->Content<!-- Another comment --></div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that comments are preserved
      assert String.contains?(encoded, "<!-- This is a comment -->")
      assert String.contains?(encoded, "<!-- Another comment -->")
    end

    test "handles HTML with CDATA sections" do
      text = "<div><![CDATA[This is <not> a tag]]>Content</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that CDATA sections are preserved
      assert String.contains?(encoded, "<![CDATA[This is <not> a tag]]>")
    end

    test "handles HTML with conditional comments" do
      text = "<div><!--[if IE]>IE specific content<![endif]-->Content</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that conditional comments are preserved
      assert String.contains?(encoded, "<!--[if IE]>")
      assert String.contains?(encoded, "<![endif]-->")
    end

    test "handles HTML with multiple script tags" do
      text =
        "<script>console.log('test');</script><div>Content</div><script src=\"test.js\"></script>"

      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that script tags are preserved and message is inserted in the div
      assert String.contains?(encoded, "console.log('test');")
      assert String.contains?(encoded, "<script src=\"test.js\"></script>")
      assert String.contains?(encoded, "<div>Content</div>")
    end

    test "handles HTML with style tags" do
      text = "<style>.test { color: red; }</style><div>Content</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that style tags are preserved
      assert String.contains?(encoded, "<style>.test { color: red; }</style>")
    end

    test "handles HTML with inline styles" do
      text = "<div style=\"color: red; font-size: 16px;\">Content</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that inline styles are preserved
      assert String.contains?(encoded, "style=\"color: red; font-size: 16px;\"")
    end

    test "handles HTML with data attributes" do
      text = "<div data-custom=\"value\" data-json='{\"key\": \"value\"}'>Content</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that data attributes are preserved
      assert String.contains?(encoded, "data-custom=\"value\"")
      assert String.contains?(encoded, "data-json='{\"key\": \"value\"}'")
    end

    test "handles HTML with event handlers" do
      text = "<div onclick=\"alert('test')\" onmouseover=\"console.log('hover')\">Content</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that event handlers are preserved
      assert String.contains?(encoded, "onclick=\"alert('test')\"")
      assert String.contains?(encoded, "onmouseover=\"console.log('hover')\"")
    end

    test "handles HTML with mixed content and empty elements" do
      text = "<div>Before <span></span> <br> <img src=\"test.jpg\"/> After</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that empty elements are preserved
      assert String.contains?(encoded, "<span></span>")
      assert String.contains?(encoded, "<br>")
      assert String.contains?(encoded, "<img src=\"test.jpg\"/>")
    end

    test "handles HTML with nested script tags" do
      text =
        "<script>var x = '<script>console.log(\"test\");</script>';</script><div>Content</div>"

      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that nested script tags are preserved
      assert String.contains?(encoded, "var x = '<script>console.log(\"test\");</script>';")
    end

    test "handles HTML with unclosed tags" do
      text = "<div>Content <span>More content <b>Bold</div>"
      data = "tracking_id_123"
      encoded = UTFtrap.encode(text, data)
      decoded = UTFtrap.decode_hidden(encoded)
      assert decoded == data
      # Verify that unclosed tags are preserved
      assert String.contains?(encoded, "<span>More content <b>Bold</div>")
    end
  end

  describe "test helpers" do
    test "sample_texts returns a list of texts in different languages" do
      texts = TestHelpers.sample_texts()
      assert is_list(texts)
      assert length(texts) > 0
      assert Enum.all?(texts, &is_binary/1)
    end

    test "sample_tracking_ids returns a list of tracking IDs" do
      ids = TestHelpers.sample_tracking_ids()
      assert is_list(ids)
      assert length(ids) > 0
      assert Enum.all?(ids, &is_binary/1)
      # Empty string should be included
      assert "" in ids
    end

    test "simulate_copy_paste preserves text content" do
      original = "Test text with special chars: \t\n\r"
      copied = TestHelpers.simulate_copy_paste(original)
      assert copied == original
    end

    test "simulate_copy_paste works with multiple iterations" do
      original = "Test text"
      copied = TestHelpers.simulate_copy_paste(original, 3)
      assert copied == original
    end

    test "unicode_spaces returns a list of Unicode space characters" do
      spaces = TestHelpers.unicode_spaces()
      assert is_list(spaces)
      assert length(spaces) > 0
      assert Enum.all?(spaces, &is_binary/1)
      # Regular space
      assert "\u0020" in spaces
      # No-break space
      assert "\u00A0" in spaces
    end

    test "sample_bidirectional_texts returns RTL/LTR mixed content" do
      texts = TestHelpers.sample_bidirectional_texts()
      assert is_list(texts)
      assert length(texts) > 0
      assert Enum.all?(texts, &is_binary/1)
      # Check for presence of RTL/LTR marks
      assert Enum.any?(texts, &String.contains?(&1, "\u202B"))
      assert Enum.any?(texts, &String.contains?(&1, "\u202C"))
    end

    test "sample_bidirectional_ids returns IDs with RTL characters" do
      ids = TestHelpers.sample_bidirectional_ids()
      assert is_list(ids)
      assert length(ids) > 0
      assert Enum.all?(ids, &is_binary/1)
      # Empty string should be included
      assert "" in ids
      # Check for presence of Hebrew/Arabic characters
      assert Enum.any?(ids, &String.contains?(&1, "עברית"))
      assert Enum.any?(ids, &String.contains?(&1, "عربي"))
    end

    test "sample_html_texts returns various HTML content" do
      html_texts = TestHelpers.sample_html_texts()
      assert is_list(html_texts)
      assert length(html_texts) > 0
      assert Enum.all?(html_texts, &is_binary/1)
      # Check for presence of HTML tags
      assert Enum.any?(html_texts, &String.contains?(&1, "<div>"))
      assert Enum.any?(html_texts, &String.contains?(&1, "<script>"))
      assert Enum.any?(html_texts, &String.contains?(&1, "<style>"))
    end

    test "sample_html_ids returns IDs with HTML tags" do
      ids = TestHelpers.sample_html_ids()
      assert is_list(ids)
      assert length(ids) > 0
      assert Enum.all?(ids, &is_binary/1)
      # Empty string should be included
      assert "" in ids
      # Check for presence of HTML tags
      assert Enum.any?(ids, &String.contains?(&1, "<span>"))
      assert Enum.any?(ids, &String.contains?(&1, "<p>"))
      assert Enum.any?(ids, &String.contains?(&1, "<div>"))
    end
  end

  describe "file operations" do
    setup do
      # Create temporary test files
      input_path = "test/fixtures/test_input.txt"
      output_path = "test/fixtures/test_output.txt"
      File.mkdir_p!("test/fixtures")
      File.write!(input_path, "This is a test file with some content.")

      # Clean up any existing output files
      if File.exists?(output_path), do: File.rm!(output_path)

      on_exit(fn ->
        # Clean up test files after tests
        File.rm(input_path)
        File.rm(output_path)
      end)

      %{input_path: input_path, output_path: output_path}
    end

    test "encodes message in file and writes to new file", %{
      input_path: input_path,
      output_path: output_path
    } do
      message = "secret_message_123"
      assert {:ok, ^output_path} = UTFtrap.File.encode_file(input_path, output_path, message)

      # Verify the encoded file exists and contains the message
      assert File.exists?(output_path)
      {:ok, encoded_content} = File.read(output_path)
      decoded = UTFtrap.decode_hidden(encoded_content)
      assert decoded == message
    end

    test "decodes message from encoded file", %{input_path: input_path, output_path: output_path} do
      message = "secret_message_123"
      {:ok, _} = UTFtrap.File.encode_file(input_path, output_path, message)

      assert {:ok, ^message} = UTFtrap.File.decode_file(output_path)
    end

    test "handles non-existent input file" do
      assert {:error, _} = UTFtrap.File.encode_file("nonexistent.txt", "output.txt", "message")
    end

    test "handles invalid output path" do
      assert {:error, _} =
               UTFtrap.File.encode_file(
                 "test/fixtures/test_input.txt",
                 "/invalid/path/output.txt",
                 "message"
               )
    end

    test "handles empty input file", %{input_path: input_path, output_path: output_path} do
      File.write!(input_path, "")
      message = "secret_message_123"
      assert {:ok, ^output_path} = UTFtrap.File.encode_file(input_path, output_path, message)

      # Verify the encoded file exists and contains the message
      assert File.exists?(output_path)
      {:ok, encoded_content} = File.read(output_path)
      decoded = UTFtrap.decode_hidden(encoded_content)
      assert decoded == message
    end

    test "handles large files with custom chunk size", %{
      input_path: input_path,
      output_path: output_path
    } do
      # Create a large file with repeated content
      content = String.duplicate("This is a test line. ", 1000)
      File.write!(input_path, content)

      message = "secret_message_123"

      assert {:ok, ^output_path} =
               UTFtrap.File.encode_file(input_path, output_path, message, chunk_size: 512)

      # Verify the encoded file exists and contains the message
      assert File.exists?(output_path)
      {:ok, encoded_content} = File.read(output_path)
      decoded = UTFtrap.decode_hidden(encoded_content)
      assert decoded == message
    end
  end

  describe "HTML file operations" do
    setup do
      # Define fixture paths
      simple_html_path = "test/fixtures/simple.html"
      complex_html_path = "test/fixtures/complex.html"
      mixed_direction_html_path = "test/fixtures/mixed_direction.html"

      # Define output paths
      simple_output_path = "test/fixtures/simple_encoded.html"
      complex_output_path = "test/fixtures/complex_encoded.html"
      mixed_output_path = "test/fixtures/mixed_encoded.html"

      # Clean up any existing output files
      Enum.each([simple_output_path, complex_output_path, mixed_output_path], fn path ->
        if File.exists?(path), do: File.rm!(path)
      end)

      on_exit(fn ->
        # Clean up output files after tests
        Enum.each([simple_output_path, complex_output_path, mixed_output_path], fn path ->
          File.rm(path)
        end)
      end)

      %{
        simple_html_path: simple_html_path,
        complex_html_path: complex_html_path,
        mixed_direction_html_path: mixed_direction_html_path,
        simple_output_path: simple_output_path,
        complex_output_path: complex_output_path,
        mixed_output_path: mixed_output_path
      }
    end

    test "encodes message in simple HTML file", %{
      simple_html_path: input_path,
      simple_output_path: output_path
    } do
      message = "tracking_id_123"
      assert {:ok, ^output_path} = UTFtrap.File.encode_file(input_path, output_path, message)

      # Verify the encoded file exists and contains the message
      assert File.exists?(output_path)
      {:ok, encoded_content} = File.read(output_path)
      decoded = UTFtrap.decode_hidden(encoded_content)
      assert decoded == message

      # Verify HTML structure is preserved
      assert_html_structure(File.read!(input_path), encoded_content)
    end

    test "encodes message in complex HTML file", %{
      complex_html_path: input_path,
      complex_output_path: output_path
    } do
      message = "tracking_id_456"
      assert {:ok, ^output_path} = UTFtrap.File.encode_file(input_path, output_path, message)

      # Verify the encoded file exists and contains the message
      assert File.exists?(output_path)
      {:ok, encoded_content} = File.read(output_path)
      decoded = UTFtrap.decode_hidden(encoded_content)
      assert decoded == message

      # Verify HTML structure is preserved
      assert_html_structure(File.read!(input_path), encoded_content)

      # Verify script content is preserved
      assert String.contains?(encoded_content, "document.getElementById('test-form')")
    end

    test "encodes message in mixed direction HTML file", %{
      mixed_direction_html_path: input_path,
      mixed_output_path: output_path
    } do
      message = "tracking_id_789"
      assert {:ok, ^output_path} = UTFtrap.File.encode_file(input_path, output_path, message)

      # Verify the encoded file exists and contains the message
      assert File.exists?(output_path)
      {:ok, encoded_content} = File.read(output_path)
      decoded = UTFtrap.decode_hidden(encoded_content)
      assert decoded == message

      # Verify HTML structure is preserved
      assert_html_structure(File.read!(input_path), encoded_content)

      # Verify RTL content is preserved
      assert String.contains?(encoded_content, "dir=\"rtl\"")
      assert String.contains?(encoded_content, "هذا نص عربي")
    end

    test "handles HTML file with custom chunk size", %{
      complex_html_path: input_path,
      complex_output_path: output_path
    } do
      message = "tracking_id_131415"

      assert {:ok, ^output_path} =
               UTFtrap.File.encode_file(input_path, output_path, message, chunk_size: 512)

      # Verify the encoded file exists and contains the message
      assert File.exists?(output_path)
      {:ok, encoded_content} = File.read(output_path)
      decoded = UTFtrap.decode_hidden(encoded_content)
      assert decoded == message

      # Verify HTML structure is preserved
      assert_html_structure(File.read!(input_path), encoded_content)
    end
  end

  # Helper function to verify HTML structure
  defp assert_html_structure(original, encoded) do
    # Extract all HTML tags from both texts
    original_tags = Regex.scan(~r/<[^>]+>/, original) |> List.flatten()
    encoded_tags = Regex.scan(~r/<[^>]+>/, encoded) |> List.flatten()

    # Verify that all original tags are present in the encoded text in the same order
    assert original_tags -- encoded_tags == []
    assert encoded_tags -- original_tags == []

    # Verify tag order is preserved
    original_tag_string = Enum.join(original_tags)
    encoded_tag_string = Enum.join(encoded_tags)
    assert original_tag_string == encoded_tag_string
  end
end
