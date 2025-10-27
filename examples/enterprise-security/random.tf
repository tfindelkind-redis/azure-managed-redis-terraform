# Random suffix for unique App Service name
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}
