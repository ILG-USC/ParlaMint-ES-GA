FROM pytorch/pytorch:1.13.1-cuda11.6-cudnn8-runtime

RUN chmod 1777 /tmp && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y git-core ssh-client build-essential ruby ruby-dev && \
    gem install puma --no-doc && \
    apt-get purge -y build-essential ruby-dev && \
    apt autoremove -y

RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh git clone git@github.com:huggingface/transformers.git

WORKDIR transformers/examples/pytorch/token-classification

RUN pip install -r requirements.txt
RUN pip install git+https://github.com/huggingface/transformers

COPY dataset .
COPY modelo modelo
COPY config.ru config.ru

# Set to any value to print the input and output for each text sent to be tagged.
ENV DEBUG=''

CMD ["puma", "--port", "5001"]
EXPOSE 5001
