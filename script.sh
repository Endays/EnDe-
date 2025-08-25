#!/bin/bash

main_menu() {
    while true; do
        echo "======================"
        echo "        MAIN MENU"
        echo "======================"
        echo "1) Encode (Encrypt)"
        echo "2) Decode (Decrypt)"
        echo "3) Create Key"
        echo "4) Exit"
        echo -n "Enter choice [1-4]: "
        read choice

        case $choice in
            1) Encryption_Menu ;;
            2) Decryption_Menu ;;
            3) Key_Menu ;;
            4) echo "Goodbye!"; exit 0 ;;
            *) echo "Invalid option. Try again." ;;
        esac
        echo
    done
}

Encryption_Menu() {
    while true; do
        echo "---- ENCRYPTION MENU ----"
        echo "1) Encrypt with existing key file"
        echo "2) Back"
        echo -n "Enter choice [1-2]: "
        read subchoice
        case $subchoice in
            1)
                echo "Enter key file name:"
                read keyfile
                if [[ ! -f "$keyfile" ]]; then
                    echo "Key file not found!"
                    continue
                fi

                echo "Enter password to unlock key file:"
                read -s keypass

                tmpfile=$(mktemp)
                if ! openssl enc -d -aes-256-cbc -pbkdf2 -in "$keyfile" -out "$tmpfile" -pass pass:"$keypass" 2>/dev/null; then
                    echo "Wrong password or corrupted key file!"
                    rm -f "$tmpfile"
                    continue
                fi
                source "$tmpfile"
                rm -f "$tmpfile"

                echo "Enter file to encrypt:"
                read infile
                echo "Overwrite $infile? (y/n)"
                read overwrite

                if [[ "$overwrite" == "y" ]]; then
                    tmpout=$(mktemp)
                    if openssl enc -aes-256-cbc -in "$infile" -out "$tmpout" -K "$KEY" -iv "$IV"; then
                        mv "$tmpout" "$infile"
                        echo "File encrypted safely in-place -> $infile"
                    else
                        echo "Encryption failed! Original file kept."
                        rm -f "$tmpout"
                    fi
                else
                    echo "Enter output file name:"
                    read outfile
                    openssl enc -aes-256-cbc -in "$infile" -out "$outfile" -K "$KEY" -iv "$IV"
                    echo "File encrypted -> $outfile"
                fi
                ;;
            2) return ;;
            *) echo "Invalid option. Try again." ;;
        esac
        echo
    done
}

Decryption_Menu() {
    while true; do
        echo "---- DECRYPTION MENU ----"
        echo "1) Decrypt with existing key file"
        echo "2) Back"
        echo -n "Enter choice [1-2]: "
        read subchoice
        case $subchoice in
            1)
                echo "Enter key file name:"
                read keyfile
                if [[ ! -f "$keyfile" ]]; then
                    echo "Key file not found!"
                    continue
                fi

                echo "Enter password to unlock key file:"
                read -s keypass

                tmpfile=$(mktemp)
                if ! openssl enc -d -aes-256-cbc -pbkdf2 -in "$keyfile" -out "$tmpfile" -pass pass:"$keypass" 2>/dev/null; then
                    echo "Wrong password or corrupted key file!"
                    rm -f "$tmpfile"
                    continue
                fi
                source "$tmpfile"
                rm -f "$tmpfile"

                echo "Enter file to decrypt:"
                read infile
                echo "Overwrite $infile? (y/n)"
                read overwrite

                if [[ "$overwrite" == "y" ]]; then
                    tmpout=$(mktemp)
                    if openssl enc -d -aes-256-cbc -in "$infile" -out "$tmpout" -K "$KEY" -iv "$IV"; then
                        mv "$tmpout" "$infile"
                        echo "File decrypted safely in-place -> $infile"
                    else
                        echo "Decryption failed! Original file kept."
                        rm -f "$tmpout"
                    fi
                else
                    echo "Enter output file name:"
                    read outfile
                    openssl enc -d -aes-256-cbc -in "$infile" -out "$outfile" -K "$KEY" -iv "$IV"
                    echo "File decrypted -> $outfile"
                fi
                ;;
            2) return ;;
            *) echo "Invalid option. Try again." ;;
        esac
        echo
    done
}


Key_Menu() {
    while true; do
        echo "---- KEY MENU ----"
        echo "1) Generate New Key"
        echo "2) Back"
        echo -n "Enter choice [1-2]: "
        read subchoice
        case $subchoice in
            1) KeyGenerator ;;
            2) return ;;
            *) echo "Invalid option. Try again." ;;
        esac
        echo
    done
}

KeyGenerator() {
    echo "Generating a 256-bit key..."
    output=$(openssl enc -aes-256-cbc -k secret -P -md sha256)

    KEY=$(echo "$output" | grep key= | cut -d= -f2)
    IV=$(echo "$output"  | grep iv  | cut -d= -f2)
    SALT=$(echo "$output" | grep salt | cut -d= -f2)

    echo "KEY: $KEY"
    echo "IV:  $IV"
    echo "SALT: $SALT"

    echo "Would you like to save key to file? [y/n]"
    read savechoice
    case $savechoice in 
        y) key_to_file ;;
        n) return ;;
    esac
}

key_to_file() {
    echo "Please name the key file:"
    read filename

    # Ask user to create password
    while true; do
        echo "Create a password to protect the key file:"
        read -s keypass1
        echo "Confirm password:"
        read -s keypass2

        if [[ "$keypass1" == "$keypass2" && -n "$keypass1" ]]; then
            keypass="$keypass1"
            break
        else
            echo "Passwords do not match or empty. Try again."
        fi
    done

    # Save raw KEY/IV/SALT into a temp file
    tmpfile=$(mktemp)
    echo "KEY=$KEY"    > "$tmpfile"
    echo "IV=$IV"     >> "$tmpfile"
    echo "SALT=$SALT" >> "$tmpfile"

    # Encrypt the key file with user’s password
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$tmpfile" -out "$filename" -pass pass:"$keypass"

    rm -f "$tmpfile"
    echo "Encrypted key file saved -> $filename"
}

# Start program
main_menu
