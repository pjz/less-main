
GALAXY=https://galaxy.ansible.com
PAGE_SIZE=1000
PAGE_FETCH_DELAY=60

REPO_FETCH_DELAY=2

all: repo_info

galaxy_raw.json:
	@touch $@
	@url="/api/v1/search/content/?deprecated=false&order_by=-relevance&keywords=&page_size=$(PAGE_SIZE)&page=1" ;\
	while [ "$$url" != "null" ] ; do \
	    echo "Getting $(GALAXY)$$url" ;\
	    url=`curl -s "$(GALAXY)$$url" | tee -a $@ | jq .next_link | xargs echo` ;\
	    echo "pausing before next page..." ;\
	    sleep $(PAGE_FETCH_DELAY) ;\
	done

galaxy.json: galaxy_raw.json
	cat $< | jq .results | jq -s add > $@


github_urls.txt: galaxy.json
	python3 -c 'import helper ; helper.print_github_user_repos("$<")' | sort -u > $@ 

.PHONY: repo_info
repo_info: github_urls.txt
	mkdir -p repo_info ;\
	for repo in `cat $<`; do \
	    outfile=repo_info/`echo $$repo | sed 's/\//_/'` ;\
	    if [ ! -f "$$outfile" ]; then \
	        echo "Getting $$outfile" ;\
	        curl -s -L https://github.com/$$repo/archive/master.tar.gz | tar tzvf - >$$outfile ;\
		echo "pausing before next fetch..." ;\
	        sleep $(REPO_FETCH_DELAY) ;\
	    else \
	        echo "Found existing $$outfile. skipping..." ;\
	    fi ;\
	done

stats: stats_tasks_files stats_tasks_main_files


stats_tasks_files:
	# tasks/* files in each repo
	@mkdir -p stats
	grep -c -E 'tasks/[^/]+$$' repo_info/* >stats/$@

stats_tasks_main_files:
	# tasks/* files in each repo
	@mkdir -p stats
	grep -c -E 'tasks/main[^/]+$$' repo_info/* >stats/$@



clean:
	rm -rf galaxy.json helper.pyc github_urls.txt __pycache__

veryclean:
	rm -f galaxy_raw.json repo_info
