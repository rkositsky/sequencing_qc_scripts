# R script for making a table summarizing the yield
# Rachel Kositsky
# Created: 2021-01-20

library("optparse")
library("tidyverse")

# Make command line options and parse arguments ####
options_list <- list(
  make_option(c("-i", "--input_file"), dest = "input_file",
              type = "character", help = "path to demultiplex report downloaded from db.davelab.org"),
  make_option(c("-f", "--flowcell_id"), dest = "flowcell_id",
              type = "character", help = "Flowcell ID, e.g. 'HNY2YDSXY'"),
  make_option(c("-o", "--output_file"), dest = "output_file", 
              type = "character", help = "path to output tab-separated value (TSV) table"))

opt_parser <- OptionParser(option_list = options_list)
opt <- parse_args(opt_parser)

print(opt)

input_file = opt[["input_file"]]
flowcell_id = opt[["flowcell_id"]]
output_file = opt[["output_file"]]

#### Make the summary table ####

df = read_csv(input_file)

undet = df %>% filter(Index == "Undetermined")
det = df %>% filter(Index != "Undetermined")

out = data.frame(Flowcell = c(flowcell_id))
out$Flowcell = flowcell_id
out$Total_Read_Pairs = sum(df$`# Reads`)
out$Total_Demux_Read_Pairs = sum(det$`# Reads`)

# Have totals per lane
for(i in unique(df$Lane)) {
  out[, sprintf("Lane_%d", i)] = det %>% filter(Lane == i) %>% pull(`# Reads`) %>% sum()
}

# Undetermined total
out$Undetermined = undet %>% pull(`# Reads`) %>% sum()
out$Pct_Undet = out$Undetermined / out$Total_Read_Pairs

write_tsv(out, file = output_file)
print(sprintf("Wrote output to %s", output_file))
  
  