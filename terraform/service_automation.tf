
resource "aws_ssm_document" "stop-pot-services" {
  name          = "stop_pot_services"
  document_type = "Automation"

  content = <<DOC
schemaVersion: '1.2'
parameters:
  EcsClusterName:
    type: String
  EcsServiceName:
    type: String
mainSteps:
  - name: ECS
    action: 'aws:executeAwsApi'
    inputs:
      Service: ecs
      Api: UpdateService
      cluster: '${aws_ecs_cluster.honeypot-cluster}'
      service: '${aws_ecs_service.cowrie-service}'
      desiredCount: 0
  - name: ECS
    action: 'aws:executeAwsApi'
    inputs:
      Service: ecs
      Api: UpdateService
      cluster: '${aws_ecs_cluster.honeypot-cluster}'
      service: '${aws_ecs_service.mysql-honeypotd-service}'
      desiredCount: 0
DOC
}

resource "aws_ssm_document" "start-pot-services" {
  name          = "start_pot_services"
  document_type = "Automation"

  content = <<DOC
schemaVersion: '1.2'
parameters:
  EcsClusterName:
    type: String
  EcsServiceName:
    type: String
mainSteps:
  - name: ECS
    action: 'aws:executeAwsApi'
    inputs:
      Service: ecs
      Api: UpdateService
      cluster: '${aws_ecs_cluster.honeypot-cluster}'
      service: '${aws_ecs_service.cowrie-service}'
      desiredCount: ${var.cowrie-desired_count}
  - name: ECS
    action: 'aws:executeAwsApi'
    inputs:
      Service: ecs
      Api: UpdateService
      cluster: '${aws_ecs_cluster.honeypot-cluster}'
      service: '${aws_ecs_service.mysql-honeypotd-service}'
      desiredCount: ${var.mysql-honeypod-desired_count}
DOC
}

