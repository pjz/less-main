
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
	@cat $< | jq .results | jq -s add > $@

github_urls.txt: galaxy.json
	@cat $< | jq -r '.[] | "\(.github_user)/\(.github_repo)"' | sort -u >$@

.PHONY: repo_info
repo_info: github_urls.txt
	@mkdir -p repo_info ;\
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


stats/%_files:
	@mkdir -p stats
	@grep -c -E '$*/[^/]+$$' repo_info/* >$@

stats/%_main_files:
	@mkdir -p stats
	@grep -c -E '$*/main[^/]+$$' repo_info/* >$@

%.dat: %
	@cut -d: -f2 $* > $@

%.sum: %.dat
	@rm -f $@ ; touch $@ ;\
	for i in 0 `seq 9` ; do \
		(grep -c -E "^$$i$$" $< || echo 0) >> $@ ;\
	done

graph_%.svg: stats/%_files.sum stats/%_main_files.sum
	@./eplot -g -o $@ -m stats/$**.sum

graphs: graph_tasks.svg graph_vars.svg graph_defaults.svg graph_meta.svg graph_handlers.svg

stats: stats/tasks_files.sum stats/tasks_main_files.sum 
stats: stats/vars_files.sum stats/vars_main_files.sum 
stats: stats/defaults_files.sum stats/defaults_main_files.sum 
stats: stats/meta_files.sum stats/meta_main_files.sum 
stats: stats/handlers_files.sum stats/handlers_main_files.sum 


summary_%: stats/%_main_files stats/%_files
	@echo "Projects with exactly 1 $*/main.* file:\t"`grep -c :1$$ stats/$*_main_files`
	@echo "     Projects with exactly 1 $*/* file:\t"`grep -c :1$$ stats/$*_files`

summary: summary_tasks summary_vars summary_defaults summary_meta summary_handlers



clean:
	rm -rf galaxy.json helper.pyc github_urls.txt __pycache__ stats

veryclean:
	rm -f galaxy_raw.json repo_info
