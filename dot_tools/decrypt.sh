#!/bin/bash

decrypt() {
    from_filename=$1
    to_filename=$2

    echo "Decrypting $from_filename to $to_filename"

    #openssl enc -aes-256-cbc -d -in $from_filename -out $to_filename
    /usr/local/opt/openssl@1.1 enc -aes-256-cbc -d -in $from_filename -out $to_filename
}
