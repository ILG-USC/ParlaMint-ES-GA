from reading import fix_toprettyreformat, escape_attrib_html
from xml.dom import minidom
import pandas as pd
import unicodedata
import datetime
import numbers
import re
import os


class metadater:
    """
    class to convert xlsx metadata to xml
    """

    def __init__(self):
        self.datos_partidos = None
        self.datos_interventores = None
        self.relacions_partidos = None
        self.resultados_interventores = {}
        self.resultados_partidos = {}
        self.regex_attributes = re.compile(r"[^0-9]+")
        self.regex_parenthesis_name_only = re.compile(r".*(\(.*?\))")

    def choose_sex(self, data: str) -> str:
        if data == "muller":
            return "F"
        else:
            return "M"

    def adapt_date_YYYY_MM_DD(
        self, original_format: datetime.datetime
    ) -> datetime.datetime:
        return original_format.strftime("%Y-%m-%d")

    def process_affilitation(self, data) -> list:
        affilitations = {}
        for index, row in data.dropna().items():
            index = index.lower()
            if "affiliation" in index:
                attribute_type = index.split("_")[1]
                attribute_index = attribute_type[-1]
                attribute_value = self.regex_attributes.match(attribute_type).group(0)
                if (
                    attribute_value == "an"
                ):  # inconsistent naming of column
                    attribute_value = "ana"
                affiliation_count = index[-1]
                if isinstance(row, datetime.datetime):
                    row = self.adapt_date_YYYY_MM_DD(row)
                if attribute_value == "ana" and row[0] != '#':
                    row = f'#{row}'
                if attribute_index != 'to' or (attribute_index == 'to' and row.lower().strip() != '-'): 
                    if attribute_index in affilitations:
                        affilitations[attribute_index].append({attribute_value: row})
                    else:
                        affilitations[attribute_index] = [{attribute_value: row}]

        return [data for key, data in affilitations.items()]

    def process_idno(self, data) -> list:
        idno_data = []
        for index, row in data.dropna().items():
            if "IDNO" in index:
                subtype_idno = index.split()[0].split("_")[1][:-1]
                if subtype_idno.lower().strip() == 'wiki':
                    subtype_idno = 'wikimedia'
                lang_idno = re.findall("\w+", index.split()[1])
                count_idno = index[-1]
                if 'es' not in lang_idno[0].lower():
                    idno_data.append(
                        {
                            "attributes": [
                                {"type": "URI"},
                                {"xml:lang": f"{lang_idno[0]}"},
                                {"subtype": subtype_idno},
                            ],
                            "inner_text": row,
                        }
                    )
        return idno_data

    def number_to_str(self, v):
        if isinstance(v, datetime.datetime):
            if not pd.isnull(v):
                v = str(v.strftime("%d.%m.%Y"))
            else:
                v = str(v)
        if isinstance(v, (numbers.Number, int, float)):
            v = str(v)
        if not isinstance(v, str) and not isinstance(v, list):
            print(v)
        return v

    def process_dict_to_xml(self, data: dict, new_node: object):
        for k, v in data.items():
            v = self.number_to_str(v)

            if k == "inner_text":
                text = self.document.createTextNode(v)
                new_node.appendChild(text)

            elif k == "attributes":
                # print(k, v)
                for attr in v:
                    for attrk, attrv in attr.items():
                        attrv = self.number_to_str(attrv)
                        new_node.setAttribute(attrk, attrv)
            else:
                if isinstance(v, list):
                    for el in v:
                        el = self.number_to_str(el)
                        inside_tag = self.document.createElement(k)
                        inside_text = self.document.createTextNode(el)
                        inside_tag.appendChild(inside_text)
                        new_node.appendChild(inside_tag)
                else:
                    inside_tag = self.document.createElement(k)
                    inside_text = self.document.createTextNode(v)
                    inside_tag.appendChild(inside_text)
                    new_node.appendChild(inside_tag)
        return

    def data_to_xml(self, data: dict, node: object):
        for tag in data:
            new_node = self.document.createElement(tag)
            if isinstance(data[tag], list):
                for instance in data[tag]:
                    new_node = self.document.createElement(tag)

                    self.process_dict_to_xml(data=instance, new_node=new_node)
                    node.appendChild(new_node.cloneNode(deep=True))

            elif isinstance(data[tag], dict):
                self.process_dict_to_xml(data=data[tag], new_node=new_node)
                node.appendChild(new_node.cloneNode(deep=True))

    def person_data(self):
        """
        <person xml:id="CastroMaríaNava">
            <persName>
                <surname>Castro</surname>
                <surname>Domínguez</surname>
                <forename>María Nava</forename>
            </persName>
            <sex value="F">muller</sex>
            <birth when="1969-03-06">
                <placeName>Ponteareas</placeName>
            </birth>
            <affiliation role="MP" ref="#PG" from="2012-11-16" to="2013-01-22" ana="#PG.9" />
            <affiliation role="member" ref="#party.PPdeG" from="2012-11-16" to="2013-01-22" ana="#PG.9" />
            <affiliation role="MP" ref="#PG" from="2016-10-21" to="2016-11-28" ana="#PG.10" />
            <affiliation role="member" ref="#party.PPdeG" from="2016-10-21" to="2016-11-28" ana="#PG.10" />
            <idno type="URI" xml:lang="gl" subtype="wikimedia">https://gl.wikipedia.org/wiki/Nava_Castro</idno>
        </person>

        persons: [{'persName':{
                                'surname':'Castro Dominguez',
                                'forename':'Maria Nava'
                                },
                    'sex':'muller',
                    'birth': {'when': 'xxxx-xx-xx', 'placeName':'Ponteareas'},
                    'affiliation': [{'role':'MP', 'ref'='#PG', 'from:'xxxx-xx-xx', 'to':'xxxx-xx-xx', 'ana'='#PG.9'},{}],
                    'idno': {'type':'URI', 'xml:lang':'gl', 'subtype'='wikimedia', 'tagged_content':'https://gl.wikipedia.org/wiki/Nava_Castro'}
                }
                ]
        """
        for index, person in self.datos_interventores.iterrows():
            if not pd.isnull(person["Surname1"]):
                    id_xml = f'{person["ID (Surname1Forename)"]}'
                    sex_value = self.choose_sex(person["Sex "])

                    affiliations = self.process_affilitation(person)
                    idno_data = self.process_idno(person)
                    from dateutil import parser
                    if person["Birth_Date"] != person["Birth_Date"]:
                        person["Birth_Date"] = parser.parse('0001-01-01').year
                    else:
                        person["Birth_Date"] = parser.parse(str(person["Birth_Date"])).year

                    if person["Birth_Place "] != person["Birth_Place "]:
                        person["Birth_Place "] = 'unknown'

                    self.resultados_interventores[id_xml] = {
                        "persName": {
                            "surname": [person["Surname1"], person["Surname2"]],
                            "forename": person["Forename"],
                        },
                        "sex": {
                            "attributes": [{"value": sex_value}],
                        },
                        "birth": {
                            "attributes": [{"when": person["Birth_Date"]}],
                            "placeName": person["Birth_Place "],
                        },
                        "affiliation": [
                            {"attributes": affiliation} for affiliation in affiliations
                        ],
                    "idno": [
                        {"attributes": idno["attributes"], "inner_text": idno["inner_text"]}
                        for idno in idno_data
                    ],
                }

    def parties_data(self):
        """
         <org xml:id="party.Levica.1" role="politicalParty">
                  <orgName full="yes" xml:lang="sl">Združena levica</orgName>
                  <orgName full="yes" xml:lang="en">United Left</orgName>
                  <orgName full="init">Levica</orgName>
                  <event from="2014-03-01" to="2017-06-24">
                     <label xml:lang="en">existence</label>
                  </event>
                  <idno type="URI" xml:lang="sl" subtype="wikimedia">https://sl.wikipedia.org/wiki/Levica_(politi%C4%8Dna_stranka)</idno>
                  <idno type="URI" xml:lang="en" subtype="wikimedia">https://en.wikipedia.org/wiki/United_Left_(Slovenia)</idno>
               </org>

        also goverment parties inside org!/

        """
        for index, party in self.datos_partidos.dropna().iterrows():
            id_xml = party["ID"]
            role = party["Role"]
            existance_from, existance_to = (
                party["Date_From (event)"],
                party["Date_To (event)"],
            )
            org_names = self._get_party_orgs(party)
            idno_data = self.process_idno(party)

            if isinstance(existance_to, str):
                event = {"attributes": [{"from": existance_from}]}
            else:
                event = {"attributes": [{"from": existance_from}, {"to": existance_to}]}

            self.resultados_partidos[id_xml] = {
                "orgName": [
                    {"attributes": org["attributes"], "inner_text": org["inner_text"]}
                    for org in org_names
                ],
                "event": event,
                "idno": [
                    {"attributes": idno["attributes"], "inner_text": idno["inner_text"]}
                    for idno in idno_data
                ],
            }
        return

    def _get_party_orgs(self, data: object) -> list:
        org_names = []

        for index, row in data.dropna().items():
            lang = None
            if "orgname" in index.lower():
                full = self.regex_parenthesis_name_only.match(index.split()[1]).group(0)
                lang_idno = re.findall("\w+", index.split()[1])[0]
                if "init" in full or 'abb' in full:
                    org_names.append(
                        {
                            "attributes": [{"full": 'abb'}],
                            "inner_text": row,
                        }
                    )
                else:
                    full = "yes"
                    org_names.append(
                        {
                            "attributes": [{"full": full}, {"lang": lang_idno}],
                            "inner_text": row,
                        }
                    )
        return org_names

    def develope_nodes_metadata(
        self, node_name: str, current_doc: object, xml_id: str = None
    ):
        current_node = current_doc.createElement(node_name)
        if xml_id:
            current_node.setAttribute("xml:id", xml_id)
        return current_node

    def generate_template(self):
        """
        read from templates folder and then append that found
        we will add generated data later
        """
        curr_dir = None
        curr_dir_name = None

        for root, dirs, files in os.walk("templates/"):
            xml_root = root.replace("templates/", "")

            base = os.path.basename(root)
            if not base:
                main_node = minidom.parse(root + os.sep + files[0]).documentElement
                self.document.appendChild(main_node)
                curr_dir = main_node

            elif base != curr_dir_name:
                curr_dir = self.develope_nodes_metadata(
                    current_doc=self.document, node_name=base
                )
                curr_dir_name = base
                main_node.appendChild(curr_dir)
                if not files:
                    main_node = curr_dir

            for f in sorted(files):
                content = minidom.parse(root + os.sep + f)
                if "particDesc" in f:
                    self.particDesc = content.documentElement

                if base:
                    curr_dir.appendChild(content.documentElement)
            """
                si la base esta vacia el contenido es el root del xml
                entonces tenemos que mirar if base vacia then file parse append document
                
            if base != prev_dir:
                print('new base')   
                if not base:
                    base = files[0]
                    curr_dir = minidom.parse(root+os.sep+files[0]).documentElement
                    print(base)
                    self.document.appendChild(curr_dir)
                else:
                    curr_dir = self.develope_nodes_metadata(base) 
                    prev_node.appendChild(curr_dir)

                prev_dir = base
                prev_node = curr_dir

            for file in files:
                #print(F"root{root} base {os.path.basename(root)}, {files}")
                content = minidom.parse(root+os.sep+file)
                if 'profileDesc' in file:
                    self.particDesc = content.documentElement
                prev_node.appendChild(content.documentElement)
            """

    def write_doc(self, name: str, current_doc: object):
        # modify to write list person and org to separate files
        with open(name, "w+", encoding='utf-8') as xml_file:
            dom_string = fix_toprettyreformat(escape_attrib_html(current_doc))
            document = unicodedata.normalize("NFC", dom_string)
            xml_file.write(document)

    def xlsx_to_df(
        self,
        path: str,
        relevant_sheets: list = [
            "DATOS INTERVENTORES",
            "DATOS PARTIDOS",
            "RELACIÓNS PARTIDOS",
        ],
    ):
        """
        load multiple sheet xlsx into dict to work with
        1/ read multiple sheet xls
        2/ find relevant fields
        """
        import time

        self.document = minidom.Document()

        self.datos_partidos = pd.read_excel(path, sheet_name="DATOS PARTIDOS")
        self.datos_interventores = pd.read_excel(path, sheet_name="DATOS INTERVENTORES")
        self.relacions_partidos = pd.read_excel(path, sheet_name="RELACIÓNS PARTIDOS")
        self.interventores_especiais = pd.read_excel(path, sheet_name="INTERVENTORES")[
            "Interventores"
        ]

        self.parties_data()
        self.person_data()
        """
        list_org = self.document.createElement("listOrg")
        list_person = self.document.createElement("listPerson")

        self.particDesc.appendChild(list_org)
        self.particDesc.appendChild(list_person)
        """
        list_org = minidom.Document()
        list_person = minidom.Document()
        
        root_org = list_org.createElement("listOrg")
        root_org.setAttribute("xmlns", "http://www.tei-c.org/ns/1.0")
        root_org.setAttribute("xml:id", "ParlaMint-ES-GAlistOrg")
        root_org.setAttribute("xml:lang", "gl")

        root_person = list_org.createElement("listPerson")
        root_person.setAttribute("xmlns", "http://www.tei-c.org/ns/1.0")
        root_person.setAttribute("xml:id", "ParlaMint-ES-GA-listPerson")
        root_person.setAttribute("xml:lang", "gl")

        list_org.appendChild(root_org)
        list_person.appendChild(root_person)
        # interventores
        for k in self.resultados_interventores:
            current_node = list_person.createElement("person")
            current_node.setAttribute("xml:id", k.replace(" ", ""))
            root_person.appendChild(current_node)
            self.data_to_xml(data=self.resultados_interventores[k], node=current_node)

        self.write_doc(
            name="TEI_XML_ROOT/ParlaMint-ES-GA-listPerson.xml", current_doc=list_person
        )
        # partidos
        for p in self.resultados_partidos:
            current_node = self.develope_nodes_metadata(
                node_name="org", xml_id=p, current_doc=list_org
            )
            root_org.appendChild(current_node)
            self.data_to_xml(data=self.resultados_partidos[p], node=current_node)
        self.write_doc(
            name="TEI_XML_ROOT/ParlaMint-ES-GAlistOrg-automatic.xml", current_doc=list_org
        )


        """
        with open("metadata.xml", "w+") as xml_file:
            # self.document.writexml(xml_file)
            dom_string = self.document.toprettyxml()
            dom_string = os.linesep.join(
                [s for s in dom_string.splitlines() if s.strip()]
            )
            xml_file.write(dom_string)
        """

        return self.resultados_interventores


if __name__ == "__main__":
    parser = metadater()

    parser.xlsx_to_df(path="META_PARLAMENTARIO.xlsx")
