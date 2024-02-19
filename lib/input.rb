module Input
  # Ensures the user enters a non-empty value
  def self.non_empty
    input = STDIN.gets.chomp.strip
    while input.length == 0
      puts 'Please enter a non-empty value:'.colorize(:yellow)
      input = STDIN.gets.chomp.strip
    end
    input
  end

  # Ensures the user enters "y" or "n"
  def self.yes_or_no
    input = STDIN.gets.chomp.downcase
    while ['y', 'n'].include?(input) == false
      puts 'Please enter "y/Y" or "n/N":'.colorize(:yellow)
      input = STDIN.gets.chomp.downcase
    end
    input
  end
end