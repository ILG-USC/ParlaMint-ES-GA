# ParlaMint processing

## Prerequisites

- ruby 3.1.2, we recommend to install it using [rbenv](https://github.com/rbenv/rbenv).
- docker and docker-compose
- Run `bundle install` to install the ruby dependencies.
- Build the docker images of the dependencies with `bin/build`

## Generate the `.ana.xml` documents

Documents must be in the `documents/source` folder with the right naming convention.

Start the dependencies.

### Using GPU for NER (recommended)

Since Freeling is slow we must start several instances of it. We have found that a good number is half of the number of cores.

```bash
docker-compose -f docker-compose.yml -f docker-compose-gpu.yml up -d --scale freeling=4
```

### Using CPU for NER (very slow)

Start multiple instances of Freeling and NER. It is recommended to use half the number of cores.

```bash
docker-compose up -d --scale freeling=4 --scale ner=4
```

### Process the documents (stage by stage):

```bash
# Divide into sentences and pos tagging with freeling
bundle exec rake -t -m process:match[tagged] &> to_tagged.log

# Add head and upos using UDPipes
bundle exec rake -t -m process:match[udeps] &> to_udeps.log

# Add NER information to each word
# Using GPU one process is enough
# Using CPU -j must be 3 (one less than the number of NER processes)
bundle exec rake -t -m -j 1 process:match[ner] &> to_ner.log

# Generate the final .ana.xml document
bundle exec rake -t -m process:match[output] &> to_output.log

# Copy the meta files to the output folder
bundle exec rake -t process:meta 
```


## Generation of final files and validation

Clone the ParlaMint project and follow the installation instructions to get the required dependencies.
Copy the output documents into the `Data/ParlaMint-ES-GA` folder.

### Conllu generation

Start the conllu generation and validation.

```bash
make conllu-ES-GA
```

### Vertana files generation

Start the conllu generation and validation.

```bash
make vertana-ES-GA
```

### Validation

```bash
make val-schema-ES-GA
```

#### Out of memory error

It is possible that the previous process fails due to insufficient memory.
One strategy is to validate analyzed documents in smaller blocks of documents.
For 32Gb of RAM we should repeat the process several times with ~100 documents each time. 
To do this comment or remove `<xs:include>` elements in `ParlaMint-ES-GA.ana.xml` file leaving only the ones to validate each time.
