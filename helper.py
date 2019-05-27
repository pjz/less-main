

def print_github_user_repos(galaxydatafilename):
    import json
    d = json.load(open(galaxydatafilename))
    for i in d:
        print(i["github_user"]+"/"+i["github_repo"])

