provider "aws" {
  alias  = "singapore"
  region = "ap-southeast-1"
  profile = "pegb"

}

provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
  profile = "pegb"
}
