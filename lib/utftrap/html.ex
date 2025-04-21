defmodule UTFtrap.HTML do
  @moduledoc """
  Handles HTML-specific encoding and decoding operations for UTFtrap.
  """

  # List of void elements that don't need closing tags
  @void_elements ~w(area base br col embed hr img input link meta param source track wbr)

  @doc """
  Encodes a message into HTML text while preserving HTML structure.
  """
  def encode(html_text, encoded) do
    # Split HTML into text nodes and tags
    parts = split_html(html_text)

    # Find suitable text nodes for insertion
    text_nodes = find_suitable_text_nodes(parts)

    case text_nodes do
      [] -> html_text
      [single] -> insert_at_text_node(html_text, single, encoded)
      [node1 | _] -> insert_at_text_node(html_text, node1, encoded)
    end
  end

  @doc """
  Checks if the given text contains HTML tags.
  """
  def contains_html?(text) do
    String.match?(text, ~r/<[^>]+>/)
  end

  @doc """
  Splits HTML into text nodes and tags.
  Returns a list of alternating text nodes and HTML tags.
  """
  def split_html(html) do
    # First, protect special content
    {html, placeholders} = protect_special_content(html)

    # Split by tags while preserving attributes and spaces
    parts =
      html
      |> String.split(~r/(<[^>]*>)/)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&restore_special_content(&1, placeholders))
      |> Enum.map(&normalize_tag/1)
      |> handle_unclosed_tags()

    # Clean up any empty text nodes
    parts
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Checks if a string is a text node (not an HTML tag).
  """
  def is_text_node?(text) do
    text != "" and not String.starts_with?(text, "<") and not String.ends_with?(text, ">")
  end

  # Private helper functions

  defp find_suitable_text_nodes(parts) do
    parts
    |> Enum.with_index()
    |> Enum.filter(fn {part, _} -> is_text_node?(part) end)
    |> Enum.filter(fn {_part, idx} ->
      # Ensure the text node is not inside script or style tags
      not is_in_special_tag?(parts, idx)
    end)
    |> Enum.map(fn {part, _} -> part end)
  end

  defp is_in_special_tag?(parts, idx) do
    parts
    |> Enum.take(idx)
    |> Enum.reverse()
    |> Enum.find(&is_special_tag?/1)
    |> case do
      nil -> false
      _ -> true
    end
  end

  defp is_special_tag?(text) do
    String.match?(text, ~r/<(script|style)[^>]*>/) and
      not String.match?(text, ~r/<\/(script|style)>/)
  end

  defp insert_at_text_node(html, node, encoded) do
    case :binary.matches(html, node) do
      [] ->
        html

      matches ->
        {pos, _len} = List.last(matches)
        # Convert character positions to byte positions
        pos_bytes = byte_size(String.slice(html, 0, pos))
        len_bytes = byte_size(node)
        after_pos_bytes = byte_size(html) - (pos_bytes + len_bytes)

        before = binary_part(html, 0, pos_bytes + len_bytes)
        after_text = binary_part(html, pos_bytes + len_bytes, after_pos_bytes)
        before <> encoded <> after_text
    end
  end

  defp normalize_tag(tag) when is_binary(tag) do
    cond do
      not String.starts_with?(tag, "<") -> tag
      is_void_element?(tag) -> ensure_self_closing(tag)
      true -> tag
    end
  end

  defp is_void_element?(tag) do
    tag
    |> extract_tag_name()
    |> case do
      nil -> false
      name -> name in @void_elements
    end
  end

  defp extract_tag_name(tag) do
    case Regex.run(~r/<([^\s>\/]+)/, tag) do
      [_, name] -> name
      _ -> nil
    end
  end

  defp ensure_self_closing(tag) do
    if String.ends_with?(tag, "/>"), do: tag, else: String.replace_suffix(tag, ">", "/>")
  end

  defp handle_unclosed_tags(parts) do
    parts
    |> Enum.reduce({[], []}, fn part, {acc, stack} ->
      cond do
        is_opening_tag?(part) ->
          {[part | acc], [extract_tag_name(part) | stack]}

        is_closing_tag?(part) ->
          tag_name = extract_closing_tag_name(part)

          case Enum.find_index(stack, &(&1 == tag_name)) do
            nil ->
              {[part | acc], stack}

            idx ->
              {_, new_stack} = Enum.split(stack, idx + 1)
              {[part | acc], new_stack}
          end

        true ->
          {[part | acc], stack}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp is_opening_tag?(tag) do
    String.match?(tag, ~r/^<[^\/][^>]*>$/)
  end

  defp is_closing_tag?(tag) do
    String.match?(tag, ~r/^<\/[^>]+>$/)
  end

  defp extract_closing_tag_name(tag) do
    case Regex.run(~r/<\/([^>]+)>/, tag) do
      [_, name] -> name
      _ -> nil
    end
  end

  defp protect_special_content(text) do
    placeholders = %{
      comments: [],
      cdata: [],
      script: [],
      style: []
    }

    {text, placeholders} = protect_comments(text, placeholders)
    {text, placeholders} = protect_cdata(text, placeholders)
    {text, placeholders} = protect_script_content(text, placeholders)
    {text, placeholders} = protect_style_content(text, placeholders)

    {text, placeholders}
  end

  defp protect_comments(text, placeholders) do
    {text, comments} =
      Regex.scan(~r/<!--.*?-->/s, text)
      |> Enum.reduce({text, []}, fn [match], {text, comments} ->
        placeholder = "COMMENT_PLACEHOLDER_#{length(comments)}"
        {String.replace(text, match, placeholder), [match | comments]}
      end)

    {text, %{placeholders | comments: comments}}
  end

  defp protect_cdata(text, placeholders) do
    {text, cdata} =
      Regex.scan(~r/<!\[CDATA\[.*?\]\]>/s, text)
      |> Enum.reduce({text, []}, fn [match], {text, cdata} ->
        placeholder = "CDATA_PLACEHOLDER_#{length(cdata)}"
        {String.replace(text, match, placeholder), [match | cdata]}
      end)

    {text, %{placeholders | cdata: cdata}}
  end

  defp protect_script_content(text, placeholders) do
    {text, script} =
      Regex.scan(~r/<script[^>]*>.*?<\/script>/s, text)
      |> Enum.reduce({text, []}, fn [match], {text, script} ->
        placeholder = "SCRIPT_PLACEHOLDER_#{length(script)}"
        {String.replace(text, match, placeholder), [match | script]}
      end)

    {text, %{placeholders | script: script}}
  end

  defp protect_style_content(text, placeholders) do
    {text, style} =
      Regex.scan(~r/<style[^>]*>.*?<\/style>/s, text)
      |> Enum.reduce({text, []}, fn [match], {text, style} ->
        placeholder = "STYLE_PLACEHOLDER_#{length(style)}"
        {String.replace(text, match, placeholder), [match | style]}
      end)

    {text, %{placeholders | style: style}}
  end

  defp restore_special_content(text, placeholders) do
    text = restore_style_content(text, placeholders.style)
    text = restore_script_content(text, placeholders.script)
    text = restore_cdata(text, placeholders.cdata)
    text = restore_comments(text, placeholders.comments)
    text
  end

  defp restore_comments(text, comments) do
    Enum.with_index(comments)
    |> Enum.reduce(text, fn {content, index}, text ->
      String.replace(text, "COMMENT_PLACEHOLDER_#{index}", content)
    end)
  end

  defp restore_cdata(text, cdata) do
    Enum.with_index(cdata)
    |> Enum.reduce(text, fn {content, index}, text ->
      String.replace(text, "CDATA_PLACEHOLDER_#{index}", content)
    end)
  end

  defp restore_script_content(text, script) do
    Enum.with_index(script)
    |> Enum.reduce(text, fn {content, index}, text ->
      String.replace(text, "SCRIPT_PLACEHOLDER_#{index}", content)
    end)
  end

  defp restore_style_content(text, style) do
    Enum.with_index(style)
    |> Enum.reduce(text, fn {content, index}, text ->
      String.replace(text, "STYLE_PLACEHOLDER_#{index}", content)
    end)
  end
end
