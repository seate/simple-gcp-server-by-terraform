resource "google_project_service" "enable_api" {
    project 	= var.project_id
    for_each 	= toset(var.enable_apis)
    service 	= each.key

    disable_on_destroy 				= false // true or unset: destory할 때 api가 비활성화됨, false: destory할 때 api가 비활성화되지 않음
    //disable_dependent_services 	= true // true: destory할 때 이 서비스에 depend하고 있는 서비스도 비활성화됨, false or unset: destory할 때 이 서비스에 depend하고 있는 서비스가 활성화 상태면 에러를 발생시킴
}