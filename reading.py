"""mwethods to read files from folder"""
from glob import iglob
import os


def read_lines_list(file_path: str, encoding: str = "utf-8") -> list:
    """return list of lines in file"""
    with open(file=file_path, encoding=encoding) as f:
        return [l.strip() for l in f.readlines() if len(l) > 1]


def read_file(file_path: str, encoding: str = "utf-8"):
    """return entire raw text"""
    with open(file=file_path, encoding=encoding) as f:
        text = f.read()
        return text


def read_folder(folder_path: str, mode: str = "lines") -> list:
    to_return = []
    for root, dirs, files in os.walk(folder_path):
        for f in files:
            if f.endswith(".txt"):
                if mode == "raw":
                    to_return.append(
                        [f.replace(".txt", ""), read_file(root + os.sep + f)]
                    )
                elif mode == "lines":
                    to_return.append(
                        [f.replace(".txt", ""), read_lines_list(root + os.sep + f)]
                    )
    return to_return

def escape_attrib_html(text):
    # originally to escape symbols. Not needed so simply toprettyxml
    pretty = text.toprettyxml(indent="\t", encoding="utf-8").decode("utf-8")
    return '\n'.join([s for s in pretty.splitlines() if s.strip()])

def fix_toprettyreformat(text: str) -> str:
    return (
        text.replace("\n\t\t\t\t\t\n", "")
        .replace("\n\t\t\t\t\n\t\t\t\n", "\n")
        .replace("\n\t\t\t\t\t\t\t\n", "\n")
        .replace("\n\t\t\t\t\n", "\n")
        .replace("\n\t\t\n\t", "\n\t")
        .replace("\n\t\t\t\t\n", "\n")
        .replace("\n\t\t\t\n", "\n")
        .replace("\n\t\t\n\n", "\n")
        .replace("\n\t\t\t\n", "\n")
        .replace("\n\t\n", "\n")
        .replace("\n\t", "\n")
    )

def list_all_docs():
    # <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="ParlaMint-ES-GA_DSPG_001_21102016.xml"/>
    for root, dirs, files in os.walk("TEI_XML_TXT/"):
        return files
