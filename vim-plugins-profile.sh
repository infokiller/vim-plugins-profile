#! /bin/bash

# Copyright 2015-2019, Hörmet Yiltiz <hyiltiz@github.com>
# Released under GNU GPL version 3 or later.

set -o errexit -o errtrace -o nounset -o pipefail
# set -x

echo "Generating vim startup profile..."
logfile="vim.log"

if [ -f $logfile ]; then
  # clear the log file first
  rm $logfile
fi
VIM_BIN="${VIM_BIN:-vim}"
echo "Using vim binary: $(realpath "$(command -v "${VIM_BIN}")")"

if [[ $# -eq 0 ]]; then
  "${VIM_BIN}" --startuptime $logfile -c q
else
  "${VIM_BIN}" --startuptime $logfile "$1"
fi

plugDir="${HOME}/submodules/vim_plugins"

echo "Parsing vim startup profile..."
# logfile=hi.log
# cat $logfile
grep "$plugDir" "$logfile" > tmp.log
awk -F':' '{print $1}' tmp.log > tmp1.log
awk -F':' '{print $2}' tmp.log | awk -F':' '{print $2}' tmp.log | sed "s%.*${plugDir}\/%%g"|sed 's/\/.*//g' > tmp2.log
paste -d ',' tmp1.log tmp2.log | tr -s ' ' ',' > profile.csv
rm tmp.log tmp1.log tmp2.log
rm $logfile

# Let's do the R magic!
echo "Crunching data and generating profile plot ..."

# Check if R is available
echo " "
type R > /dev/null 2>&1 || { printf >&2 "Package R is required but it's not installed. \nPlease install R using your package manager, \nor check out cran.r-project.org for instructions. \nAborting.\n"; exit 1; }


# Still here? Great! Let's move on!
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
R --vanilla --quiet --slave --file="$DIR/vim-plugins-profile-plot.R"
#R --vanilla --file="vim-plugins-profile-plot.R"  # or use this for debugging

# we use result.csv, which is saved from R
# delete profile.csv since it is used to feed into R
rm profile.csv


echo " "
echo 'Your plugins startup profile graph is saved '
echo 'as "result.png" under current directory.'
echo " "
echo "=========================================="
echo "Top 10 Plugins That Slows Down Vim Startup"
echo "=========================================="
cat -n result.csv |head -n 10 # change this 10 to see more in this `Top List`
echo "=========================================="

echo "Done!"
echo " "
