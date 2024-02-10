#!/bin/bash

# 1. Prompt the user for the Trello board URL
read -p "Please enter your Trello board URL: " trelloUrl

# 2. Extract the "O7mSeCJk" part from the entered URL
boardId=$(echo "$trelloUrl" | sed 's/.*\/b\/\([^/]*\)\/.*/\1/')

# 3. Prompt the user for the Trello API key
read -p "Please enter your Trello API key: " apiKey

# 4. Prompt the user for the Trello token
read -p "Please enter your Trello token: " token

# 5. Make a curl request to get the lists of the board
response=$(curl -sS "https://api.trello.com/1/boards/$boardId/lists?key=$apiKey&token=$token")

# Add one line break before displaying the response
echo -e "\n"

# Display the idBoard only once
echo "idBoard : $boardId"

# One line break
echo -e "\n"

# Display information for each list
echo "List information:"
echo -e "\n"
echo "$response" | jq -r '.[] | "List: \(.name) \nList ID: \(.id) \n\n"'

# One line break
echo -e "\n"
