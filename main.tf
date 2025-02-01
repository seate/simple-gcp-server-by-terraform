provider "google" {
    project = var.project_id
    region  = var.region
}

# 파일에 IP 정보 기록
resource "local_file" "write_ip_info" {
  	filename = "ip_info.txt"

  	content = <<EOT
VM External IP: ${google_compute_instance.my_vm.network_interface[0].access_config[0].nat_ip}
MySQL Private IP: ${google_sql_database_instance.mysql.private_ip_address}
EOT
}