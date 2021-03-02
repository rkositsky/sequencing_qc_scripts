# Sequencing Quality Control Scripts

Quality control scripts for sequencing outputs. Customized to the Dave Lab's framework, but could be generalized with some minor adjustments.

Example script for generating an HTML report:
Rscript -e "rmarkdown::render('qc_report.Rmd',params=list(qc_excel = 'all_qc_report.xlsx'))"
