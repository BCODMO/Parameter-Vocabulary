# Parameter-Vocabulary

## Docker

The Dockerfile uses the tenforce/virtuoso container to setup an RDF triplestore pre-populated with NERC Parameter vocabularies P01, P02, and the entire semantic model along with the BCO-DMO Datasets, Parameters and Parameter Vocabulary.

### First Use

Starting the docker container for the first time downloads the NERC and BCO-DMO RDF data as RDF/XML into the `data/toLoad` directory. This may take up to 15min as some of the data are large. Once the data are downloaded, they are loaded into the triplestore, and Virtuoso starts up. You will know the container is ready when the docker logs print the following lines:

```
01:34:15 OpenLink Virtuoso Universal Server
01:34:15 Version 07.20.3229-pthreads for Linux as of Aug 21 2019
01:34:15 uses parts of OpenSSL, PCRE, Html Tidy
01:34:15 Database version 3126
01:34:15 SQL Optimizer enabled (max 1000 layouts)
01:34:16 Compiler unit is timed at 0.000111 msec
01:34:18 Roll forward started
01:34:18     3 transactions, 185 bytes replayed (100 %)
01:34:18 Roll forward complete
01:34:19 Checkpoint started
01:34:19 Checkpoint finished, log reused
01:34:19 HTTP/WebDAV server online at 8890
01:34:19 Server online at 1111 (pid 1)
```
Now, the Virtuoso container can be stopped and restarted without having to download (and load) the data. For a glimpse at what data is being downloaded, see the `startup.sh` file. 

When the container is fully loaded, you can begin to inspect the data at: `http://localhost:8890`

### Updating the Data

When the data are first loaded, a two files are written to the `data` directory to tell Virtuoso that the data has been both downloaded and loaded. To download and reload the data, delete the files: `.data_loaded` and `.data_downloaded`. If you prefer to reload the already downloaded data, delete the `.data_loaded` file.

### Data

#### NERC Parameter Vocabularies and Semantic Model
* http://vocab.nerc.ac.uk/collection/P01/current/
* http://vocab.nerc.ac.uk/collection/P02/current/
* http://vocab.nerc.ac.uk/collection/S01/current/
* http://vocab.nerc.ac.uk/collection/S02/current/
* http://vocab.nerc.ac.uk/collection/S03/current/
* http://vocab.nerc.ac.uk/collection/S04/current/
* http://vocab.nerc.ac.uk/collection/S05/current/
* http://vocab.nerc.ac.uk/collection/S06/current/
* http://vocab.nerc.ac.uk/collection/S07/current/
* http://vocab.nerc.ac.uk/collection/S25/current/
* http://vocab.nerc.ac.uk/collection/S26/current/
* http://vocab.nerc.ac.uk/collection/S27/current/
* http://vocab.nerc.ac.uk/collection/S29/current/

#### BCO-DMO Datasets and Parameter Vocabularies
* https://www.bco-dmo.org/rdf/dumps/parameter.rdf
* https://www.bco-dmo.org/rdf/dumps/dataset_parameter.rdf
* https://www.bco-dmo.org/rdf/dumps/dataset.rdf
