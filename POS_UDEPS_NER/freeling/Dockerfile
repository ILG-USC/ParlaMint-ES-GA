FROM ruby:2.7.3-slim-buster

ENV FREELINGSHARE=/usr/share/freeling
ENV FREELING_LANGUAGE=gl
ENV FREELING_PORT=5000
ENV SERVER_PORT=5001
# Set to any value to print the input and output for each text sent to be tagged.
ENV DEBUG=''

RUN apt-get update
ENV LANG=en_US.UTF-8
RUN apt-get install -y locales && \
    sed -i -e "s/# $LANG.*/$LANG UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG
RUN apt-get install -y libboost-regex1.67.0 \
                       libboost-chrono1.67.0 \
                       libboost-date-time1.67.0 \
                       libboost-system1.67.0 \
                       libboost-program-options1.67.0 \
                       libboost-thread1.67.0 \
                       libboost-filesystem1.67.0 \
                       libboost-iostreams1.67.0 \
                       libicu63 \
                       zlib1g
RUN apt-get install -y wget && \
    wget --no-verbose https://github.com/TALP-UPC/FreeLing/releases/download/4.2/freeling-4.2-buster-amd64.deb && \
    wget --no-verbose https://github.com/TALP-UPC/FreeLing/releases/download/4.2/freeling-langs-4.2.deb && \
    dpkg -i freeling-4.2-buster-amd64.deb && \
    dpkg -i freeling-langs-4.2.deb && \
    rm freeling-4.2-buster-amd64.deb && \
    rm freeling-langs-4.2.deb && \
    #   Uncomment to remove unwanted languages data to save space && \
    rm -rf /usr/share/freeling/as && \
    rm -rf /usr/share/freeling/ca && \
    rm -rf /usr/share/freeling/cs && \
    rm -rf /usr/share/freeling/cy && \
    rm -rf /usr/share/freeling/de && \
    rm -rf /usr/share/freeling/en && \
    rm -rf /usr/share/freeling/es && \
    rm -rf /usr/share/freeling/es/es-ar && \
    rm -rf /usr/share/freeling/es/es-cl && \
    rm -rf /usr/share/freeling/es/es-old && \
    rm -rf /usr/share/freeling/fr && \
    # rm -rf /usr/share/freeling/gl && \
    rm -rf /usr/share/freeling/hr && \
    rm -rf /usr/share/freeling/it && \
    rm -rf /usr/share/freeling/nb && \
    rm -rf /usr/share/freeling/pt && \
    rm -rf /usr/share/freeling/ru && \
    rm -rf /usr/share/freeling/sl && \
    apt-get purge -y wget
RUN locale-gen en_US.UTF-8

RUN apt-get install -y build-essential && \
    gem install puma --no-doc && \
    apt-get purge -y build-essential && \
    apt autoremove -y

COPY config /usr/share/freeling/config
COPY gl /usr/share/freeling/gl

COPY config.ru config.ru
COPY start.sh start.sh
# Default command is freeling server. To execute the client use the following command (after running the server):
# docker run --rm -i --network=host freeling analyzer_client localhost:$FREELING_PORT
CMD ["/bin/sh", "-c", ". /start.sh"]
EXPOSE $SERVER_PORT
