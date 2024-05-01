#!/bin/bash -e

# Define the metrics file name
metrics_file="github-metrics.svg"

# Function to validate the number of arguments
validate_arguments() {
  if [ "$#" -ne 1 ]; then
    echo "Error: Incorrect number of arguments. Usage: $0 <commit>"
    exit 0
  fi
}

# Function to check if the commit exists
check_commit_existence() {
  if ! git rev-parse --quiet --verify "$1^{commit}" > /dev/null; then
    echo "Error: Commit $1 does not exist"
    exit 0
  fi
}

# Function to check if the parent commit exists
check_commit_parent_existence() {
  if ! git rev-parse --quiet --verify "$1^" > /dev/null; then
    echo "Error: Parent of commit $1 does not exist"
    exit 0
  fi
}

# Function to check if the metrics file exists
check_metrics_exists() {
  if ! git cat-file -e "$1:$metrics_file"; then
    echo "Error: $metrics_file does not exist in commit $1"
    exit 0
  fi
}

# Function to check for changes in metrics file
check_metrics_changes() {
  short_stat=$(git diff --shortstat "$1^" "$1" "$metrics_file")

  if [ -z "$short_stat" ]; then
    echo "Error: No changes in $metrics_file"
    exit 0
  fi
}

# Function to check for excessive changes
check_excessive_changes() {
  one_line_change=' 1 file changed, 1 insertion(+), 1 deletion(-)'
  if [ "$short_stat" != "$one_line_change" ]; then
    echo "Error: Too many changes in $1"
    echo "$short_stat"
    exit 0
  fi
}

# Function to check for last updated change
check_last_updated_change() {
  git_diff_output=$(git diff "$1^" "$1" --unified=0 --word-diff | tail +6)
  search_string='<span>Last updated .+, .+ \(timezone [A-Za-z/]+\) with lowlighter/metrics@[0-9.]+</span>'
  if ! echo "$git_diff_output" | grep --quiet -E "$search_string"; then
    echo "Error: No change to Last updated"
    exit 0
  fi
}

# Main function
main() {
  validate_arguments "$@"
  check_commit_existence "$1"
  check_commit_parent_existence "$1"
  check_metrics_exists "$1"
  check_metrics_changes "$1"
  check_excessive_changes "$1"
  #check_last_updated_change "$1"

  # Get the metrics file from the parent commit
  git checkout "$1^" "$metrics_file"
}

# Call the main function with passed arguments
main "$@"
