SAS with SASPy

It runs an interactive python shell and wraps the utilities from SASPy to
make it convenient to work with SAS for any kind of SASPy supported SAS
deployments, for example, IOM for local installed SAS on Windows, IOM for
remote workspace server (e.g. SAS OA), and HTTP for SAS Viya.  For more access
method, please refer to the documents of SASPy

To install SASPy in Python:
pip install saspy

Usage:
1. Set `sas-py-cfgname' to the config.
2. Call `run-sas-py'
3. `sas-py-submit-file' or `sas-py-submit-region'
