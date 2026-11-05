# Finds the packages the authors' code loads, and installs them from the
# CRAN snapshot set in the R profile. Base R only, since it runs with the
# authors' R version, however old.
# Usage: Rscript find_packages.R manuscript
#
# Read: every .R file in the deposit, hidden folders included, and every
# .Rprofile, which R runs before the scripts; renv's own folder and .git are
# left out. In each file, R's parser finds the calls to library(), require(),
# requireNamespace() and loadNamespace(), with the package written plainly
# or in quotes, on one line or several, and every pkg::function() or
# pkg:::function(). A call with character.only = TRUE names a variable, not
# a package, and is skipped. A file R cannot parse is read line by line
# with a simpler pattern instead. Base packages are not installed.

deposit <- commandArgs(trailingOnly = TRUE)[1]

# Files ####
files <- list.files(deposit, pattern = "([.][Rr]|^[.]Rprofile)$", full.names = TRUE,
                    recursive = TRUE, all.files = TRUE)
files <- files[!grepl("/(renv|[.]git)/", files)]

loaders <- c("library", "require", "requireNamespace", "loadNamespace")

# With R's parser ####
from_parser <- function(f) {
  pd <- tryCatch(getParseData(parse(f, keep.source = TRUE)), error = function(e) NULL)
  if (is.null(pd)) return(NULL)
  pd <- pd[pd$terminal, ]
  pd <- pd[order(pd$line1, pd$col1), ]
  found <- pd$text[pd$token == "SYMBOL_PACKAGE"]
  for (k in which(pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% loaders)) {
    if (k + 2 > nrow(pd) || pd$token[k + 1] != "'('") next
    # The tokens of the whole call, up to its closing parenthesis.
    depth <- 0
    end <- k + 1
    for (j in (k + 1):nrow(pd)) {
      if (pd$token[j] == "'('") depth <- depth + 1
      if (pd$token[j] == "')'") depth <- depth - 1
      if (depth == 0) { end <- j; break }
    }
    call_text <- paste(pd$text[(k + 1):end], collapse = "")
    first <- pd[k + 2, ]
    if (first$token == "STR_CONST") {
      found <- c(found, gsub("^[\"']|[\"']$", "", first$text))
    } else if (first$token == "SYMBOL" &&
               !grepl("character.only=(TRUE|T)", call_text)) {
      found <- c(found, first$text)
    }
  }
  found
}

# Line by line, for files R cannot parse ####
from_lines <- function(f) {
  code <- readLines(f, warn = FALSE)
  code <- code[!grepl("^[[:space:]]*#", code)]
  code <- code[!grepl("character[.]only[[:space:]]*=[[:space:]]*(TRUE|T)", code)]
  pattern <- "(library|require|requireNamespace|loadNamespace)[(][[:space:]]*[\"']?[A-Za-z][A-Za-z0-9.]*[\"']?[[:space:]]*[,)]"
  calls <- unlist(regmatches(code, gregexpr(pattern, code)))
  names_used <- gsub("^[^(]*[(][[:space:]]*[\"']?|[\"']?[[:space:]]*[,)]$", "", calls)
  colons <- unlist(regmatches(code, gregexpr("[A-Za-z][A-Za-z0-9.]*:::?", code)))
  c(names_used, sub(":::?$", "", colons))
}

pkgs <- character(0)
for (f in files) {
  found <- from_parser(f)
  if (is.null(found)) {
    cat("Could not parse", f, "- read line by line instead.\n")
    found <- from_lines(f)
  }
  pkgs <- c(pkgs, found)
}
pkgs <- unique(pkgs[grepl("^[A-Za-z][A-Za-z0-9.]*$", pkgs)])
pkgs <- setdiff(pkgs, rownames(installed.packages(priority = "base")))

# Installation ####
cat("Packages found:", pkgs, "\n")
if (length(pkgs) > 0) install.packages(pkgs)
