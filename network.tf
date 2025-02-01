# VPC 네트워크 생성
resource "google_compute_network" "vpc_network" {
	name	= "vpc-network"

	depends_on = [
		google_project_service.enable_api
  	]
}

# 서브넷 생성
resource "google_compute_subnetwork" "subnet" {
  	name          = "subnet"
  	ip_cidr_range = "10.0.0.0/24"
  	region        = var.region
  	network       = google_compute_network.vpc_network.name
}


# VPC에 사용할 IP 범위 예약
resource "google_compute_global_address" "private_range" {
  	name          = "private-range"
  	purpose       = "VPC_PEERING"
  	address_type  = "INTERNAL"
  	prefix_length = 16 # /16 범위, 알아서 다른 것과 겹치지 않게 생성함, 불가능할 시 에러 발생
  	network       = google_compute_network.vpc_network.id
}

# Private Service Connection 생성
resource "google_service_networking_connection" "private_connection" {
  	network                 = google_compute_network.vpc_network.id
  	service                 = "servicenetworking.googleapis.com"
  	reserved_peering_ranges = [google_compute_global_address.private_range.name]

	deletion_policy			= "ABANDON" // 이 설정을 추가해야 destory 시에 error가 발생하지 않음, vpc peering이 남을 수? 있다고 하는데 정확한 정보 필요

	// 위 설정만으로 에러가 발생할 경우
	/* provisioner "local-exec" {
		command = <<EOT
			gcloud services vpc-peerings update --project=${var.project_id} \
				--service=${google_service_networking_connection.private_connection.service} \
				--network=${google_compute_network.vpc_network.name} \
				--ranges=${google_compute_global_address.private_range.name} \
				--force
		EOT
  	} //*/
}


# ssh 허용
resource "google_compute_firewall" "allow_ssh" {
  	name    = "allow-ssh"
  	network = google_compute_network.vpc_network.name

  	allow {
		protocol = "tcp"
		ports    = ["22"]
  	}

  	source_ranges = ["0.0.0.0/0"] # 모든 ip에서 접속 허용
}

# mySQL 접속 허용
resource "google_compute_firewall" "allow_mysql" {
  	name    = "allow-mysql"
  	network = google_compute_network.vpc_network.name

  	allow {
		protocol = "tcp"
		ports    = ["3306"]
  	}

  	source_ranges = ["10.0.0.0/8"] # 내부 IP 대역만 허용
}
