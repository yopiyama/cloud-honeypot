
resource "aws_ssm_document" "stop-pot-services" {
  name          = "stop_pot_services"
  document_type = "Automation"
  document_format = "YAML"

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
      cluster: '${aws_ecs_cluster.honeypot-cluster.name}'
      service: '${aws_ecs_service.cowrie-service.name}'
      desiredCount: 0
  - name: ECS
    action: 'aws:executeAwsApi'
    inputs:
      Service: ecs
      Api: UpdateService
      cluster: '${aws_ecs_cluster.honeypot-cluster.name}'
      service: '${aws_ecs_service.mysql-honeypotd-service.name}'
      desiredCount: 0
DOC
}

resource "aws_ssm_document" "start-pot-services" {
  name          = "start_pot_services"
  document_type = "Automation"
  document_format = "YAML"

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
      cluster: '${aws_ecs_cluster.honeypot-cluster.name}'
      service: '${aws_ecs_service.cowrie-service.name}'
      desiredCount: ${var.cowrie-desired_count}
  - name: ECS
    action: 'aws:executeAwsApi'
    inputs:
      Service: ecs
      Api: UpdateService
      cluster: '${aws_ecs_cluster.honeypot-cluster.name}'
      service: '${aws_ecs_service.mysql-honeypotd-service.name}'
      desiredCount: ${var.mysql-honeypod-desired_count}
DOC
}

