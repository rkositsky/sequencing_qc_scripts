# Base Image
FROM r-base:3.5.1

# Metadata
LABEL base.image="sequencingqc:v20210308"
LABEL version="1"
LABEL software="SequencingQC"
LABEL software.version="20210308"
LABEL description="A collection of scripts to generate flowcell level QC and figures"
LABEL tags="flowcell qc"

# Maintainer
MAINTAINER DaveLab <lab.dave@gmail.com>

# update the OS related packages
RUN apt-get update -y && \
    apt-get install -y pandoc

# install required dependencies for QCParser
RUN R --vanilla -e 'install.packages(c("tidyr","readr","dplyr","ggplot2","readxl", "scales", "rmarkdown", "knitr", "devtools"), repos="http://cran.us.r-project.org")'

#RUN R --vanilla -e 'devtools::install_github("jgm/pandoc")'

# get the QCParser from GitHub
COPY summarize_flowcell_yield.R /
COPY qc_report.Rmd /
COPY print_flowcell_figs.R /
COPY graph_mismatch_rate.R /

RUN chmod 755 /summarize_flowcell_yield.R /qc_report.Rmd /print_flowcell_figs.R /graph_mismatch_rate.R

CMD ["qc_report.Rmd"]
