echo "Running Release Tasks"

echo "Migrating:"
bundle exec rake db:migrate
