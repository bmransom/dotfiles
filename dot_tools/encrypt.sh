#!/bin/bash

encrypt() {
    from_filename=$1
    to_filename=$2

    echo "Encrypting $from_filename to $to_filename"

    openssl enc -aes-256-cbc -salt -in $from_filename -out $to_filename
}

