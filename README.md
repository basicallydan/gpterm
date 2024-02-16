# GPTerminal
GPTerminal is a command-line application that allows interaction with OpenAI's GPT models. It's designed for easy use and customization through prompts and presets.
## Getting Started
To use GPTerminal, ensure you have Ruby installed on your system. Then, follow these steps:
- Clone the repository or download the source code.
- Navigate to the GPTerminal directory and run `bundle install` to install dependencies.
- Start the application by running `ruby main.rb`.
## Configuration
On first run, you'll be prompted to enter your OpenAI API key. This is required for the application to interact with OpenAI's API.
## Usage
GPTerminal can be used with the following options:
- `-p`, `--prompt PROMPT`: Set a custom prompt for generating text.
- `-s`, `--save NAME,PROMPT`: Create a custom preset prompt that can be reused.
Without any options, GPTerminal will prompt you to enter a text prompt manually.
## Presets
You can save and reuse preset prompts for common or repeated tasks. To create a preset, use the `-s` option followed by a name and the prompt, separated by a comma.
To use a preset, simply pass its name as an argument when starting GPTerminal.
## Example
```
$ ruby main.rb -p 'Tell me a joke'
```
This command uses a custom prompt to generate a joke.
```
$ ruby main.rb funny_joke
```
This command uses a preset named 'funny_joke' to generate a joke.
## Contributing
Contributions are welcome! Feel free to open an issue or pull request.
## License
GPTerminal is open-source software licensed under the MIT license.
