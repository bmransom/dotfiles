#!/bin/bash

pandoc-pdf() {
  filename=$1
  echo "Exporting $filename to ${filename%%.*}.pdf..."
  pandoc -t latex $filename -o "${filename%%.*}".pdf
}

pandoc-html() {
  filename=$1
  echo "Exporting $filename to ${filename%%.*}.html..."
  pandoc $filename -f markdown -t html -s -o "${filename%%.*}".html
}
