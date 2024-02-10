# Prompt the user for the Trello board URL
Write-Host -NoNewline "Please enter your Trello board URL: "
$trelloUrl = Read-Host

# Extract the "xxxxxxxx" part from the entered URL
$boardId = $trelloUrl -replace '.*\/b\/([^/]+)\/.*', '$1'

# Prompt the user for the Trello API key
Write-Host -NoNewline "Please enter your Trello API key: "
$apiKey = Read-Host

# Prompt the user for the Trello token
Write-Host -NoNewline "Please enter your Trello token: "
$token = Read-Host

# Make a curl request to get the lists of the board
$response = & curl.exe -sS "https://api.trello.com/1/boards/$boardId/lists?key=$apiKey&token=$token"

# Add one line break before displaying the response
Write-Host ""

# Display the idBoard only once
Write-Host "idBoard : $boardId"
Write-Host ""

# Display information for each list
Write-Host "List information:"
Write-Host ""

# Convert the JSON response to PowerShell object
$jsonResponse = $response | ConvertFrom-Json

# Iterate through each list and display its name and ID
foreach ($list in $jsonResponse) {
    Write-Host "List: $($list.name)"
    Write-Host "List ID: $($list.id)"
    Write-Host ""
}

# Wait for user to input "end" to terminate the script
do {
    $input = Read-Host -Prompt "Enter 'end' to terminate the script"
} while ($input -ne "end")
