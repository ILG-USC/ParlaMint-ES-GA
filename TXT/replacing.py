import os
import regex

to_replace = [ ("`","'"),("´","'"),('<<', '"'), ('>>', '"'),('<', '"'), ('>', '"'), ('“', '"'),  ('”', '"'),('«', '"'),  ('»', '"') ]
#to_replace = [ ('<<', '"'), ('>>', '"'),('<', '"'), ('>', '"'), ('“', '"'),  ('”', '"') ]
regex_kavychki = r'\"([^\"]*)\"'

for root, dirs, files in os.walk('.'):
    for xf in files:
        if xf.endswith(".txt"):
            with open(root + os.sep + xf, 'r', encoding='utf-8') as f:
                text = f.read()
                for to in to_replace:
                    text = text.replace(to[0], to[1])

                """
                find text within quotation marks and replace quotation marks to avoid &quot
                quotations = regex.finditer(regex_kavychki, text, regex.MULTILINE)
                for q in quotations:
                    q = q.group(0)
                    print(f'quotations {q}')
                    modified_q = f'«{q[1:-1]}»'
                    print(f'modified q {modified_q}')
                    text = text.replace(q, modified_q)
                """

            with open(root + os.sep + xf, 'w+', encoding='utf-8') as f:
                f.write(text)
