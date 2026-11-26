# Runner workspace (workspace-runner-admin)
# Kicks off the chain: network -> security -> compute.
#
# DISABLED FOR NOW: without timestamp() nothing changes, so there is no apply
# and network is not triggered. Uncomment the line below to turn it back on.

resource "terraform_data" "trigger" {
  # triggers_replace = timestamp()
}
