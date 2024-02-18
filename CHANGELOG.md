# 0.6.1

- Updated prompts.yml to include guidelines on command execution and multiline strings restriction
- Updated path to prompts.yml in client.rb to be more robust by using File.join
- Updated exit_with_message method to support optional color parameter in gpterm.rb
- Credit in readme
- Preparing the changelog for a new version
- Refactored client.rb to dynamically set the model based on configuration. Enhanced gpterm.rb to include user input for model preference and improved configuration setup process.

# 0.6.0

- Allow the model to be configured

# 0.5.0

- Updated user prompts for clarity in gpterm.rb by adding 'then hit return' to all user input instructions.
- Added input validation methods in gpterm.rb: get_yes_or_no for confirming actions with 'y' or 'n', and get_non_empty_input to ensure non-empty user inputs.
- Refactor gpterm.rb: streamline command execution and improve exit message handling.
- Refactor Client class: rename openapi_client to openai_client and update method calls accordingly.
- DRY the interactions with openai client

# 0.2.0

- Changed the interface to use a mixture of positional args, subcommands and options

# 0.1.1

- Switch to using gpt-4-turbo-preview

# 0.1.0

- First release
- Includes basic features to generate commands with limited interactivity
- Colourful prompts to make it easier to distinguish between types of messages
- Still quite verbose but it works!
