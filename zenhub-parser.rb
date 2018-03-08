require 'unirest'
require 'csv'

# Two Step Zenhub Issue Parser:

# First, uncomment and assign the following variables:
# zenhub_access_token = <FOR ACCESS TOKEN GO TO https://app.zenhub.com/dashboard/tokens AND GENERATE NEW TOKEN>
# github_access_token = <FOR ACCESS TOKEN GO TO https://github.com/settings/tokens AND CREATE NEW PERSONAL ACCESS TOKEN>

# Last, run "ruby zenhub-parser.rb" in the terminal and zenhub_results.csv should be ready to upload to an excel doc.

response = Unirest.get("https://api.zenhub.io/p1/repositories/65375203/board?access_token=#{zenhub_access_token}").body["pipelines"]

compiled_issues = []

p "Compiling Issues..."

response.each do |response_pipeline|
  response_pipeline["issues"].each do |pipeline_issue|
    issue = pipeline_issue
    if pipeline_issue["estimate"]
      issue["estimate"] = pipeline_issue["estimate"]["value"]
    end
    issue["pipeline"] = response_pipeline["name"]
    compiled_issues << issue 
  end
end

compiled_issues.each do |issue|
  p "Pulling additional information for Issue #{issue["issue_number"]}"
  response = Unirest.get("https://api.github.com/repos/nomo-fomo/nomofomo/issues/#{issue["issue_number"]}?access_token=#{github_access_token}").body
  issue["title"] = response["title"]
  issue["state"] = response["state"]
  issue["locked"] = response["locked"]
  issue["comments"] = response["comments"]
  issue["created_at"] = response["created_at"]
  issue["updated_at"] = response["updated_at"]
  issue["body"] = response["body"]
  issue["closed_at"] = response["closed_at"]
  if response["labels"]
    labels = []
    response["labels"].each do |label|
      labels << label["name"]
    end
    issue["labels"] = labels.join(", ")
  end
  if response["assignees"]
    assignees = []
    response["assignees"].each do |assignee|
      assignees << assignee["login"]
    end
    issue["assignees"] = assignees.join(", ")
  end
end

p "Writing csv file..."

CSV.open("zenhub_results.csv", "w") do |csv|
  csv << ["Issue Number", "Title", "Pipeline", "Position", "Labels", "Assignees", "Is Epic", "Estimate", "State", "Locked", "Comments", "Created At", "Updated At", "Closed At", "Body"]
  compiled_issues.each do |issue|
    csv << [issue["issue_number"], issue["title"], issue["pipeline"], issue["position"], issue["labels"], issue["assignees"], issue["is_epic"], issue["estimate"], issue["state"], issue["locked"], issue["comments"], issue["created_at"], issue["updated_at"], issue["closed_at"], issue["body"]]
  end
end

p "Done! Now upload zenhub_results.csv to an excel spreadsheet."
