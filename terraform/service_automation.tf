
resource "aws_ssm_document" "stop-pot-services" {
  name            = "stop_pot_services"
  document_type   = "Automation"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '0.3'
description: 'Stop Honeypot Services'
mainSteps:
  - name: 'StopCowrieService'
    action: 'aws:executeAwsApi'
    inputs:
      Service: ecs
      Api: UpdateService
      cluster: '${aws_ecs_cluster.honeypot-cluster.name}'
      service: '${aws_ecs_service.cowrie-service.name}'
      desiredCount: 0
  - name: 'StopMysqlService'
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
  name            = "start_pot_services"
  document_type   = "Automation"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '0.3'
description: 'Start Honeypot Services'
mainSteps:
  - name: 'StartCowrieSerivce'
    action: 'aws:executeAwsApi'
    inputs:
      Service: ecs
      Api: UpdateService
      cluster: '${aws_ecs_cluster.honeypot-cluster.name}'
      service: '${aws_ecs_service.cowrie-service.name}'
      desiredCount: ${var.cowrie-desired_count}
  - name: 'StartMysqlSerivce'
    action: 'aws:executeAwsApi'
    inputs:
      Service: ecs
      Api: UpdateService
      cluster: '${aws_ecs_cluster.honeypot-cluster.name}'
      service: '${aws_ecs_service.mysql-honeypotd-service.name}'
      desiredCount: ${var.mysql-honeypod-desired_count}
DOC
}

resource "aws_cloudwatch_event_rule" "stop-pot-service-event" {
  name                = "stop-pot-service-event"
  schedule_expression = "cron(0 16 * * ? *)"
}

# resource "aws_cloudwatch_event_target" "stop-pot-service-event-target" {
#   rule = aws_cloudwatch_event_rule.stop-pot-service-event.name

#   arn      = aws_ssm_document.stop-pot-services.arn
#   role_arn = aws_iam_role.ecs-service-automation-role.arn
# }

resource "aws_cloudwatch_event_rule" "start-pot-service-event" {
  name                = "start-pot-service-event"
  schedule_expression = "cron(5 16 * * ? *)"
}

# resource "aws_cloudwatch_event_target" "start-pot-service-event-target" {
#   rule = aws_cloudwatch_event_rule.start-pot-service-event.name

#   arn      = aws_ssm_document.start-pot-services.arn
#   role_arn = aws_iam_role.ecs-service-automation-role.arn
# }
