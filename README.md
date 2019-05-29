
Scripts to extract stats from ansible-galaxy

## Tools
### that you may have to install
  * curl
  * jq
  * gnuplot (used by eplot)
### that you probably already have
  * make, grep, xargs, sort, tar
  * ./eplot is copied here from https://github.com/chriswolfvision/eplot

## Goal
These scripts were written toward prodicing data about how many individual
ansible-role subdirs (eg. tasks/, vars/, handlers/, etc) have only a single file
named 'main.{yml,yaml,json}' in them.

Hypothesis: Lots, maybe most of them have only the single `main` file in them,
so creating a mechanism to allow, for instance, `vars/main.yml` to replaced by 
a file `vars.yml` would be beneficial.

