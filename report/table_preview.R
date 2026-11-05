# Prints a CSV or TSV file written by the authors' code as a Markdown table,
# for the report: the first 30 rows, with a note when there are more. Every
# cell is shown as the text in the file, unconverted ("007" stays "007").
# Base R only, since it runs with the authors' R version, however old.
# Usage: Rscript table_preview.R path/to/file.csv

path     <- commandArgs(trailingOnly = TRUE)[1]
max_rows <- 30

# Encoding ####
# UTF-8 (with or without a byte-order mark), or Latin-1 when the file is
# not valid UTF-8, as older Windows and Spanish files often are; the report
# says so.
lines <- tryCatch(readLines(path, warn = FALSE), error = function(e) character(0))
latin1 <- exists("validUTF8") && length(lines) > 0 && !all(validUTF8(lines))
encoding <- if (latin1) "latin1" else "UTF-8-BOM"
first <- if (length(lines)) lines[1] else ""
if (latin1) first <- iconv(first, "latin1", "UTF-8")

# Separator ####
# Tab for .tsv; for .csv, a comma, or a semicolon when the first line has
# more semicolons than commas (write.csv2, common in Spanish and other
# European locales).
count <- function(ch, x) lengths(regmatches(x, gregexpr(ch, x, fixed = TRUE)))
sep <- if (grepl("[.]tsv$", path, ignore.case = TRUE)) {
  "\t"
} else if (length(first) && count(";", first) > count(",", first)) {
  ";"
} else {
  ","
}

# Reading ####
# Read without a header, so that every row is kept as it is in the file,
# and as text. The widest row sets the number of columns; shorter rows are
# padded with empty cells.
fail <- function() {
  cat("*This file could not be read as a table; it is in the artifact.*\n")
  quit(save = "no")
}
fields <- tryCatch(count.fields(file(path, encoding = encoding), sep = sep, quote = "\"",
                                comment.char = "", blank.lines.skip = TRUE),
                   error = function(e) NULL)
fields <- fields[!is.na(fields)]
if (!length(fields)) fail()
width <- max(fields)
d <- tryCatch(read.table(path, sep = sep, header = FALSE, quote = "\"", comment.char = "",
                         fill = TRUE, colClasses = "character", na.strings = character(0),
                         col.names = paste0("V", seq_len(width)), strip.white = FALSE,
                         blank.lines.skip = TRUE, fileEncoding = encoding),
              error = function(e) NULL)
if (is.null(d) || nrow(d) == 0) fail()

# The first row is the header. When it has one cell fewer than every row
# below, the file has row names (write.table's default), and the header
# is shifted right by one empty cell.
header <- unlist(d[1, ], use.names = FALSE)
if (length(fields) > 1 && fields[1] == width - 1 && all(fields[-1] == width)) {
  header <- c("", header[seq_len(width - 1)])
}
body <- d[-1, , drop = FALSE]

# Markdown table ####
# Line breaks inside a cell become spaces, and every character Markdown
# would act on (emphasis, code, HTML, maths, links, the pipe that ends a
# cell) is escaped with a backslash, so that the cell shows its text.
cell <- function(x) {
  x <- gsub("\r?\n", " ", as.character(x))
  gsub("([][\\`*_<>$~^|])", "\\\\\\1", x)
}
header[header == ""] <- " "
shown <- body[seq_len(min(nrow(body), max_rows)), , drop = FALSE]
out <- c(paste0("| ", paste(cell(header), collapse = " | "), " |"),
         paste0("|", paste(rep("---", width), collapse = "|"), "|"))
for (i in seq_len(nrow(shown))) {
  out <- c(out, paste0("| ", paste(cell(unlist(shown[i, ], use.names = FALSE)),
                                   collapse = " | "), " |"))
}
writeLines(out)
if (latin1) {
  cat("\n*This file is not valid UTF-8 and was read as Latin-1.*\n")
}
if (length(unique(fields[-1])) > 1) {
  cat("\n*Rows in this file have different numbers of cells; shorter rows are shown padded.*\n")
}
if (nrow(body) > max_rows) {
  cat("\n*The first", max_rows, "of", nrow(body), "rows; the whole file is in the artifact.*\n")
}
