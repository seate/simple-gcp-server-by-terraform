resource "tls_private_key" "ssh_key" {
  	algorithm = "RSA"
  	rsa_bits  = 2048
}

resource "local_file" "private_key" {
  	content  = tls_private_key.ssh_key.private_key_pem
  	filename = "${var.ssh_key_dir}/private_key.pem"
	file_permission = "0600"
}

resource "local_file" "public_key" {
  	content  = tls_private_key.ssh_key.public_key_openssh
  	filename = "${var.ssh_key_dir}/public_key.pem"
	file_permission = "0644"
}

# 고정 ip 생성
resource "google_compute_address" "static_ip" {
    name   = "dynamic-static-ip"
    region = var.region
}

# vm instance 생성
resource "google_compute_instance" "my_vm" {
	depends_on = [
	    google_project_service.enable_api
  	]

    name         = "my-vm-name"
    machine_type = var.vm_spec
    zone = var.zone

    boot_disk {
      	initialize_params {
        	image = "ubuntu-os-cloud/ubuntu-2204-lts" # OS 이미지
    	}
  	}

  	network_interface {
    	network = google_compute_network.vpc_network.name

    	access_config {
      		nat_ip = google_compute_address.static_ip.address # 현재는 고정 IP 사용, 아무것도 적혀 있지 않아도 외부 IP 할당됨
    	}
  	}

  	metadata = {
    	ssh-keys = "${var.ssh_user}:${tls_private_key.ssh_key.public_key_openssh}"
  	}

  	# MySQL 클라이언트 설치 스크립트 실행
  	provisioner "remote-exec" {
    	connection {
      		type        = "ssh"
      		user        = var.ssh_user # SSH 사용자명
      		private_key = tls_private_key.ssh_key.private_key_pem
      		host        = self.network_interface[0].access_config[0].nat_ip # 실행할 instance의 host = 현재 VM의 host
    	}

    	inline = [
      		"sudo apt-get update",
      		"if ! command -v mysql >/dev/null 2>&1; then sudo apt-get install -y mysql-client; fi", # MySQL 클라이언트 설치 여부 확인
      		"mysql --version || echo 'MySQL 클라이언트가 설치되지 않았습니다.'" # 설치 여부 확인 메시지
    	]
  	}
}

