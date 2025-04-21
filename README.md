# UTFtrap

> **Disclaimer**: UTFtrap is an experimental project intended for intellectual exploration and research purposes only. It should not be relied upon for production use or serious security applications. The techniques demonstrated here are meant to spark discussion and learning about text encoding, Unicode properties, and creative approaches to content tracking. While interesting from an academic perspective, invisible text markers can be detected and removed by those who know to look for them. This is not a substitute for proper DRM, watermarking, or content protection systems.

## Overview

UTFtrap is an Elixir library and tool that helps content creators and organizations protect their intellectual property by embedding invisible tracking markers into text content. These markers are undetectable to the human eye and survive copy-paste operations, making them perfect for identifying where and by whom your content is being used without permission.

## Potential use cases

Here are some key ways to leverage UTFtrap for protecting content:

### Track Content Leaks

1. **Paid Newsletters or Private Blog Posts**: Generate unique tracking codes for each authorized reader, embed the code in multiple locations throughout your posts and if content appears elsewhere, you can identify the source of the leak.

2. **Secure Document Distribution** Watermark confidential documents with recipient-specific codes so you can track unauthorized sharing back to the original recipient.

3. **Email Protection** Add unique identifiers to important emails, embed different codes for each recipient and monitor if sensitive emails are forwarded inappropriately

4. **Chat Message Security** Insert tracking codes in WhatsApp/Slack messages, use different codes for different recipients/channels and identify which team member leaked confidential chats

5. **Document Timestamping** Embed creation dates and author identifiers, create verifiable proof of when content was created, which is useful for copyright disputes and proving ownership

## Important Notes on Compatibility

While UTFtrap's Unicode directional marks generally survive copy-paste operations, there are some environments where these marks may not be preserved:

- Pre-UTF-8 era software, which is mostly deprecated by today standards. We are talking Windows 98/Me, MacOS 9, AmigaOS, OS/2, etc...
- Terminal emulators: Some terminal applications strip or ignore Unicode directional marks
- Command-line interfaces (CLIs): Tools like `cat`, `echo`, or other CLI text processors may not handle these marks correctly
- Text editors with limited Unicode support: Basic text editors might not properly display or preserve these characters
- Programming IDEs: Some IDEs may normalize or strip Unicode control characters when pasting (and some other explicitely show them, so good for debugging!)
- Plain text email clients: Basic email clients may not maintain these invisible marks

However, the marks reliably survive in most modern environments, including:

- Web browsers and web-based applications
- Rich text editors
- Modern word processors
- Social media platforms
- Office suites like Google Docs or Office 365
- Most messaging applications, even Whatsapp and Telegram Messages!

For best results, test the preservation of marks in your specific use case and target environment.

## How It Works

UTFtrap uses Unicode directional marks (LTR and RTL) to encode hidden information within text. These marks are:
- Invisible to the human eye
- Preserved during copy-paste operations
- Machine-detectable for verification
- Non-intrusive to the reading experience

The library can encode any string as hidden markers, allowing you to embed unique identifiers, timestamps, or any other tracking information you need.

The general encoding used is as simple as:

- A `right-to-left` or `RTL` character is a binary `0`
- A `left-to-right` or `LTR` character is a binary `1`

Then, the message is encoded following these rules:

- A header consisting of Three `RTL` and Three `LTR`s
- 16 "bits" encoded with `RTL` and `LTR`s with the length of the encoded message
- As many `RTL` and `LTR` characters as needed to encode the message.
- A footer consisting of Two `RTL` and another two `LTR`s
- If needed, a character resetting the direction of the string to the previous direction expected.

  

### Requirements

To use UTFtrap, you'll need a working Elixir installation. We recommend using `asdf` version manager by following the [official installation guide](https://asdf-vm.com/guide/getting-started.html).

Once you have `asdf` installed, add the Elixir plugin to asdf. 
```bash
asdf plugin add elixir
```

This project provides a `.tool-versions` that should make `asdf` autodetect the expected elixir version and allow you to easily install and activate it.

### Using the Command Line Interface

In order to build the command line interface, get it and build from sources.

```bash
# Install from Hex
mix escript.install hex utftrap

# Or build from source
git clone https://github.com/lmartinsantos/utftrap.git
cd utftrap
mix escript.build
```

This will make `utftrap` built. You might need to symlink it or access as `./utftrap` if you don't install the binary.

```bash
# Show help
utftrap --help

# Encode a message in a file
utftrap --encode --input input.txt --output output.txt --message "secret message"

# Decode a message from a file
utftrap --decode --input encoded.txt
```

## Usage as Elixir Library

### Installation

Add UTFtrap to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:utftrap, "~> 0.1.0"}
  ]
end
```

### Encoding Data

```elixir
# Encode a number
text = "This is a sample text that will contain hidden information."
encoded = UTFtrap.encode(text, 12345)

# Encode a string
encoded = UTFtrap.encode(text, "tracking_id_123")
```

### Decoding Data

```elixir
# Decode a number
number = UTFtrap.decode_hidden(encoded_text)

# Decode a string
string = UTFtrap.decode_hidden(encoded_text)
```

### Text Direction Detection

UTFtrap automatically detects the text direction of your content and adds correction marks if needed to maintain the original direction:

```elixir
# Detect text direction
direction = UTFtrap.detect_text_direction("This is LTR text")  # Returns :ltr
direction = UTFtrap.detect_text_direction("هذا نص RTL")        # Returns :rtl
direction = UTFtrap.detect_text_direction("12345 !@#$%")      # Returns :neutral
```

## Example

```elixir
# Original text
text = "Welcome to our blog post about cybersecurity."

# Encode a tracking ID
encoded = UTFtrap.encode(text, "TRACK_2024_001")

# Later, when you find this text somewhere else
tracking_id = UTFtrap.decode_hidden(found_text)
# Returns: "TRACK_2024_001"
```

## Use Cases

- Track unauthorized content copying
- Identify the source of leaked documents
- Monitor content distribution
- Protect intellectual property
- Gather evidence of copyright infringement

## Security Considerations

- The hidden markers are not encryption and should not be used for secure data transmission
- The markers can be removed by stripping all Unicode directional marks
- Consider using this in combination with other content protection measures

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## File Operation

You can encode/decode data from full files with the `File` module.

### Functions

1. `encode_file/4` - Encodes a message in a file and writes it to a new file:
   - Takes input path, output path, message, and optional parameters
   - Supports chunk-based processing for large files
   - Returns `{:ok, output_path}` on success or `{:error, reason}` on failure

2. `decode_file/2` - Decodes a message from an encoded file:
   - Takes file path and optional parameters
   - Returns `{:ok, message}` on success or `{:error, reason}` on failure

### Usage

```elixir
# Encode a message in a file
UTFtrap.File.encode_file("input.txt", "output.txt", "secret message")

# Encode a number in a file
UTFtrap.File.encode_file("input.html", "output.html", 12345)

# Decode a message from a file
UTFtrap.File.decode_file("encoded.txt")

# Process large files with custom chunk size
UTFtrap.File.encode_file("large_input.txt", "large_output.txt", "secret message", chunk_size: 2048)
```
