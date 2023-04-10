from PyInquirer import style_from_dict, Token, prompt
from pprint import pprint
import os
import numpy as np
import logging

style = style_from_dict(
    {
        Token.Separator: "#cc5454",
        Token.QuestionMark: "#673ab7 bold",
        Token.Selected: "#cc5454",  # default
        Token.Pointer: "#673ab7 bold",
        Token.Instruction: "",  # default
        Token.Answer: "#f44336 bold",
        Token.Question: "",
    }
)


def levenshtein_matrix(word_len: int, target_len: int) -> np.array:
    """
     xxxxxxx
    yccccccc
    yccccccc
    yccccccc
    yccccccc
    """
    matrix = np.zeros((word_len + 1, target_len + 1))
    for t in range(word_len + 1):
        matrix[t][0] = t
    for t in range(target_len + 1):
        matrix[0][t] = t

    return matrix


def calculate_distance_levenshtein(matrix: np.array, word: str, target: str) -> int:

    for y in range(1, matrix.shape[0]):
        for x in range(1, matrix.shape[1]):
            if word[y - 1] == target[x - 1]:
                matrix[y][x] = matrix[y - 1][x - 1]
            else:
                case_1 = matrix[y][x - 1]
                case_2 = matrix[y - 1][x]
                case_3 = matrix[y - 1][x - 1]

                if case_1 <= case_2 and case_1 <= case_3:
                    matrix[y][x] = case_1 + 1
                elif case_2 <= case_1 and case_2 <= case_3:
                    matrix[y][x] = case_2 + 1
                if case_3 <= case_2 and case_3 <= case_1:
                    matrix[y][x] = case_3 + 1
    # print(matrix, word, target)
    return int(matrix[matrix.shape[0] - 1][matrix.shape[1] - 1])


def levenshtein_distance(word: str, target: str):
    matrix = levenshtein_matrix(word_len=len(word), target_len=len(target))
    return calculate_distance_levenshtein(matrix=matrix, word=word, target=target)


def select_choice(choices: list, message: str) -> str:
    if choices:
        data_display = {
            "type": "list",
            "message": message,
            "name": "selection",
            "choices": choices,
            "validate": lambda answer: "You must choose one "
            if answer == "no"
            else True,
        }

        input_user = prompt(data_display, style=style)
        pprint(input_user)
        return input_user["selection"]
    else:
        return input(message)


def save_error_file(file_name: str, errors_data: dict):
    os.makedirs(os.path.dirname("./errors/"), exist_ok=True, mode=0o777)
    if errors_data:
        with open(
            f"./errors/error_{file_name}.txt", encoding="utf-8", mode="w+"
        ) as error_file:
            for speaker, speeches in errors_data.items():
                for speech in speeches:
                    error_file.write(
                        f"{speech['date']} ERROR WITH SPEAKER {speaker}:\n error:{speech['error']}\n text: {speech['speech']}"
                    )


class Logging_format(logging.Formatter):

    grey = "\x1b[38;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    format = (
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s (%(filename)s:%(lineno)d)"
    )

    FORMATS = {
        logging.DEBUG: grey + format + reset,
        logging.INFO: grey + format + reset,
        logging.WARNING: yellow + format + reset,
        logging.ERROR: red + format + reset,
        logging.CRITICAL: bold_red + format + reset,
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)


if __name__ == "__main__":
    levenshtein_distance("abcde", "abcde")
