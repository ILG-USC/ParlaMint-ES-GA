FROM perl:5.36-slim

RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential ruby ruby-dev && \
    gem install puma --no-doc && \
    apt-get purge -y build-essential ruby-dev && \
    apt autoremove -y
COPY config.ru config.ru
COPY eagles2UD2.pl .

# Set to any value to print the input and output for each text sent to be tagged.
ENV DEBUG=''

CMD ["puma", "--port", "5001"]
EXPOSE 5001
