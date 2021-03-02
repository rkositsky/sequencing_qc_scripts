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
              type = "character", help = "path to output tab-separated value (TSV) table"),
  make_option(c("-p", "--output_plot"), dest = "output_plot", 
              type = "character", help = "path to output PNG graphing % reads with 1 mismatch (PNG)"))

opt_parser <- OptionParser(option_list = options_list)
opt <- parse_args(opt_parser)

print(opt)

input_file = opt[["input_file"]]
flowcell_id = opt[["flowcell_id"]]
output_file = opt[["output_file"]]
output_plot = opt[["output_plot"]]

#### Graph the mismatch rate ####

df = read_csv(input_file)

df$Prop_Mismatch = df$`# One Mismatch Index Reads`/df$`# Reads`
df$Should_Redemux = (df$Prop_Mismatch > 0.10)

png(output_plot, width=6, height = 3, res=300, unit = "in")
df2 <- df %>% filter(Index != "Undetermined")
p <- ggplot(data = df2, 
            aes(x = as.numeric(row.names(df2)), y = Prop_Mismatch, color = Should_Redemux)) + 
  #geom_hline(yintercept = 0.10, linetype = "dashed", alpha = 0.5) +
  geom_point() +
  scale_y_continuous(labels = scales::percent_format()) +
  #scale_x_discrete(labels = c()) +
  labs(title = sprintf("%s: %% reads that have 1 mismatch per sequencing ID+lane", flowcell_id),
       y = "Percent of reads which have one mismatch",
       x = "Sequencing ID index") +
  theme(text = element_text(size = 8))
print(p)
dev.off()

write_tsv(df, file = output_file)
print(sprintf("Wrote output to %s", output_file))
  
  