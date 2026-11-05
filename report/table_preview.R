# Prints a CSV or TSV file written by the authors' code as a Markdown table,
# for the report: the first 30 rows, with a note when there are more. Base R
# only, since it runs with the authors' R version, however old.
# Usage: Rscript table_preview.R path/to/file.csv

path     <- commandArgs(trailingOnly = TRUE)[1]
max_rows <- 30

# Reading ####
sep <- if (grepl("[.]tsv$", path, ignore.case = TRUE)) "\t" else ","
d <- tryCatch(read.table(path, sep = sep, header = TRUE, check.names = FALSE,
                         quote = "\"", comment.char = "", fill = TRUE,
                         stringsAsFactors = FALSE),
              error = function(e) NULL)
if (is.null(d) || ncol(d) == 0) {
  cat("*This file could not be read as a table; it is in the artifact.*\n")
  quit(save = "no")
}

# Markdown table ####
# Cells as text, with NA shown and the pipe, which ends a Markdown cell,
# escaped.
cell <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  gsub("|", "\\|", x, fixed = TRUE)
}
header <- names(d)
header[header == ""] <- " "
shown <- d[seq_len(min(nrow(d), max_rows)), , drop = FALSE]
out <- c(paste0("| ", paste(cell(header), collapse = " | "), " |"),
         paste0("|", paste(rep("---", ncol(d)), collapse = "|"), "|"))
for (i in seq_len(nrow(shown))) {
  out <- c(out, paste0("| ", paste(cell(unlist(shown[i, ], use.names = FALSE)),
                                   collapse = " | "), " |"))
}
writeLines(out)
if (nrow(d) > max_rows) {
  cat("\n*The first", max_rows, "of", nrow(d), "rows; the whole file is in the artifact.*\n")
}
