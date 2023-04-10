from processing import parser_datos, add_list_files
from reading import read_folder
import sys


if __name__ == "__main__":
    text_parser = parser_datos()
    metadata_dict = text_parser.xlsx_to_df(path="META_PARLAMENTARIO.xlsx")
    texts = read_folder(folder_path="./TXT/", mode="raw")
    for text in texts:
        text_parser.get_data_xml(text=text[1], file_name=text[0])
    text_parser._track_unknown_names()
    add_list_files()
    sys.exit()
