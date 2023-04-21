# PARLAMINT ES-GA
This repository contains all the tools developed for processing the corpus of Galician parliamentary proceedings compiled for the ParlaMint project. 
## Requirements 
- python 3.8

## Processing text files
All source txt files must be stored inside the `TXT` folder. 
In order to process them, first we need to install all the 
required libraries with pip 
```
pip3 install -r requirements.txt
```
Now we can call the following script to parse our .txt files into .xml
```
python3 main.py
```
The output of this script is saved into two separate folders:
#### TEI_XML_TXT
.xml version of all source txt files 
#### TEI_XML_ROOT
metadata information including list of parties and speakers

## NER and validation
please see the readme inside [POS_UDEPS_NER](https://github.com/ILG-USC/ParlaMint-ES-GA/tree/main/POS_UDEPS_NER)
