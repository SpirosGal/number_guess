#!/bin/bash

# Define PSQL command with a custom delimiter
PSQL="psql -X --username=freecodecamp --dbname=number_guess -F',' -A -t -c"

# Generate a random number between 1 and 1000
NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt user to enter username
echo "Enter your username:" 
read USERNAME 

# Check if the username exists and retrieve user information
RESULT=$($PSQL "SELECT games_played, best_game FROM users WHERE username = '$USERNAME';")

if [[ -z $RESULT ]]; then
    # User does not exist, insert new user
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    $PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$USERNAME', 0, NULL);" >/dev/null
else
    # User exists, parse games played and best game
    IFS=',' read -r GAMES_PLAYED BEST_GAME <<< "$RESULT"
    GAMES_PLAYED=${GAMES_PLAYED//\'/} 
    BEST_GAME=${BEST_GAME//\'/}
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Initialize game variables
echo "Guess the secret number between 1 and 1000:" 
THIS_GAME=0

while read USERGUESS; do
    # Validate user input
    if ! [[ $USERGUESS =~ ^[0-9]+$ ]]; then
        echo "That is not an integer, guess again:"
        continue
    fi

    # Increment guess count
    ((THIS_GAME++))

    # Check guess against secret number
    if [[ $USERGUESS -gt $NUMBER ]]; then
        echo "It's lower than that, guess again:"
    elif [[ $USERGUESS -lt $NUMBER ]]; then
        echo "It's higher than that, guess again:"
    else
        echo "You guessed it in $THIS_GAME tries. The secret number was $NUMBER. Nice job!"
        break
    fi
done

# Update users games played and best game
$PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR best_game > $THIS_GAME THEN $THIS_GAME ELSE best_game END WHERE username = '$USERNAME';" >/dev/null
