# IMPORTANT: Terraform can create this connection, but AWS requires a human
# to authorize it via the console (OAuth handshake with GitHub can't be
# scripted). After `terraform apply`, go to:
#   AWS Console -> Developer Tools -> Settings -> Connections
# Find "<project_name>-github", click it, click "Update pending connection",
# and authorize access to your GitHub account/repo. Status must show
# "Available" before the pipeline's Source stage will work.

resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-github"
  provider_type = "GitHub"
}
