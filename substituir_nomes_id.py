from nis import match
import pandas as pd
import datetime
import os
import re
import logging
from interface import Logging_format


regex_only_text = re.compile(r'[^\W\d_]+')
regex_dates = re.compile(r'(DSPG_DP_|DSPG_)(\d{2,3}_)(\d{6,8})(?:_ok| ok)?')
regex_split_speech= r"(^A señora|^O señor)[^:a-z]+([s]{0,2}\([^:]+\))?:" #ou  (^A señora|^O señor)[A-Za-z_ÑñÁáÉéÍíÓóÚú ]+( \([^:]+\))?:

regex_split_speaker= re.compile(r'(^A señora|^O señor)')
regex_president_xunta = re.compile(r'O señor PRESIDENTE DA XUNTA DE GALICIA \(.*\)')
regex_parenthesis_name_only= re.compile(r'.*(\(.*?\))')
errors_surname= { 'rodríguez-vispo': ['vispo'], 'filgueira':['filgueira figueira', 'filgueira filgueria', 'filgueira filgueira', 'filgueira filqueira'], 'prado': ['parado'], 'garcía': ['gacía', 'garcia'], 'méndez': ['mendez'], 'gonzález': ['gónzález'], 'balseiro': ['balseio'], 'vieira': ['viera'],'docasar':['docsar'],'fernández':['ferández'], 'caselas':['caelas']}
datos_interventores = pd.read_excel('META_PARLAMENTARIO.xlsx', sheet_name='DATOS INTERVENTORES', , engine='openpyxl')

datos_interventores['Surname1'] = datos_interventores['Surname1'].str.strip()
datos_interventores['Surname1'] = datos_interventores['Surname1'].str.lower()
datos_interventores['Surname2'] = datos_interventores['Surname2'].str.strip()
datos_interventores['Surname2'] = datos_interventores['Surname2'].str.lower()
current_file_date = None
current_file_name = None

logging.basicConfig(filename="./logs/substituir_nomes_id.log",
                    format='%(asctime)s %(message)s',
                    filemode='w+')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

l_handler = logging.StreamHandler()
l_handler.setFormatter(Logging_format())
logger.addHandler(l_handler)

def quick_fix_pip():
    import subprocess
    import sys
    packages = ['openpyxl']
    for p in packages:
        subprocess.check_call([sys.executable, "-m", "pip", "install", p])

def _check_surname_exists( surname:str)-> str:
    '''
        attempts to correct typos in the name of the speaker
        to match them with the name in the metadata sheet 
        by comparing to a manually added list of typos
    '''
    for correct_s in errors_surname:
        if surname in errors_surname[correct_s]:
            #print(surname, correct_s, errors_surname[correct_s], len(surname), len(errors_surname[correct_s][0]))
            return correct_s

    return surname

def _identify_chair( speaker:str):
    '''
        use date to identify president of parliament
    '''
    for index_row, person in datos_interventores.iterrows():
        for i in range(1,12):
            if isinstance(person[f'Affiliation_From{i}'], datetime.datetime) and (isinstance(person[f'Affiliation_To{i}'], datetime.datetime) or  person[f'Affiliation_To{i}'] == '-'):

                if (person[f'Affiliation_From{i}'] <= current_file_date and ( person[f'Affiliation_To{i}'] == '-' or person[f'Affiliation_To{i}'] >= current_file_date)
                and person [f'Affiliation_Role{i}'] == 'president'):    
                    
                    #print(f"president {person['ID (Surname1Forename)'], adapt_role(person[f'Affiliation_Role{i}'])}")
                    return person['ID (Surname1Forename)'], (person[f'Affiliation_Role{i}'])
                    
def _get_metadata_by_surname( speaker:str, gender:str):
    surname1 = _check_surname_exists(speaker.split()[0].lower()).strip()
    surname2 = ' '.join(speaker.split()[1:]).strip().lower()

    surname2 = ' '.join(regex_only_text.findall(surname2))
    surname2 = _check_surname_exists(surname=surname2)

    matches_s1 = datos_interventores.index[datos_interventores['Surname1']==surname1].to_list()
    for i in matches_s1:
        if  ' '.join(regex_only_text.findall(datos_interventores['Surname2'][i].strip().lower())) == surname2 and datos_interventores['Sex '][i].strip().lower() == gender:
            return datos_interventores.loc[i].to_dict()

    error =ValueError(F'{surname1}+{surname2} NOT FOUND IN METADATA. FILE {current_file_name}')
    logger.error(error)
    
def _find_speaker_metadata(speaker:str):
    gender_speaker = 'home'
    if 'señora' in speaker.lower():
        gender_speaker = 'muller'

    split_speaker = regex_split_speaker.split(speaker)[2].lower().strip()
    parenthesis_name = re.search(regex_parenthesis_name_only, split_speaker)
    if parenthesis_name:
        parenthesis_name =parenthesis_name.group(1)
        parenthesis_name = parenthesis_name.replace('(', '').replace(')', '')
        metadata = _get_metadata_by_surname(speaker=parenthesis_name, gender=gender_speaker)

    elif not regex_president_xunta.match(speaker) and ('pesident' in speaker.lower() or 'president' in speaker.lower()):
        
        return _identify_chair(speaker=speaker)[0]
    else:
        metadata = _get_metadata_by_surname(speaker=split_speaker, gender=gender_speaker)

    if metadata:
        logger.debug(f'metadata {metadata}')
        return metadata['ID (Surname1Forename)']

def find_matches(text:str) -> list:
    '''
        list of all speakers that will be replaced in the text
    '''
    matches = re.finditer(regex_split_speech, text, re.MULTILINE)
    logger.debug(f'matches speakers in text {matches}')
    return [match.group().strip() for match in matches]


def replace_speakertags(text:str)-> str:
    matches_to_replace = find_matches(text)
    for match in matches_to_replace:
        _id = _find_speaker_metadata(speaker=match)
        if not _id:
            text = text.replace(match, f' <notFound>{match}</notFound>')
        else:
            text = text.replace(match, f' <spkrID>{_id}</spkrID>')
    return text

def write_file(file_name:str, data:str) -> None:
    os.makedirs(os.path.dirname('./spkrID_texts/'), exist_ok=True, mode=0o777)
    with open(file=f'./spkrID_texts/{file_name}', mode='w+',encoding='utf-8' ) as new_file:
        new_file.write(data)

def _get_date_txt_name(file_name:str)->str:
    print(f'reading {file_name}')
    raw_date = regex_dates.search(file_name).group(3)
    year = raw_date[-4:]
    month = raw_date[-6:-4]
    day = raw_date[-8:-6]
    #return {'day':day,'month':month,'year':year}
    date = datetime.datetime.strptime(f'{day}.{month}.{year}', '%d.%m.%Y')
    return date 

def read_to_data(path:str) -> dict:
    global current_file_date
    global current_file_name
    for root, dirs, files in os.walk(path):
        for f in files:
            if f.endswith(".txt"):
                file_path = root+os.sep+f
                with open(file=file_path, encoding='utf-8') as file:
                    current_file_name = f
                    current_file_date =_get_date_txt_name(f.replace('.txt', ''))     
                    text = replace_speakertags(file.read())
                    write_file(f, text)

    print('done')
    quit()
if __name__ == '__main__':
    quick_fix_pip()
    read_to_data(input('PATH TXT FOLDER: '))
