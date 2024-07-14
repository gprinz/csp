output "id_configuration" {
  value       = random_id.id.hex
  description = "Id used for making ressources having unique names."
}