from collections import defaultdict


def load_paths_from_file(fn):
    """Load the contents """
    with open(fn) as f:
        lines = f.readlines()
        
    paths = set()
    toplevels = defaultdict(set)

    for line in lines:
        # skip symlinks
        if line.startswith("l"): continue
            
        # "-rw-rw-r-- root/root       436 2019-01-12 10:22 ansible-lufi-master/meta/main.yml"
        words = line.split()
        if len(words) < 6: 
            print("found bad line", line)
            raise IOError

        # "ansible-lufi-master/meta/main.yml"
        fullpath = words[5]

        # "meta/main.yml"
        _, __, p = fullpath.partition('/')

        paths.add(p)

        # "meta", "main.yml"
        toplevel, _, tail = p.partition('/')
        if tail != "" and not tail.endswith("/"):
            toplevels[toplevel].add(tail)
            
    return paths, toplevels


from typing import Tuple, Dict, Set
from dataclasses import dataclass

MAIN_NAMES = set(["main.yml", "main.yaml", "main.json"])

@dataclass
class Project:
    filename: str
    paths: Set[str]
    toplevels: Dict[str, Set[str]]
    
    def __init__(self, filename):
        self.filename = filename
        with open(filename) as f:
            lines = f.readlines()
        
        paths = set()
        toplevels = defaultdict(set)

        for line in lines:
            # skip symlinks
            if line.startswith("l"): continue
            
            # "-rw-rw-r-- root/root       436 2019-01-12 10:22 ansible-lufi-master/meta/main.yml"
            words = line.split()
            if len(words) < 6: 
                print("found bad line", line)
                raise IOError

            # "ansible-lufi-master/meta/main.yml"
            fullpath = words[5]

            # "meta/main.yml"
            _, __, p = fullpath.partition('/')

            paths.add(p)

            # "meta", "main.yml"
            toplevel, _, tail = p.partition('/')
            if tail != "" and not tail.endswith("/"):
                toplevels[toplevel].add(tail)
            
        self.paths = paths
        self.toplevels = toplevels
        
    def count_directory_members(self, dirname, max_count=10) -> (int, int):
        """Return counts of the number of files in a directory, separated into non-main and main."""
        d = self.toplevels
        if dirname not in d: return 0,0
        count = len(d[dirname])
        mains = len(d[dirname].intersection(MAIN_NAMES))
        if mains > 1:
            print(f"Warning: in {self.filename}, the {dirname} entry contains multiple main.yml/yaml/json")
        count -= mains
        return min(max_count, count), mains
    
    MAIN_NAMES = set(["main.yml", "main.yaml", "main.json"])

def count_directory_members(d, name, diagnostic_path=""):
    if name not in d: return 0,0
    count = len(d[name])
    mains = len(d[name].intersection(MAIN_NAMES))
    if mains > 1:
        print(f"Warning: in {diagnostic_path}, the {name} entry contains multiple main.yml/yaml/json")
    count -= mains
    return min(count, 10), mains
