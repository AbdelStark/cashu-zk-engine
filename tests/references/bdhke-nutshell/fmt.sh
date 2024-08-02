#!/bin/bash

# Find all Python files in the current directory and subdirectories
python_files=$(find . -name "*.py")

# Run Black on all Python files
poetry run black $python_files

# Run isort on all Python files
poetry run isort $python_files

echo "Formatting complete!"