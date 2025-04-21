defmodule UTFtrap.Insertion do
  @moduledoc """
  Handles finding insertion points in text for UTFtrap.
  """

  alias UTFtrap.HTML

  @doc """
  Finds the insertion point in text, considering HTML structure if present.
  Returns a tuple with the text before and after the insertion point.
  """
  def find_insertion_point(text) do
    if HTML.contains_html?(text) do
      find_html_insertion_point(text)
    else
      find_text_insertion_point(text)
    end
  end

  @doc """
  Finds the insertion point in HTML text.
  Returns a tuple with the text before and after the insertion point.
  """
  def find_html_insertion_point(text) do
    if HTML.contains_html?(text) do
      parts = HTML.split_html(text)
      text_nodes = Enum.filter(parts, &HTML.is_text_node?/1)
      text_nodes = Enum.filter(text_nodes, &(String.trim(&1) != ""))

      case length(text_nodes) do
        # If no text nodes, append at the end
        0 ->
          {text, ""}

        _ ->
          # Find the first text node with a space
          case Enum.find(text_nodes, &String.contains?(&1, " ")) do
            # If no spaces found, append at the end
            nil ->
              {text, ""}

            node_with_space ->
              # Find position of this node in original text
              case :binary.matches(text, node_with_space) do
                [] ->
                  {text, ""}

                matches ->
                  {pos, len} = List.last(matches)
                  # Find the first space in this node
                  space_pos =
                    String.slice(node_with_space, 0, len)
                    |> String.split(" ", parts: 2)
                    |> hd
                    |> String.length()

                  actual_pos = pos + space_pos

                  {String.slice(text, 0, actual_pos + 1),
                   String.slice(text, actual_pos + 1, String.length(text) - actual_pos - 1)}
              end
          end
      end
    else
      find_text_insertion_point(text)
    end
  end

  # Private helper functions

  defp find_text_insertion_point(text) do
    text = String.trim(text)

    case String.split(text, " ", parts: 2) do
      # No spaces found
      [text] -> {text, ""}
      [first, rest] -> {first <> " ", rest}
    end
  end
end
