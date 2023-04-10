from concurrent.futures import process
import re
import os
import pandas as pd
from copy import deepcopy
from xml.dom import minidom
from reading import (
    read_lines_list,
    read_folder,
    escape_attrib_html,
    fix_toprettyreformat,
)
from metadata import metadater
import datetime
from interface import (
    levenshtein_distance,
    select_choice,
    save_error_file,
    Logging_format,
)
import traceback
import regex
import logging
import unicodedata
from reading import list_all_docs

os.makedirs(os.path.dirname("./logs/"), exist_ok=True, mode=0o777)

logging.basicConfig(
    filename="./logs/processing.log", format="%(asctime)s %(message)s", filemode="w+"
)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

l_handler = logging.StreamHandler()
l_handler.setFormatter(Logging_format())
l_handler.setLevel(logging.INFO)
logger.addHandler(l_handler)


def unmark_comment(text: str) -> str:
    text = text.replace("<marked>", "")
    text = text.replace("</marked>", "")
    return text


def intToRoman(num):
    # Storing roman values of digits from 0-9
    # when placed at different places
    m = ["", "M", "MM", "MMM"]
    c = ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM "]
    x = ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"]
    i = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]

    # Converting to roman
    thousands = m[num // 1000]
    hundreds = c[(num % 1000) // 100]
    tens = x[(num % 100) // 10]
    ones = i[num % 10]

    ans = thousands + hundreds + tens + ones

    return ans


class parser_datos(metadater):
    """
    process a parlamentary text to find speakers and their speech
    """

    def __init__(self) -> None:
        # CASOS
        # * O señor / A señora seguido dos apelidos e dous puntos
        #       - O señor SÁNCHEZ GARCÍA: Grazas, señor presidente.
        # * O señor / A señora seguido do cargo e dous puntos
        #       - O señor PRESIDENTE: Bueno, iso xa o entendín, [...]
        # * O señor / A señora seguido do cargo, os apelidos entre paréntese e en minúsculas e dous puntos
        #       - O señor CONSELLEIRO DE ECONOMÍA, EMPREGO E INDUSTRIA (Conde López): Grazas, señor presidente.
        # - O presidente tamén pode aperecer como "O señor / A señora" seguido do cargo, os apelidos entre paréntese e dous puntos,
        # cando o vicepresidente ou outra persoa substitúe ao presidente do Parlamento nesa lexislatura:
        #       - O señor PRESIDENTE (Calvo Pouso): Remate, por favor.
        super(parser_datos, self).__init__()
        self.data = {
            "unknown": []
        }  # table with all the information about each speaker: whole name as key. Inside surnames, title and speech
        self.regex_split_speech = r"(^A señora|^O señor)[^:a-z]+([s]{0,2}\([^:]+\))?:"
        self.regex_split_speaker = re.compile(r"(^A señora|^O señor)")
        # self.regex_temp_chair = re.compile(r"((O señor|A señora) (PRESIDENTE|PRESIDENTA) \(.*\)):")
        self.regex_notes_lines = r"\([^)(]*(?:\([^)(]*(?:\([^)(]*(?:\([^)(]*\)[^)(]*)*\)[^)(]*)*\)[^)(]*)*\)"  # '\(([\r\n]?[^)(]*)?\)'
        self.regex_esclarecimentos = r"\(.* ((\d|\w)º?\)|bis\))"
        self.avoid_notes_breaks = r"((?<!\d)\d|(?<!\w)\w)(\.)?(\º)?(bis)?\)"
        self.regex_only_text = re.compile(r"[A-Za-z-ÑñÁáÉéÍíÓóÚúÜü]+")
        self.regex_parenthesis_name_only = re.compile(r".*(\([^:]+\)?)")
        self.retrieve_whole_comment = r"<marked>[\s\S]*?<marked>"
        self.regex_dates = re.compile(
            r"(DSPG_DP_|DSPG_)(\d{2,3}_)(\d{6,8})(?:_ok| ok)?"
        )
        self.regex_sessions = r"(^[A-ZÁÉÍÓÚÜÑa-záéíóúñ]* a sesión á(s)?.*.)"
        self.current_file_date = None
        self.errors_surname = {
            "rodríguez-vispo": ["vispo"],
            "filgueira": [
                "filgueira figueira",
                "filgueira filgueria",
                "filgueira filgueira",
                "filgueira filqueira",
            ],
            "prado": ["parado"],
            "garcía": ["gacía", "garcia"],
            "méndez": ["mendez"],
            "gonzález": ["gónzález"],
            "balseiro": ["balseio"],
            "vieira": ["viera"],
            "docasar": ["docsar"],
            "fernández": ["ferández"],
            "caselas": ["caelas"],
        }
        self.errors_surname = {}
        self.current_speaker = None
        self.errors_processing = {}
        self.errors_found = []
        self.segment_count = 0
        self.speech_counter = 0
        self.covid_date = datetime.datetime.strptime(f"01.11.2019", "%d.%m.%Y")
        self.session_number = None
        self.len_text = 0
        self.table_chairs = {
            "RojoPilarMilagros": {
                "from": datetime.datetime.strptime(f"01.01.2015", "%d.%m.%Y"),
                "to": datetime.datetime.strptime(f"31.12.2015", "%d.%m.%Y"),
            },
            "SantalicesMiguelÁngel": {
                "from": datetime.datetime.strptime(f"01.01.2016", "%d.%m.%Y"),
                "to": datetime.datetime.strptime(f"31.12.2022", "%d.%m.%Y"),
            },
        }

        self.type_elements = {
            "murmuring": ["murmurio", "palabras que non se perciben", "inintelixible"],
            "laughter": ["risos", "risas"],
            "applause": ["aplauso"],
            "interruption": ["interrupción"],
            "time": [self.regex_sessions]
        }

    def _classify_note(self, note: str) -> str:
        note = note.lower().strip()
        if "aplauso" in note:
            _type = "kinesic"
        elif (
            "murmurio" in note
            or "palabras que non se perciben" in note
            or "inintelixible" in note
            or "risos" in note
            or "risas" in note
        ):
            _type = "vocal"
        else:
            _type = "note"
        return _type

    def _identify_note(self, potential_note: str) -> bool:
        potential_note = unmark_comment(
            potential_note.replace("(", "").replace(")", "")
        )
        if (
            potential_note.isupper()
            or potential_note[:3] == "DOG"
            or (
                potential_note[0].isupper() and potential_note[1].isupper()
            )  # char+whitespace[:1]==True!
        ):
            return False
        elif potential_note[0].islower():
            return False
        elif potential_note[0].isupper():
            return True

    def adapt_role(self, role_meta: str, ref: str):
        """
        ONLY GUEST, CHAIR(PRESIDENT), MEMBER(MP)
        if "president" == role_meta.lower().strip() or "head" in role_meta.lower().strip() and 'pg' in ref.lower().strip():
            role_meta = "chair"
        """
        if "guest" in role_meta.lower():
            role_meta = "guest"
        else:
            role_meta = "regular"
        return role_meta

    def _track_unknown_names(self):
        for error_text in set(self.errors_found):
            with open("errors_txt.txt", "a+", encoding="utf-8") as errorlog:
                if error_text not in errorlog.read():
                    errorlog.write(f"{error_text}\n")

    def _automatic_search_typos(self, word: str, type: str) -> None:
        """
        attempt to find typos in the speaker's name.
        If we find 2 names with a 1 character distance,
        we add them to self.data['uncertain'] for manual review?
        """
        all_surname1 = self.datos_interventores["Surname1"].str.lower()
        all_surname2 = self.datos_interventores["Surname2"].str.lower()
        possible_matches = []

        if type == "president":
            if levenshtein_distance(word, "presidente") <= 2:
                possible_matches = ["presidente"]
            elif levenshtein_distance(word, "presidenta") <= 2:
                possible_matches = ["presidenta"]
        elif type == "surname1":
            possible_matches = [
                surname
                for surname in self.datos_interventores["Surname1"]
                if levenshtein_distance(word, surname) == 1
            ]

        elif type == "surname2":
            possible_matches = [
                surname
                for surname in self.datos_interventores["Surname2"]
                if levenshtein_distance(word, surname) == 1
            ]

        if possible_matches:
            message = f'Expected a valid {type}. Found unknown role or surname "{word}" while processing speaker {self.current_speaker} in file {self.file_name}. Do you want to replace it by one of the following suggestions?'
        else:
            message = f'Expected a valid {type}. Found unknown role or surname "{word}" while processing speaker {self.current_speaker} in file {self.file_name}. No suggestions found. If {word} is an error. Type here the correct surname/role: '

        if message not in self.errors_found:
            self.errors_found.append(message)

        return select_choice(possible_matches, message)

    def _get_date_txt_name(self, file_name: str) -> str:
        print(f"reading {file_name}")
        split_name = file_name.split('-')
        year = split_name[-4][-4:]
        month = split_name[-3]
        day = split_name[-2]
        self.session_number = split_name[-1][-3:] 
        # return {'day':day,'month':month,'year':year}
        date = datetime.datetime.strptime(f"{day}-{month}-{year}", "%d-%m-%Y")
        return date

    def duplicate_nested_parenthesis(self, text: str) -> str:
        esclarecimentos = [
            m.group(0)
            for m in regex.finditer(self.regex_esclarecimentos, text, regex.MULTILINE)
        ]
        # append extra ) to maintain parentheses parity
        for esclarecimento in esclarecimentos:
            text = text.replace(esclarecimento, f"{esclarecimento})")
        return text

    def _ensure_parity_parentheses(self, text: str) -> list:
        text = self.duplicate_nested_parenthesis(text)
        indexes_breaks = [
            [m.group(0), (m.start(), m.end())]
            for m in regex.finditer(self.avoid_notes_breaks, text, regex.MULTILINE)
        ]
        if indexes_breaks:
            if not self.breaks:
                self.breaks = [m[0] for m in indexes_breaks]

            breaker = indexes_breaks[0]
            text = f"{text[:breaker[1][0]-1]}@@@@@@@{text[breaker[1][1]:]}"
            del breaker
            return self._ensure_parity_parentheses(text)
        else:
            return text

    def _format_comments(self, text: str) -> str:
        self.breaks = []
        text = self._ensure_parity_parentheses(text)

        splits = [
            [m.group(0), (m.start(), m.end())]
            for m in regex.finditer(self.regex_notes_lines, text, regex.MULTILINE)
        ]
        text = self._process_comments(text, splits)
        text = self._quickfix_comments(text)
        return text

    def _quickfix_comments(self, text: str) -> str:
        if self.breaks:
            text = text.replace("@@@@@@@", self.breaks[0], 1)
            del self.breaks[0]
            return self._quickfix_comments(text=text)
        else:
            return text

    def _process_comments(self, text: str, splits: list, checked: list = []) -> str:
        splits = [
            [m.group(0), (m.start(), m.end())]
            for m in regex.finditer(self.regex_notes_lines, text, regex.MULTILINE)
            if m.start() == 0
            or text[m.start() - 1] != ">"
            and self._identify_note(m.group(0)) == True
        ]
        splits += [
            [m.group(0), (m.start(), m.end())]
            for m in regex.finditer(self.regex_sessions, text, regex.MULTILINE)
            if m.start() == 0 or text[m.start() - 1] != ">"
        ]
        # splits = sorted(splits, key = lambda x: x[0].count('\n'),reverse=True)
        if len(splits) > 0:
            split = splits[0]
            to_modify = split[0]
            to_modify = to_modify.replace("\n", "")
            text = (
                text[: split[1][0]]
                + f"<marked>{to_modify}<marked>"
                + text[split[1][1] :]
            )
            checked.append(to_modify)
            return self._process_comments(text=text, splits=splits, checked=checked)
        else:
            return text

    def _split_lines_into_speaker_text_pairs(self, whole_text: str) -> list:
        """
        split the entire text from a txt file into
        a list using the o se;or X as rule

        we split the text into paragraphs which are tagged as segments <seg>
        SPLIT INTO SPEECHES
        SPLIT INTO SEGMENTS
        """
        speeches = []

        # find inicio sesion before actual speeches
        matches = list(
            regex.finditer(self.regex_split_speech, whole_text, regex.MULTILINE)
        )

        for m in range(len(matches)):
            start = matches[m].start()
            end = matches[m].end()
            speaker = whole_text[start:end]
            logging.debug(f"o speaker {speaker}")
            if m + 1 < len(matches):
                text = whole_text[end : matches[m + 1].start()]
            else:
                text = whole_text[end:]
            text = self._format_comments(text=text)
            speeches.append([speaker, text])

        #adicionar abrese a sesion bla bla bla antes do primeiro speaker
        split_newlines = whole_text.split("\n")
        for line in split_newlines[:7]:
            if len(line) > 1:
                line_to_check = line
                if re.match(self.regex_sessions, line_to_check):
                    speeches[0][1] = f"<marked>{line}<marked>" + speeches[0][1]
                    break
            
        return speeches

    def _apped_data(self, new_data: list) -> None:
        if new_data[0] not in self.data:
            # print(new_data[0], new_data[1][:10])
            self.data[new_data[0]] = [new_data[1]]
        else:
            self.data[new_data[0]].append(new_data[1])
        return

    def _check_surname_exists(self, surname: str) -> str:
        """
        attempts to correct typos in the name of the speaker
        to match them with the name in the metadata sheet
        by comparing to a manually added list of typos
        """
        for correct_s in self.errors_surname:
            if surname in self.errors_surname[correct_s]:
                # print(surname, correct_s, self.errors_surname[correct_s], len(surname), len(self.errors_surname[correct_s][0]))
                return correct_s

        return surname

    def _get_metadata_by_surname(self, speaker: str, gender: str):
        surname1 = self._check_surname_exists(speaker.split()[0].lower()).strip()
        surname2 = " ".join(speaker.split()[1:]).lower()

        surname2 = " ".join(self.regex_only_text.findall(surname2))
        surname2 = self._check_surname_exists(surname=surname2)

        logging.debug(f"by surname {surname1}=={surname2}=={self.file_name}")

        matches_s1 = self.datos_interventores.index[
            self.datos_interventores["Surname1"] == surname1
        ].to_list()

        logging.debug(f"matches_s1: {matches_s1}")
        if not matches_s1:
            try_fix = self._automatic_search_typos(
                word=surname1.lower(), type="surname1"
            ).lower()
            logging.debug(f"matches1 try_fix {try_fix}")
            matches_s1 = self.datos_interventores.index[
                self.datos_interventores["Surname1"] == try_fix
            ].to_list()
            # print(matches_s1)

        if not any(
            self.datos_interventores["Surname2"][i].lower() == surname2.lower()
            for i in matches_s1
        ):
            surname2 = self._automatic_search_typos(
                word=surname2.lower(), type="surname2"
            ).lower()
            logging.debug(f"matches2 try_fix {surname2}")

        for i in matches_s1:
            if (
                " ".join(
                    self.regex_only_text.findall(
                        self.datos_interventores["Surname2"][i]
                    )
                ).lower()
                == surname2
                or "-".join(
                    self.regex_only_text.findall(
                        self.datos_interventores["Surname2"][i]
                    )
                ).lower()
                == surname2
            ):
                if self.datos_interventores["Sex "][i].strip().lower() == gender:
                    return self.datos_interventores.loc[i].to_dict()

        raise ValueError(f"{surname1}+{surname2} NOT FOUND IN METADATA")

    def _get_speaker_id_role(self, speaker_metadata: dict, i: int = 1):
        """
        check if guest speaker
        else check if affliatiom from is not NaN
        compare affliation_from > file date and affiliatiom to < file date or == '-'
        return speaker id and role according to parlamint format: guest chair regular
        """
        if f"Affiliation_From{i}" in speaker_metadata:
            if speaker_metadata["Affiliation_Role1"].strip().lower() == "guest speaker":
                return speaker_metadata["ID (Surname1Forename)"], self.adapt_role(
                    speaker_metadata[f"Affiliation_Role1"],
                    speaker_metadata["Affiliation_Ref1"],
                )

            if isinstance(speaker_metadata[f"Affiliation_From{i}"], datetime.datetime):
                logging.debug(
                    f' file date: {self.current_file_date} current speaker: {speaker_metadata["ID (Surname1Forename)"]} affiliation from date {speaker_metadata[f"Affiliation_From{i}"]} to {speaker_metadata[f"Affiliation_To{i}"]}'
                )
                logging.debug(
                    self.current_file_date >= speaker_metadata[f"Affiliation_From{i}"]
                )

                # print(speaker_metadata[f"Affiliation_To{i}"], self.current_file_date)
                if self.current_file_date >= speaker_metadata[
                    f"Affiliation_From{i}"
                ] and (
                    speaker_metadata[f"Affiliation_To{i}"] == "-"
                    or speaker_metadata[f"Affiliation_To{i}"]
                    or not speaker_metadata[f"Affiliation_To{i}"]
                    or speaker_metadata[f"Affiliation_To{i}"] >= self.current_file_date
                ):
                    return speaker_metadata["ID (Surname1Forename)"], self.adapt_role(
                        speaker_metadata[f"Affiliation_Role{i}"],
                        speaker_metadata[f"Affiliation_Ref{i}"],
                    )

            elif f"Affiliation_From{i}" in speaker_metadata:
                if self.current_file_date >= speaker_metadata[f"Affiliation_From{i}"]:
                    return speaker_metadata["ID (Surname1Forename)"], self.adapt_role(
                        speaker_metadata[f"Affiliation_Role{i}"],
                        speaker_metadata[f"Affiliation_Ref{i}"],
                    )

            return self._get_speaker_id_role(speaker_metadata=speaker_metadata, i=i + 1)

    def _identify_chair(self):
        """
        use date to identify president of parliament
        """
        for chair, dates in self.table_chairs.items():
            if (
                self.current_file_date > dates["from"]
                and self.current_file_date < dates["to"]
            ):
                return chair, "chair"

    def _find_speaker_metadata(self, speaker: str):
        """
        catch names inside ()
        catch vice/president parliament

        identify o se;or presidente
        identify other presidents by name (paranthesis)
        identify o se;or/a xxxx

        """
        role_chair = False
        gender_speaker = "home"
        if "señora" in speaker.lower():
            gender_speaker = "muller"

        self.current_speaker = speaker

        if self.regex_split_speaker.match(speaker):
            split_speaker = self.regex_split_speaker.split(speaker)[2].lower().strip()
            parenthesis_name = re.search(
                self.regex_parenthesis_name_only, split_speaker
            )

            logging.debug(
                f"split speaker == {split_speaker} | parenthesis_name {parenthesis_name}"
            )

            if parenthesis_name:
                if (
                    "O señor PRESIDENTE (" in speaker
                    or "A señora PRESIDENTA (" in speaker
                ):
                    role_chair = True

                parenthesis_name = parenthesis_name.group(1)
                parenthesis_name = parenthesis_name.replace("(", "").replace(")", "")
                metadata = self._get_metadata_by_surname(
                    speaker=parenthesis_name, gender=gender_speaker
                )

            elif (
                levenshtein_distance(word=split_speaker, target="presidenta") <= 2
                and split_speaker != "presidente"
            ) or (
                levenshtein_distance(word=split_speaker, target="presidente") <= 2
                and split_speaker != "presidenta"
            ):
                split_speaker = "president"
                return self.chair_president
            else:
                metadata = self._get_metadata_by_surname(
                    speaker=split_speaker, gender=gender_speaker
                )

            if metadata:
                logging.debug(f"metadata found {metadata}")
                data = self._get_speaker_id_role(speaker_metadata=metadata)
                if data:
                    speaker_id, role = data[0], data[1]
                    if role_chair:
                        role = "chair"
                else:
                    error = ValueError(
                        f"ROLE/TIMEFRAME FOR {split_speaker} NOT FOUND IN METADATA. FILE {self.file_name}"
                    )
                    logger.error(error)
                    speaker_id, role = f"notFound-{split_speaker}", "unknown"
                # print(speaker_id,role)
                return speaker_id, role

    def _create_segment(self, text: str) -> object:
        self.segment_count += 1
        segment = self.document.createElement("seg")
        segment.setAttribute("xml:id", f"{self.file_name}.seg{self.segment_count}")
        segment_text = self.document.createTextNode(text)
        segment.appendChild(segment_text)
        return segment

    def _create_speech(self, speaker: str) -> object:
        speech = self.document.createElement("u")
        self.speech_counter = self.speech_counter + 1
        who, role = self._find_speaker_metadata(speaker.replace(":", ""))
        speech.setAttribute("who", f"#{who}")
        speech.setAttribute("ana", f"#{role}")
        speech.setAttribute("xml:id", f"{self.file_name}.u{self.speech_counter}")
        return speech

    def _paragraph_to_segments(self, splits: list):
        segments = []
        for split in splits:
            if not split[0]:
                for line in split[1].split("\n\n"):
                    line = line.strip()
                    if line:
                        # print(f"line to segment {line}")
                        segments.append(self._create_segment(line))
            else:  # kinetic, vocal, note

                type = [
                    k
                    for k in self.type_elements
                    if any( re.search(x,split[1].lower()) for x in self.type_elements[k])
                ]
                new_note = self.document.createElement(split[0])
                text_note = self.document.createTextNode(split[1])
                if type:
                    new_note.setAttribute("type", type[0])

                    desc_node = self.document.createElement("desc")
                    # print(split[1])
                    desc_node.appendChild(text_note)
                    new_note.appendChild(desc_node)
                else:
                    new_note.appendChild(text_note)
                segments.append(new_note)
        return segments

    def text_note_to_el(self, type_note: str, text: str) -> object:
        new_note = self.document.createElement(type_note)

        sub_type = [
            k
            for k in self.type_elements
            if any( re.search(x,text.lower()) for x in self.type_elements[k])
        ]

        text_note = self.document.createTextNode(text)
        if sub_type:
            new_note.setAttribute("type", sub_type[0])

        if type_note != "note":
            desc_node = self.document.createElement("desc")
            # print(split[1])
            desc_node.appendChild(text_note)
            new_note.appendChild(desc_node)

        else:
            new_note.appendChild(text_note)
        return new_note

    def _process_paragraph(self, paragraph: str) -> object:
        paragraph = paragraph.strip()
        splits = [
            [m.group(0), (m.start(), m.end())]
            for m in regex.finditer(
                self.retrieve_whole_comment, paragraph, regex.MULTILINE
            )
            if self._identify_note(m.group(0)) == True
        ]
        segmented_text = []
        if splits:
            start_text = 0
            for split in splits:
                new_text = unmark_comment(split[0].strip())
                type_note = self._classify_note(new_text)
                elemented_note = self.text_note_to_el(type_note, new_text)
                for line in unmark_comment(paragraph[start_text : split[1][0]]).split(
                    "\n\n"
                ):
                    line = line.strip()
                    if len(line):
                        # print(line, len(line))
                        new_segment = self._create_segment(line)
                        segmented_text.append(new_segment)

                if split[1][0] == 0 or split[1][1] == len(paragraph):
                    segmented_text.append(elemented_note)
                else:
                    segmented_text[-1].appendChild(elemented_note)
                start_text = split[1][1]

            remaining = unmark_comment(paragraph[start_text:])
            if remaining:
                for line in remaining.split("\n\n"):
                    line = line.strip()
                    if line:
                        segmented_text.append(self._create_segment(line))
            return segmented_text
        else:
            segments = [
                self._create_segment(unmark_comment(line))
                for line in paragraph.split("\n\n")
                if len(line) > 0
            ]
        return segments

    def _find_lexislatura(self) -> dict:
        dates = {
            "PG.9": {
                "from": datetime.datetime.strptime("16.10.2012", "%d.%m.%Y"),
                "to": datetime.datetime.strptime("01.08.2016", "%d.%m.%Y"),
            },
            "PG.10": {
                "from": datetime.datetime.strptime("21.10.2016", "%d.%m.%Y"),
                "to": datetime.datetime.strptime("10.02.2020", "%d.%m.%Y"),
            },
            "PG.11": {
                "from": datetime.datetime.strptime("07.08.2020", "%d.%m.%Y"),
                "to": datetime.datetime.strptime("31.12.9999", "%d.%m.%Y"),
            },
        }
        for k, v in dates.items():
            if (
                v["from"] <= self.current_file_date
                and v["to"] >= self.current_file_date
            ):
                return k
        else:
            raise

    def _add_tei_header(self):
        tei_header = minidom.parse("TEMPLATES/tei_header.xml").documentElement
        meetings_titles = tei_header.getElementsByTagName("meeting")
        meetings_titles += tei_header.getElementsByTagName("title")
        dates = tei_header.getElementsByTagName("date")
        # modify meeting tags inside tei_header to add proper date and session
        """
        DATOS GOB E LEXISL
        """
        lexislatura = self._find_lexislatura()
        self.lexislatura_number = lexislatura.split(".")[-1]

        for meeting_title in meetings_titles:
            if "xxx" in meeting_title.firstChild.nodeValue:
                if "Lexislatura" in meeting_title.firstChild.nodeValue:
                    meeting_title.firstChild.nodeValue = (
                        meeting_title.firstChild.nodeValue.replace(
                            "xxx", f"{intToRoman(int(self.lexislatura_number))}"
                        )
                    )
                meeting_title.firstChild.nodeValue = (
                    meeting_title.firstChild.nodeValue.replace(
                        "xxx", f"{str(self.lexislatura_number).zfill(3)}"
                    )
                )
                if "n" in meeting_title.attributes:
                    meeting_title.attributes["n"] = str(self.lexislatura_number).zfill(3)
                if "ana" in meeting_title.attributes:
                    meeting_title.setAttribute(
                        "ana",
                        meeting_title.attributes["ana"].value.replace(
                            "PG.xx", f"{lexislatura}"
                        ),
                    )

            elif "xx" in meeting_title.firstChild.nodeValue:
                meeting_title.firstChild.nodeValue = (
                    meeting_title.firstChild.nodeValue.replace(
                        "xx", f"{self.session_number}"
                    )
                )
                if "n" in meeting_title.attributes:
                    meeting_title.attributes["n"] = self.session_number

            elif "DD.MM.AAAA" in meeting_title.firstChild.nodeValue:
                meeting_title.firstChild.nodeValue = self.current_file_date.strftime(
                    "%d.%m.%Y"
                )
                meeting_title.attributes["n"] = self.current_file_date.strftime(
                    "%Y-%m-%d"
                )
            if "AAAA-MM-DD" in meeting_title.firstChild.nodeValue:
                meeting_title.firstChild.nodeValue = meeting_title.firstChild.nodeValue.replace(
                    "AAAA-MM-DD",self.current_file_date.strftime(
                    "%d-%m-%Y"
                ))
        # write current date to header
        for date in dates:
            date.firstChild.nodeValue = self.current_file_date.strftime("%d.%m.%Y")
            date.attributes["when"] = self.current_file_date.strftime("%Y-%m-%d")
            logging.debug(
                f"date DD-MM-YYYY {date.firstChild.nodeValue},  DATE FILE {self.current_file_date}"
            )

        # expected publicationdate of all files
        publicationStmt_tag = tei_header.getElementsByTagName("publicationStmt")[0]
        date_pub = publicationStmt_tag.getElementsByTagName("date")[0]
        date_pub.attributes["when"] = "2023-03-01"
        date_pub.firstChild.nodeValue = "01.03.2023"

        #modified date = current date
        change_el = tei_header.getElementsByTagName("change")[0]
        change_el.attributes["when"] = datetime.datetime.now().strftime("%Y-%m-%d")
        return tei_header

    def _format_xml(self, data: list):
        """
        <text ana="#reference" xml:lang="nl">
            <body>
            <div type="debateSection">
                <note>Herdenking W. Kok</note>
                <u who="#AnkieBroekers-Knol"
                ana="#chair"
                xml:id="ParlaMint-NL_2018-10-30-eerstekamer-4.u1">
                <seg xml:id="ParlaMint-NL_2018-10-30-eerstekamer-4.seg1">Aan de orde is de herdenking van de heer Wim Kok.</seg>
            </div>
            </body>
        </text>
        https://github.com/clarin-eric/ParlaMint/blob/main/Data/ParlaMint-NL/ParlaMint-NL_2018-10-30-eerstekamer-4.xml
        div type="debateSection" always debate?

        <u who='metadata name of speaker'
        xml:id="name_file.uxx.x:
            uxx.x ==speech, line

        Inside the text:
        <note> for things inside () in the original txt file

        """
        self.speech_counter = 0  # new doc reset speech count <u>
        self.document = minidom.Document()
        # TEI main tag attributes
        new_TEI = self.document.createElement("TEI")
        new_TEI.setAttribute("xmlns", "http://www.tei-c.org/ns/1.0")
        new_TEI.setAttribute("xml:lang", "gl")
        new_TEI.setAttribute("xml:id", self.file_name)
        if self.current_file_date < self.covid_date:
            new_TEI.setAttribute("ana", f"#parla.sitting #reference")
        else:
            new_TEI.setAttribute("ana", f"#parla.sitting #covid")
        new_TEI.setAttribute("xmlns", "http://www.tei-c.org/ns/1.0")
        tei_header = (
            self._add_tei_header()
        )  # tei_header for file with dates session number etc
        new_TEI.appendChild(tei_header)
        self.document.appendChild(new_TEI)
        new_text = self.document.createElement("text")
        if self.current_file_date < self.covid_date:
            new_text.setAttribute("ana", f"#reference")
        else:
            new_text.setAttribute("ana", f"#covid")
        new_TEI.appendChild(new_text)
        body = self.document.createElement("body")
        new_text.appendChild(body)
        debate_section = self.document.createElement("div")
        # ALL FILES ARE DEBATE SECTIONS?
        body.appendChild(debate_section)
        debate_section.setAttribute("type", "debateSection")
        pb = self.document.createElement("pb")
        pb.setAttribute('source', f'https://www.parlamentodegalicia.gal/sitios/web/BibliotecaDiarioSesions/D{self.lexislatura_number}0{self.session_number}.pdf')
        debate_section.appendChild(pb)
        self.chair_president = self._identify_chair()
        for speaker_text in data:
            speaker = speaker_text[0]
            paragraph = speaker_text[1]
            # print(speaker, paragraphs)

            if len(paragraph) > 1:
                note_speaker = self.document.createElement("note")
                note_speaker.setAttribute("type", "speaker")
                text = self.document.createTextNode(speaker)
                note_speaker.appendChild(text)

                segments = self._process_paragraph(paragraph=paragraph)
                list_speeches = []
                to_split = []

                if segments and segments[0].tagName != "seg":
                    debate_section.appendChild(segments[0])
                    del segments[0]

                current_speech = self._create_speech(speaker)
                for segment in segments[:-1]:
                    current_speech.appendChild(segment.cloneNode(deep=True))

                speaker_note = self.document.createElement("note")
                speaker_note.setAttribute("type", "speaker")
                speaker_info_text = self.document.createTextNode(speaker)
                speaker_note.appendChild(speaker_info_text)
                debate_section.appendChild(speaker_note)
                debate_section.appendChild(current_speech)

                if segments:
                    if segments[-1].tagName != "seg":
                        debate_section.appendChild(segments[-1])
                    else:
                        current_speech.appendChild(segments[-1])
                '''
                notes outside speech and start new speech after note
                for segment in segments:
                    if segment.tagName in ["seg", "vocal", "kinesic"]:
                        to_split.append(segment)
                        #print(segment, segment.tagName)

                    elif segment.tagName == "note":
                        if len(to_split) != 0:
                            list_speeches.append(to_split)
                        list_speeches.append([segment])
                        to_split = []
                if to_split:
                    list_speeches.append(to_split)

                #print(f"list segments {segments}")
                for new_speech in list_speeches:
                    if new_speech[0].tagName != "note":
                        current_speech = self._create_speech(speaker)
                        # print(f"{self.file_name} new speech {new_speech}")
                        for segment in new_speech:
                            current_speech.appendChild(segment.cloneNode(deep=True))
                        debate_section.appendChild(current_speech)
                    else:
                        for note in new_speech:
                            debate_section.appendChild(note.cloneNode(deep=True))

                    """
                    if not isinstance(new_speech, list):
                    else:
                        # print(new_speech[0])
                        text_note = self.document.createTextNode(new_speech[1])
                        new_note = self.document.createElement("note")
                        new_note.appendChild(text_note.cloneNode(deep=True))
                        debate_section.appendChild(new_note)
                    """
                '''

        measures = tei_header.getElementsByTagName("measure")
        for measure in measures:
            unit = measure.attributes["unit"]
            if unit.value == "speeches":
                measure.attributes["quantity"] = str(self.speech_counter)
            elif unit.value == "words":
                measure.attributes["quantity"] = str(self.len_text)

        return fix_toprettyreformat(  # fix tei_header template wrong tab lines loading from file with dif format
            escape_attrib_html(self.document)
        )

    def get_data_xml(self, text: str, file_name: str) -> None:
        """
        returns xml files with parlamint format.
        1 for speaker metadata and a different one
        for the speeches.
        """
        self.file_name = file_name
        self.errors_processing = {}
        self.current_file_date = self._get_date_txt_name(file_name)
        self.len_text = len(text.split())
        split_texts = self._split_lines_into_speaker_text_pairs(whole_text=text)

        self.datos_interventores["Surname1"] = self.datos_interventores[
            "Surname1"
        ].str.strip()
        self.datos_interventores["Surname1"] = self.datos_interventores[
            "Surname1"
        ].str.lower()
        self.datos_interventores["Surname2"] = self.datos_interventores[
            "Surname2"
        ].str.strip()
        self.datos_interventores["Surname2"] = self.datos_interventores[
            "Surname2"
        ].str.lower()
        self.segment_count = 0
        document = self._format_xml(data=split_texts)

        os.umask(0)
        os.makedirs(os.path.dirname("./TEI_XML_TXT/"), exist_ok=True, mode=0o777)

        with open(
            f"./TEI_XML_TXT/{self.file_name}.xml", "w+", encoding="utf-8"
        ) as xml_file:
            document = unicodedata.normalize("NFC", document)
            xml_file.write(document)
        save_error_file(
            file_name=f"ParlaMint-ES-GA_{self.file_name}",
            errors_data=self.errors_processing,
        )


def add_list_files():
    docs = list_all_docs()
    parlamint_ana = minidom.parse("TEMPLATES/ParlaMint-ES-GA.ana.xml")
    parlamint_corpus = minidom.parse("TEMPLATES/ParlaMint-ES-GA.xml")
    for doc in docs:
        # <xi:include xmlns:xi="http://www.w3.org/2001/XInclude"
        #  href="ParlaMint-ES-GA_DSPG_001_21102016.xml"/>
        xi_corpus = parlamint_corpus.createElement("xi:include")
        xi_corpus.setAttribute("xmlns:xi", f"http://www.w3.org/2001/XInclude")
        xi_corpus.setAttribute("href", f"{doc}")
        parlamint_corpus.documentElement.appendChild(xi_corpus)

        xi_ana = parlamint_ana.createElement("xi:include")
        xi_ana.setAttribute("xmlns:xi", f"http://www.w3.org/2001/XInclude")
        xi_ana.setAttribute("href", f"{doc}")
        parlamint_ana.documentElement.appendChild(xi_ana)

    with open(
        f"TEI_XML_ROOT/ParlaMint-ES-GA.ana.xml", "w+", encoding="utf-8"
    ) as xml_file:
        document = unicodedata.normalize("NFC", escape_attrib_html(parlamint_ana))
        xml_file.write(fix_toprettyreformat(document))
    with open(f"TEI_XML_ROOT/ParlaMint-ES-GA.xml", "w+", encoding="utf-8") as xml_file:
        document = unicodedata.normalize("NFC", escape_attrib_html(parlamint_corpus))
        xml_file.write(fix_toprettyreformat(document))


if __name__ == "__main__":
    texts = read_folder(folder_path="./test/")
    parser = parser_datos()
    for text in texts:
        parser.get_data_xml(text=text[1], file_name=text[0])
