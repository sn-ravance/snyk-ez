# Snyk-EZ

*A prescriptive example/exercise, using **jq** and **variables**, of how one can quickly set up snyk-api-import utility and begin importing repos from GitHub to Snyk; see the [full repo](https://github.com/snyk-tech-services/snyk-api-import) for more info*

---
***prereqs:*** 

*1) [jq](https://stedolan.github.io/jq/download/) a lightweight and flexible command-line JSON processor*

*2) [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) package manager for the Node JavaScript platform, I'm recommending this as a way to download the snyk-api-importer but there are [other ways](https://github.com/snyk-tech-services/snyk-api-import#installation) if npm is not an option* 

*3) a [GitHub account](https://github.com/login) connected to at least one GH organization with repos in it; log in from this link now if not already logged in*

*4) a [Snyk account](https://app.snyk.io/login?cta=login&loc=nav&page=homepage) with at least one Snyk org in it; log in from this link now if not already logged in*

*5) A working integration from the Snyk org to the GitHub user account*  

---
## Set up

1. Install [snyk-api-import](https://github.com/snyk-tech-services/snyk-api-import#installation) tool
   
   - Easiest way if you have npm --> `npm install snyk-api-import@latest -g`


2. Clone this repo --> `git clone https://github.com/antz-snyk/snyk-ez.git`
   - Navigate into it --> `cd snyk-ez`


3. Get your [GitHub Org name](https://github.com/settings/organizations), put that org name in snyk-orgs.json file
   - Ensure the GitHub user you log in with is connected to a GitHub Organization
   - Create Var --> `export GITHUB_ORG_NAME=<your GH organization name>`
   - Write this Var to snyk-orgs.json file --> `cat <<< $(jq '.orgData[].name=env.GITHUB_ORG_NAME' snyk-orgs.json) > snyk-orgs.json`


4. Make a new [GitHub Auth token](https://github.com/settings/tokens)
   - Again, ensure token is created with a GitHub user connected to a GitHub org
   - Ensure token is created with all of the repo permissions
   - Create Var --> `export GITHUB_TOKEN=<your GitHub token>`


6. Get your [Snyk Org name](https://app.snyk.io/org/importer-org/manage/settings), put that org name in your snyk-orgs.json file
   - Once logged in to Snyk UI, navigate to the desired organization, then to settings (gear icon, upper right)
   - Scroll to Organization ID, copy the ID
   - Create Var --> `export SNYK_ORG_ID=<your Snyk org ID>`
   - Write this Var to the snyk-orgs.json file --> `cat <<< $(jq '.orgData[].orgId=env.SNYK_ORG_ID' snyk-orgs.json) > snyk-orgs.json`
 
  
7. Get your [Snyk Integration ID for GitHub](https://app.snyk.io/org/importer-org/manage/integrations/), put that ID in your snyk-orgs.json file
   - Navigate to [Integration settings page](https://app.snyk.io/org/importer-org/manage/integrations) within your Snyk org
   - Scroll to the GitHub and GitHub Enterprise settings; which was used to integrate?
   - Determine the correct integration option (GH or GH Enterprise), then select *Edit settings* for that integration option
   - Scroll to the bottom of the *Edit settings* page, copy the Integration ID
   - Create Var --> `export SNYK_ORG_INT_ID=<your Snyk org integration ID>`
   - Write this Var to the snyk-orgs.json file, and delete the alternate integration option; do one or the other of the below for this:

       - ...If you are doing regular GitHub integration: 
            ```
            cat <<< $(jq '.orgData[].integrations.github=env.SNYK_ORG_INT_ID' snyk-orgs.json) > snyk-orgs.json
            cat <<< $(jq 'del(.orgData[].integrations ["github-enterprise"])' snyk-orgs.json) > snyk-orgs.json 
            ```
       - ...If you are doing GitHub Enterprise integration:
            ```
            cat <<< $(jq 'del(.orgData[].integrations ["github"])' snyk-orgs.json) > snyk-orgs.json
            cat <<< $(jq '.orgData[].integrations.github-enterprise=env.SNYK_ORG_INT_ID' snyk-orgs.json) > snyk-orgs.json
            ```
       - If doing GitHub Enterprise Server (on-prem), set up one more var: export GHE_SERVER_URL=<https://ghe.custom.com>
     
       
8. Get your [Snyk account token](https://app.snyk.io/account)
   - In your account settings, under Api Token, click to show the key, select and copy the value
   
   - Create Var --> `export SNYK_TOKEN=<Snyk Token>`


9. Create a few more Vars/Commands:
   - To keep track of imported repos, errors, activity --> `mkdir snyk-log && export SNYK_LOG_PATH=snyk-log`
   
   - So the utility can talk to the api --> `export SNYK_API=https://snyk.io/api/v1`
   
   - A temporary patch --> `export SANITIZE_IMPORT_TARGET=true`

---

## Import data

Working directory: `/snyk-ez`

Now that were set up, the first thing we'll do is run a command to import data. This won't import any actual repos yet. Instead it will import data into a file. We'll use the data from that file to import the repos.

It will: 1) query our GitHub org and read all the repos in it, 2) associate each one with our Snyk project, 3) create a new file that combines both 1 and 2 called 'github-import-targets.json' and save it to snyk-log directory, we'll use this to import the repos to Snyk

1. Ok let's build our data file; choose from one of the three below options

   - If importing from regular GitHub org--> `snyk-api-import import:data --source=github --integrationType=github --orgsData=snyk-orgs.json`
   - If importing from GitHub Enterprise Cloud org--> `snyk-api-import import:data --source=github-enterprise --integrationType=github-enterprise --orgsData=snyk-orgs.json`
   - If importing from GitHub Enterprise Server org--> `snyk-api-import import:data --source=github-enterprise --integrationType=github-enterprise --orgsData=snyk-orgs.json --sourceUrl=GHE_SERVER_URL`


2. Review this file --> `jq . snyk-log/github-import-targets.json`
   - Should look something like this:
```json
{
  "targets": [
    {
      "target": {
        "fork": true,
        "name": "java-goof",
        "owner": "antz-snyk1",
        "branch": "main"
      },
      "integrationId": "3813xxxx-16xx-486x-bxx6-b4exxxac158",
      "orgId": "a62xx1ba-671x-xx30-8097-ca1845xxxxx"
    },
    {
      "target": {
        "fork": true,
        "name": "juice-shop",
        "owner": "antz-snyk1",
        "branch": "master"
      },
       "integrationId": "3813xxxx-16xx-486x-bxx6-b4exxxac158",
       "orgId": "a62xx1ba-671x-xx30-8097-ca1845xxxxx"
    }
  ]
}
```

3. Questions to ask: How many repos total in this file --> `cat snyk-log/github-import-targets.json | jq '.targets | length'`? How many projects does that represent? Could the total # of projects [exceed the limit](https://docs.snyk.io/getting-started/introduction-to-snyk-projects/maximum-number-of-projects-in-an-organsation)?


4. If ok with importing this number of repos/projects as is, lets go to the next step


5. More info on [snyk-orgs.json](https://github.com/snyk-tech-services/snyk-api-import/blob/master/docs/import-data.md#importdata)
---
## Import repos to Snyk

Working directory: `/snyk-ez`

1. Use the file you just created to import repos to Snyk:
   - --> `snyk-api-import import --file=snyk-log/github-import-targets.json`

---

## Snyk Log

Working directory: `/snyk-ez`

After the import finishes, you can get information about the import job with your **Snyk Org Id**, **jq**, and the newly generated files in your **snyk-log** directory

1. Check how many projects successfully imported:
   - --> `jq -s length snyk-log/$SNYK_ORG_ID.imported-projects.log`
   
   
2. Check if any projects failed to import and why:
   - --> `jq . snyk-log/$SNYK_ORG_ID.failed-projects.log`
   

4. Review the snyk-logs folder for other log files:
   - --> `ls -la snyk-log`