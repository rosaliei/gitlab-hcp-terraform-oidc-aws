data "tfe_outputs" "network" {
  organization = "kst-cie"
  workspace    = "network"
}

data "tfe_outputs" "security" {
  organization = "kst-cie"
  workspace    = "security"
}
