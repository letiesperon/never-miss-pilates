# frozen_string_literal: true

require 'English'
require 'optparse'

task :linters do
  desc 'Runs linters configured for the project. (Select -a to autofix)'
  options = {}
  OptionParser.new { |opts|
    opts.on('-a') { |autofix| options[:autofix] = autofix }
    opts.on('-l LINTERS',
            'Comma delimited list of linters to run: rubocop',
            ' (runs all when omitted)') do |linters|
      options[:linters] = linters
    end
  }.parse!

  # get an array of the files changed from master
  # (they need to be filtered by certain linters)
  files_diff = `git diff --diff-filter=ACMRTUXB --name-only origin/master...`.split("\n")
  unless $CHILD_STATUS.success?
    warn 'ERROR: could not obtain the list of changed files.'
    exit false
  end

  if files_diff.empty?
    puts_header 'linters.rake: files diff is empty, exiting.'
    # exit true so that CI does not consider this a failure
    exit
  end

  configs = get_configs(files_diff)

  linters_with_errors = []

  puts_header "CANDIDATES: #{files_diff.count} files"

  # run linters, tracking which ones fail
  configs.each do |linter, config|
    unless run_linter?(linter, options[:linters])
      puts_header "SKIPPING LINTER: #{linter} (-l option=#{options[:linters]})"
      next
    end
    if config[:files].empty?
      puts_header "SKIPPING LINTER: #{linter} (no applicable files)"
      next
    end

    # makes ctrl-f type searching fo reach linter's output easier
    puts_header "RUNNING LINTER: #{linter} (#{config[:files].count} files)"
    cmd = config[:cmd]
    cmd.push(config[:fix_arg]) if config[:fix_arg] && options[:autofix]
    cmd.push(*config[:files])
    linters_with_errors << linter unless system(*cmd)
  end

  unless linters_with_errors.empty?
    warn '-' * 80,
         "The following linters failed: #{linters_with_errors.join(', ')}",
         "\nCheck output of each linter for details.", '-' * 80
    # exit false equates to a non-zero return code to the calling shell,
    # which signals CI to fail this step
    exit false
  end
rescue RuntimeError => e
  e.instance_eval do
    def skip_bugsnag
      true
    end
  end
  raise e
end

def puts_header(msg)
  puts '-' * 40, msg, '-' * 40
end

def run_linter?(linter, linters)
  (linters && linters =~ /#{linter}(,|$)/) || !linters
end

def get_configs(files_diff)
  {
    rubocop: {
      cmd: %w[bundle exec rubocop --force-exclusion],
      fix_arg: '-A',
      files: files_diff
    }
  }
end
