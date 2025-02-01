# DB 생성
resource "google_sql_database_instance" "mysql" {
	depends_on = [
		google_service_networking_connection.private_connection
	]

  	name             = "mysql-instance"
  	database_version = "MYSQL_8_0"
  	region           = var.region

  	settings {
    	tier                = var.db_spec 
    	availability_type   = "ZONAL" # 단일 가용영역으로 비용 절감
    	ip_configuration {
      		ipv4_enabled    = false         # Public IP 비활성화
      		private_network = google_compute_network.vpc_network.id
    	}
  	}

	deletion_protection 	= false # 주의 필요, '테라폼에 의한' 삭제 방지 기능 해제 -> 일반적인 다른 삭제 방지 기능이 아님
}

# DB 내부의 database 생성 ex) show databases;
resource "google_sql_database" "default_db" {
  	name     = "default_db"
  	instance = google_sql_database_instance.mysql.name
}

# DB의 사용자 생성
resource "google_sql_user" "default_user" {
	instance = google_sql_database_instance.mysql.name
  	name     = var.db_username
  	password = var.db_password
}
