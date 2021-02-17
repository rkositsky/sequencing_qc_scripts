# R script for making flowcell figures

library("optparse")
library("tidyverse")
library("ggpubr")
library("scales")

# Make command line options and parse arguments ####
options_list <- list(
  make_option(c("-i", "--input_file"), dest = "input_file",
              type = "character", help = "path to input QC table downloaded from db.davelab.org"),
  make_option(c("-o", "--output_dir"), dest = "output_dir", 
              type = "character", help = "path to figure output directory"))

opt_parser <- OptionParser(option_list = options_list)
opt <- parse_args(opt_parser)

print(opt)

input_file = opt$input_file
output_dir = opt$output_dir

# Make the output directory
if (!dir.exists(output_dir)) {
  dir.create(output_dir)  
}


#### Read in input ####
# Keep just one analysis per submission ID
df = readxl::read_excel(path = input_file) %>% 
  distinct(submission_id, .keep_all = T)
# Make capture pool a discrete factor variable
df$capture_pool_id = as.factor(df$capture_pool_id)
# Make submission ID a discrete factor variable
df$submission_id = as.factor(df$submission_id)

# Check it's all from one flowcell
if(length(table(df$flowcell)) > 1) {
  print(table(df$flowcell))
  warning("More than one flowcell found in QC table!")
}

#### Print output figures ####
flowcell_title = sprintf("Flowcell %s (n=%d)", 
                         paste(unique(df$flowcell), collapse = ","), 
                         nrow(df))

# Read pairs plot
df_long <- df %>% arrange(demux_input_read_pairs) %>% 
  select(demux_dna_read_pairs, demux_rna_read_pairs, capture_pool_id, submission_id) %>%
  gather("Nucelic_Acid", "Value", -capture_pool_id, -submission_id)

svg(paste0(output_dir, "/read_pairs.svg"), width=6, height = 3)
ggplot(data = df_long,
       aes(x = submission_id, y = Value, fill = Nucelic_Acid)) + 
  geom_col() + scale_y_continuous(labels = comma) +
  scale_x_discrete(labels = c()) +
  labs(subtitle = flowcell_title,
       title = "Read pairs per submission", y = "Read pairs")
dev.off()

# RNA percentage plot
svg(paste0(output_dir, "/rna_percentage.svg"), width=6, height = 3)
ggplot(data = df_long, 
       aes(x = submission_id, y = Value, fill = Nucelic_Acid)) + 
  geom_bar(position = "fill", stat = "identity") +
  scale_y_continuous(labels = scales::percent_format()) +
  scale_x_discrete(labels = c()) +
  labs(subtitle = flowcell_title,
       title = "DNA/RNA breakdown per submission", 
       y = "Percentage of reads")
dev.off()

# PCR duplicates
# add lines at 25%, 50%, 75%
# DNA PCR dups
svg(paste0(output_dir, "/dna_pcr_dups.svg"), width=6, height = 3)
p <- ggplot(data = df,
       aes(x = submission_id, y = dna_pct_pcr_dups/100, fill = capture_pool_id)) + 
  geom_hline(yintercept = 0.25, linetype = "dashed", alpha = 0.5) +
  geom_hline(yintercept = 0.50, linetype = "dashed", alpha = 0.5) +
  geom_col() +
  scale_y_continuous(labels = scales::percent_format()) +
  scale_x_discrete(labels = c()) +
  labs(subtitle = flowcell_title,
       title = "DNA PCR duplicate rate per submission",
       y = "DNA percent PCR duplicates")
if (max(df$dna_pct_pcr_dups, na.rm = T) > 50) {
  p <- p + geom_hline(yintercept = 0.50, linetype = "dashed", alpha = 0.5)
}
if (max(df$dna_pct_pcr_dups, na.rm = T) > 70) {
  p <- p + geom_hline(yintercept = 0.75, linetype = "dashed", alpha = 0.5)
}
print(p)
dev.off()

# RNA PCR duplicates
svg(paste0(output_dir, "/rna_pcr_dups.svg"), width=6, height = 3)
p <- ggplot(data = df, 
            aes(x = submission_id, y = rna_pct_pcr_dups/100, fill = capture_pool_id)) + 
  geom_hline(yintercept = 0.25, linetype = "dashed", alpha = 0.5) +
  geom_hline(yintercept = 0.50, linetype = "dashed", alpha = 0.5) +
  geom_col() +
  scale_y_continuous(labels = scales::percent_format()) +
  scale_x_discrete(labels = c()) +
  labs(subtitle = flowcell_title,
       title = "RNA PCR duplicate rate per submission",
       y = "RNA percent PCR duplicates")
if (max(df$rna_pct_pcr_dups, na.rm = T) > 50) {
  p <- p + geom_hline(yintercept = 0.50, linetype = "dashed", alpha = 0.5)
}
if (max(df$rna_pct_pcr_dups, na.rm = T) > 70) {
  p <- p + geom_hline(yintercept = 0.75, linetype = "dashed", alpha = 0.5)
}
print(p)
dev.off()


# DNA coverage
svg(paste0(output_dir, "/dna_mean_coverage.svg"), width=6, height = 3)
median_cov = median(df$dna_mean_coverage)
p <- ggplot(data = df,
            aes(x = submission_id, y = dna_mean_coverage, fill = panel)) + 
  geom_hline(yintercept = median_cov, alpha = 0.5) +
  geom_col() +
  scale_x_discrete(labels = c()) +
  labs(subtitle = flowcell_title,
       title = sprintf("DNA mean coverage per submission [median %2.0fx]", median_cov),
       y = "DNA mean coverage (x)")
print(p)
dev.off()

# RNA coverage
svg(paste0(output_dir, "/rna_mean_coverage.svg"), width=6, height = 3)
median_cov = median(df$rna_mean_coverage)
p <- ggplot(data = df,
            aes(x = submission_id, y = rna_mean_coverage, fill = panel)) + 
  geom_hline(yintercept = median_cov, alpha = 0.5) +
  geom_col() +
  scale_x_discrete(labels = c()) +
  labs(subtitle = flowcell_title,
       title = sprintf("RNA mean coverage per submission [median %2.0fx]", median_cov),
       y = "RNA mean coverage (x)")
print(p)
dev.off()

# DNA PCR duplicates vs coverage
svg(paste0(output_dir, "/dna_pcr_dups_vs_dna_mean_coverage.svg"), width=6, height = 3)
ggplot(data = df,
       aes(y = dna_pct_pcr_dups, x = dna_mean_coverage, color = panel)) +
  geom_point() +
  labs(subtitle = flowcell_title,
       title = "DNA PCR dups vs. DNA coverage",
       x = "DNA mean coverage (x)", y = "DNA percentage PCR duplicates (%)")
dev.off()

# DNA PCR duplicates vs library input
svg(paste0(output_dir, "/dna_pcr_dups_vs_library_input.svg"), width=6, height = 3)
ggplot(data = df,
       aes(y = dna_pct_pcr_dups, x = library_input_amount, color = panel)) +
  geom_point() +
  labs(subtitle = flowcell_title,
       title = "DNA PCR dups vs. library input",
       x = "Library input (ng)", y = "DNA percentage PCR duplicates (%)")
dev.off()

# DNA mean coverage vs library input
svg(paste0(output_dir, "/dna_mean_coverage_vs_library_input.svg"), width=6, height = 3)
ggplot(data = df,
       aes(y = dna_mean_coverage, x = library_input_amount, color = panel)) +
  geom_point() +
  labs(subtitle = flowcell_title,
       title = "DNA mean coverage vs. library input",
       x = "Library input (ng)", y = "DNA mean coverage (x)")
dev.off()

# DNA mean coverage vs DNA demux reads
svg(paste0(output_dir, "/dna_mean_coverage_vs_dna_reads.svg"), width=6, height = 3)
ggplot(data = df,
       aes(y = dna_mean_coverage, x = demux_dna_read_pairs, color = panel)) +
  geom_point() +
  scale_x_continuous(labels = comma) +
  labs(subtitle = flowcell_title,
       title = "DNA mean coverage vs. DNA reads",
       x = "DNA demux read pairs", y = "DNA mean coverage (x)")
dev.off()

svg(paste0(output_dir, "/dna_mean_coverage.histogram.svg"),
    width=4.5, height = 3)
ggplot(data = df, aes(x = dna_mean_coverage, fill = panel)) + 
  geom_histogram(binwidth = 10) +
  labs(subtitle = flowcell_title,
       title = "dna_mean_coverage")
dev.off()

png(paste0(output_dir, "/library_concentration.histogram.png"),
    width=4.5, height = 3, units = "in", res = 300)
ggplot(data = df, aes(x = library_concentration, fill = panel)) + 
  geom_histogram() +
  labs(subtitle = flowcell_title,
       title = "library_concentration")
dev.off()

png(paste0(output_dir, "/demux_input_read_pairs.histogram.png"),
    width=4.5, height = 3, units = "in", res = 300)
ggplot(data = df, aes(x = demux_input_read_pairs, fill = panel)) + 
  geom_histogram() +
  labs(title = flowcell_title,
       subtitle = "demux_input_read_pairs")
dev.off()

png(paste0(output_dir, "/demux_rna_percent.histogram.png"),
    width=4.5, height = 3, units = "in", res = 300)
ggplot(data = df, aes(x = demux_rna_percent, fill = panel)) + 
  geom_histogram() +
  labs(title = flowcell_title,
       subtitle = "demux_rna_percent")
dev.off()

png(paste0(output_dir, "/dna_pct_on_target.histogram.png"),
    width=4.5, height = 3, units = "in", res = 300)
ggplot(data = df, aes(x = dna_pct_on_target, fill = panel)) + 
  geom_histogram() +
  labs(title = flowcell_title,
       subtitle = "dna_pct_on_target")
dev.off()

#### By pool ####

svg(paste0(output_dir, "/dna_mean_coverage.by_pool.violin.svg"),
    width=4.5, height = 3) 
dna_cov_pool <- ggplot(df, aes(x = capture_pool_id, y = dna_mean_coverage, fill = panel)) +
  geom_violin() +
  scale_y_continuous(labels = scales::comma) +
  labs(title = flowcell_title,
       subtitle = "dna_mean_coverage by capture pool")
print(dna_cov_pool)
dev.off()

svg(paste0(output_dir, "/demux_input_read_pairs.by_pool.violin.svg"),
    width=4.5, height = 3) 
read_pairs_pool <- ggplot(df, aes(x = capture_pool_id, y = demux_input_read_pairs, fill = panel)) +
  geom_violin() +
  scale_y_continuous(labels = scales::comma) +
  labs(title = flowcell_title,
       subtitle = "read pairs by capture pool")
print(read_pairs_pool)
dev.off()

# Multiple in one page
svg(paste0(output_dir, "/by_pool.2plots.svg"))
ggarrange(dna_cov_pool, read_pairs_pool, 
          ncol = 1, nrow = 2)
dev.off()