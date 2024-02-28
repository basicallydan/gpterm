# gpterm: a natural language interface for your terminal

**WARNING:** `gpterm` has very few guardrails. If used indiscriminately, it can wipe your entire system or leak information.

![gpterm-fb-for-dogs-18-feb](https://github.com/basicallydan/gpterm/assets/516325/db45357d-2270-4253-b344-10523bea34e1)

`gpterm` is a powerful, flexible and dangerous command-line tool designed to help you generate commands for your terminal using OpenAI's Chat Completions. It will not execute commands without your consent, but please do check which commands it is presenting before you let it execute them. Like so:

```bash
$ gpterm "Using git diff to gather info, commit all the latest changes with a descriptive commit message, then push the changes"
$ # It gathers info, asks for consent, and does the thing
$ [main 94a9292] Update README with gpterm usage example
$  1 file changed, 4 insertions(+)
```

## Getting Started

You can install it from RubyGems using `gem install gpterm`, or you can clone it and run it straight from the source.

Ensure you have Ruby installed on your system. Then, follow these steps:

- Clone the repository or download the source code.
- Navigate to the gpterm directory and run `bundle install` to install dependencies.
- Start the application by running `./bin/gpterm`

## Configuration

On first run, you'll be prompted to enter your OpenAI API key. This is required for the application to interact with OpenAI's API. You will also be asked to specify whether you'd like your `PATH` variable to be sent in the prompt, which can help with command generation.

## Usage

`gpterm <prompt> [options] [subcommand [options]]`

**Subcommands:**

- `preset` - `gpterm preset <name> <prompt>`
- `config` - `gpterm config [--openapi_key <value>|--send_path <true|false>]`

**Options:**
`-v`, `--verbose` Run verbosely

## Presets

You can save and reuse preset prompts for common or repeated tasks. To create a preset, use the `-s` option followed by a name and the prompt, separated by a comma.
To use a preset, simply pass its name as an argument when starting gpterm.

### Example Presets

I have been using the following presets while developing `gpterm` and have found them to be quite helpful.

- `gc`: **Makes and pushes a commit describing the most recent changes.**
  - Prompt: `"Commit all the latest changes to the current git branch, describing specifically what the changes are in the commit message. Please determine what the changes are before you write the commit message. You should use git diff and git status for information gathering"`
- `minorv`: **Does all the steps necessary in publishing a new version of this gem, including updating the changelog.**
  - Prompt: `"Bump to a new minor version of this gem (change the y and reset z in version number x.y.z). That means you need to add a new section to the changelog with 1-5 bullet points summarising the changes (check git logs since the most recent git tag), then commit that, then create a new git tag, pushing the tag to the remote, update the gemspec, build the gem and publish it to rubygems. DO NOT try to add or commit any .gemspec files to the repo, or any other files which are listed in .gitignore"`

## Contributing

Contributions are welcome! Feel free to open an issue or pull request.

## License

gpterm is open-source software licensed under the MIT license.

## Credit

[Dan Hough](https://danhough.com)/@basicallydan built this application.

[Alex Rudall](https://github.com/alexrudall)/@alexrudall developed [ruby-openai](https://github.com/alexrudall/ruby-openai) around which this application was built.

[OpenAI](https://openai.com/)/@openai built a powerful API full of great AI models upon which this whole concept relies.
