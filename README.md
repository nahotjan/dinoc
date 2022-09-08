# DInOC

DINOC stands for **D**FIR **In**stead **O**f **C**onfigure.  
The purpose of this project is to provide to Forensic analysts a ready to use DFIR environement in either:
  - On premise server (Ubuntu XX.XX)
  - Cloud [Not implemented yet]

The environement contains:
  - Plaso
  - Timesketch
  - Jupyter 
    - Including Notebooks ready to import data, and investigate
    - Including dinoc python lib (https://github.com/nahotjan/dinoclib)

Data ingested follow the ECS standard (in addition of the fields used by plaso to ensure compatibility, and field created by the source).  
Having data ingested in ECS format allows analysts to run searches across multiple sources.  

## Instal

```
```

## Usage exemple

### Import DFIR-Orc archives in timesketch

[DFIR-Orc](https://www.ssi.gouv.fr/actualite/decouvrez-dfir-orc-un-outil-de-collecte-libre-pour-lanalyse-forensique/) is a live forensics collection tool developped by the French agency ANSSI.

You can run the notebook imported in Jupyter to ingest your data.
 
```
```

### Import Kape reports in timeskecth

[Kape](https://www.kroll.com/en/insights/publications/cyber/kroll-artifact-parser-extractor-kape) is a live forensics collection tool developped by Eric Zimmerman and commonly used.  
The main objective is to convert data to Plaso/Timesketch and ECS format.

```
```
