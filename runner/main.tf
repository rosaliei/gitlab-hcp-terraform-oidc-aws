# Runner workspace (workspace-runner-admin)
# No real infrastructure. It changes on every run so there is always an apply,
# and a successful apply fires the run trigger: network -> security -> compute.

resource "terraform_data" "trigger" {
  triggers_replace = timestamp()
}
