# Reproducibility check

A GitHub template for checking, before peer review, that the code and data deposited with a manuscript reproduce the results it reports. It runs the
authors' code unchanged in the computing environment of the date the materials
were deposited, and produces a report that a checker compares with the article.

## How a check runs

1. **Materials.** The authors' code and data go into `manuscript/` exactly as
   deposited. Nothing in that folder is edited: whatever the code needs in
   order to run is a finding for the checklist, not a fix. Optionally, the
   manuscript goes into `paper/` as `manuscript.pdf`, for metacheck's
   comparison; it is converted inside the run and not sent out. Both folders
   hold only a hidden `.gitkeep` in the template, so that nothing of ours is
   mistaken for the authors' files.
2. **Environment.** Three values in `settings.env` describe the manuscript:
   the R version current at the deposit date, the date of the CRAN snapshot to
   install packages from, and the script or scripts to run, in order. The
   workflow itself is not edited.
3. **Run.** The checker starts the check by hand, from the **Actions** tab
   (*Run workflow*). Two checkboxes there add metacheck's inspection of the
   deposited files and its comparison of reported and reproduced tests. The
   run rebuilds the environment in a `rocker/r-ver` container, installs the
   packages the code loads from the dated snapshot, and runs each script in
   its own R session, in the order listed, so that scripts pass results to
   one another only through the files they write.
4. **Report.** The workflow renders `report/report.qmd` into an HTML report
   with one section per script. Each section gives the script's exit status,
   the files it wrote (each compared with the file of the same name in the
   deposit), its figures, the tables it saved as CSV or TSV, and its full
   console transcript. The sections are followed by a list of the deposited
   files that no script wrote and by the package versions. The report and every file the
   scripts wrote are attached to the run under *Artifacts*.
5. **Checklist.** The checker opens an issue from the *Reproducibility check*
   template, compares reported and reproduced values, and records a verdict.

## Origin

reprocheck was proposed by Pandelis Perakakis as a reproducibility check
before peer review for [Psicológica](https://psicologicajournal.com). It is
currently being developed with a team formed at BrainHack Donostia 2026 (BCBL,
Donostia-San Sebastián, 3–6 November 2026).

## Related work

The check follows the principles of [CODECHECK](https://codecheck.org.uk):
the checker runs the code but does not fix it, and records what happened.

## Licence

MIT (see `LICENSE`). metacheck, which the optional jobs install and call as a
package, keeps its own AGPL-3.0 licence; no metacheck code is copied here.
