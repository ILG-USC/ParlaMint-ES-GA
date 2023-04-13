# See: https://github.com/samisalkosuo/udpipe-rest-server-docker
FROM ubuntu

RUN apt-get update
RUN apt-get -y install gcc clang build-essential wget unzip

#get udpipe code
WORKDIR /udpipe
#RUN git clone https://github.com/ufal/udpipe.git
RUN wget -q https://github.com/ufal/udpipe/archive/master.zip
RUN unzip -q master.zip
WORKDIR /udpipe/udpipe-master/src

#make udpipe server
RUN make server

#set your model file name is like: fi_20180811.model
#this model have been trained and it is in training/models directory
ARG MODEL_FILE_NAME
#set model name. UDPipe REST server shows this name
#for example: fi
ARG MODEL_NAME
#model description is something that REST servers shows
ARG MODEL_DESC

WORKDIR /udpipe/udpipe-master/src/rest_server

#add the model
COPY models/${MODEL_FILE_NAME} .

ENV MODEL_FILE_NAME=${MODEL_FILE_NAME}
ENV MODEL_NAME=${MODEL_NAME}
ENV MODEL_DESC=${MODEL_DESC}

EXPOSE 8080
#start udpipe REST server
#using custom model
CMD ["sh", "-c", "./udpipe_server 8080 --max_request_size=1048576 ${MODEL_NAME} ${MODEL_NAME} ./${MODEL_FILE_NAME} ${MODEL_DESC}"]

