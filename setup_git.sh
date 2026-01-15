#!/bin/bash

# Nebula Core - Git Setup and GitHub Push Script
# This script will help you push your project to GitHub

echo "🌌 Nebula Core - GitHub Setup"
echo "=============================="
echo ""

# Step 1: Configure Git identity
echo "📝 Step 1: Configure Git Identity"
echo "Please enter your GitHub username:"
read -p "Username: " git_username

echo "Please enter your GitHub email:"
read -p "Email: " git_email

git config --global user.name "$git_username"
git config --global user.email "$git_email"

echo "✅ Git identity configured!"
echo ""

# Step 2: Create initial commit
echo "📦 Step 2: Creating initial commit..."
git add .
git commit -m "Initial commit: Nebula Core - Firebase-based ESP32 Smart Switch Control System"

echo "✅ Initial commit created!"
echo ""

# Step 3: GitHub repository setup
echo "🔗 Step 3: GitHub Repository Setup"
echo ""
echo "Please create a new repository on GitHub:"
echo "1. Go to: https://github.com/new"
echo "2. Repository name: nebula_core (or your preferred name)"
echo "3. Description: Production-Ready ESP32 Smart Switch Control System"
echo "4. Keep it PUBLIC or PRIVATE (your choice)"
echo "5. DO NOT initialize with README, .gitignore, or license"
echo "6. Click 'Create repository'"
echo ""
echo "After creating the repository, enter the repository URL:"
echo "Example: https://github.com/yourusername/nebula_core.git"
read -p "Repository URL: " repo_url

# Step 4: Add remote and push
echo ""
echo "🚀 Step 4: Pushing to GitHub..."
git remote add origin "$repo_url"
git branch -M main
git push -u origin main

echo ""
echo "✅ SUCCESS! Your project is now on GitHub!"
echo ""
echo "🌟 Next steps:"
echo "1. Visit your repository: ${repo_url%.git}"
echo "2. Add topics/tags: firebase, esp32, flutter, iot, smart-home"
echo "3. Enable GitHub Pages (optional)"
echo "4. Star your own repo! ⭐"
echo ""
echo "Happy coding! 🚀"
