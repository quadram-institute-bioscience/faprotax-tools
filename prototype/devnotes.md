# FAPROTAX PARSER

Specify **functional groups** based on taxon names.
* Each group begins with a group name, followed by a list of taxons affiliated with that group ('member taxons', one member per line).
* Groups are separated by at least one blank or pure-whitespace line.
* Member taxons can be enclosed in quotes.
* Comments are prefixed with `#` and will be ignored. Use comments to provide literature references for functional affiliations.
* Group names should not contain whitespace characters (e.g. tabs).
* Group names may be appended by an optional semicolon-separated list of metadata entries, which is separated by the group name by whitespace
  * These metadata may be included in the generated function tables, but they do not unfluence which OTU/taxon is assigned to which function.
 *  Each metadata entry should be of the format` <key>:<value>`, where `<value>` is a comma-separated list of values (whitespace is ignored)
    * For example, methanogenesis may be appended by "`carbon:yes; anaerobic:yes; elements:C,H`"

**Members**:
* Each member is specified as a list of descending taxonomic levels (typically 2 or 3), separated by an asterisk (*).
  * For example "`*Escherichia*Coli*`" or "`*Proteobacteria*Nitrosomonas*`" or "`*Bacteria*Nitrosomonas*europaea*`"
* The prefixed and suffixed asterisks indicate that there may be higher or lower taxonomic levels that haven't been included in the member name.
* Be as general as possible, but as specific as needed to ensure the validity of the functional affiliations.
  * For example, if all Nitrosomonas but not all Proteobacteria oxidize ammonia, then add `*Proteobacteria*Nitrosomonas*` instead of `*Proteobacteria*`, and instead of just `*Proteobacteria*Nitrosomonas*europaea*`.

•	Taxon names are case-insensitive.
•	Overlaps between groups are allowed.
•	Duplicate entries within a group are allowed (and will be ignored).
•	Prefixed or trailing whitespace is ignored, unless enclosed in quotes.

**Set operations** between functional groups are also supported:
* Adding previously defined groups to a new group (e.g. for group nesting) is done using the prefix 'add_group:'
 * For example, the group 'mammal_pathogens' may include 'add_group:human_pathogens' and 'add_group:cattle_pathogens'
 * Found 79 instances in FAPROTAX 1.2
* Similarly, to subtract previously defined groups from a new group (set difference), use the prefix 'subtract_group:'
 * Found 1 instance in FAPTROTAX 1.2
* To form the intersection of a group with a previously defined group, use the prefix 'intersect_group:'
 * For example, the group 'hydrogenotrophic_methanogens' may be defined by the two operations '`add_group:hydrogenotrophy`' and '`intersect_group:methanogens`'.
 * No instances found!
* The order of set operations matters, because a set operation applies to group definitions until the point of the set operation.
 * For example, the group 'obligate_aerobic' may include `'add_group:aerobic`' and then '`subtract_group:anaerobic`'. Similarly, the group 'obligate_aerobic_and_others' may start with '`add_group:aerobic`', then '`subtract_group:anaerobic`', and then list additional members not affected by the set operations.

	
## Notes

### Intersect_group
Intersect_group: never found in the Database, not implemented at the moment

### Subtract_group
Subtract_group: found only once, and the examples collides with the expected behaviour:  (A – B)
In the database:

```
chloroplasts                    elements:C,O; .. light_dependent:yes
*chloroplast*
```
```
cyanobacteria                   elements:C,O; …; light_dependent:yes
*cyanobacteria*
```
`subtract_group:chloroplasts`

Having this example, I had to keep the "subtracted" on a different structure. But this will probably generate problems in the future as the order of the operation matters.

### Taxonomy entries to understand
Some taxonomy entries are difficult to match (e.g. should ‘`sp.`’ be ignored altogether?):
`*Acidithiomicrobium*sp.*P2*`

Some entries can contain “:”:
`*Escherichia*coli*O157:H7*`

Currently no entry uses quotes.

## Example2: taxonomy parser
Using the provided taxonomy parser I tried to check if my implementation provides coherent results.

Example Input: 
`Proteobacteria;Alphaproteobacteria;Rhizobiales;Methylobacteriaceae;Methylobacterium;`
Faprotax script output:
`methanol_oxidation, methylotrophy`

Perl implementation output:
`methanol_oxidation, methanotrophy, ureolysis`

In the databases, under “**ureolysis**” there is this entry:
          `'*Rhizobiales*Methylobacterium*',`

From microbes wiki for Methylobacterium: 
`Bacteria; Proteobacteria; Alphaproteobacteria; Rhizobiales; Methylobacteriaceae; Methylobacterium
`

