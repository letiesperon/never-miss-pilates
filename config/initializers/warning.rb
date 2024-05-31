# frozen_string_literal: true

# https://github.com/jeremyevans/ruby-warning

# Configuration for warning gem (to silence warnings that we can't or won't fix right now)

# Uncomment to see backtrace for every warning (quite noisy for warnings from gems)
# Warning.process { :backtrace }

require 'warning'

# List here the warnings we want to silence until they are permanently fixed:
# Warning.ignore(/foo bar/)
