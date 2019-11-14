# Prototype of parser / annotator using FAPROTAX



## Create database 

This will parse the FAPROTAX.txt file and create a database (FAPROTAX.db) by default. 
```
perl faproparse.pl 
```

## Classify a taxonomy

Example:
```
perl fapro_class.pl "Bacteria;Proteobacteria;Alphaproteobacteria;Rhizobiales;Methylobacteriaceae;Methylobacterium;" | grep '=='
```

Output:
```
== methanol_oxidation
== methanotrophy
== ureolysis
```

## Classify the output of LOTUS

```
perl fapro_lotus.pl -i Lotus_Output
```

This command will load the taxonomy (hiera_RDP.txt or hiera_BLAST.txt) and the OTU table (OTU.txt) from the LOTUS output 
directory and will create a new directory (default 'function' inside the Lotus output diretory, but can be chaged with `-o`)
containing:

 - OTU_functions.txt <==
```
#OTU    Classes Taxonomy
OTU_13  fermentation;   Bacteria;Bacteroidetes;Bacteroidia;Bacteroidales;Bacteroidaceae;Bacteroides;acidifaciens
OTU_16  N/A     Bacteria;Firmicutes;Clostridia;Clostridiales;?;?;?
OTU_17  fermentation;   Bacteria;Firmicutes;Clostridia;Clostridiales;Ruminococcaceae;Ruminococcus;?
...
```
 - otutab.functions.tsv (TSV)
```
Class                           13CD    14CD    15CD    16CD    19HFD   21HFD   22HFD   24xHFD
aerobic_chemoheterotrophy       0       1       0       0       0       1       0       0
fermentation                    340     537     301     724     238     166     461     215
```
