resource "aws_appautoscaling_target" "node-hello-world-as-target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.node-hello-world-terraform.name}/${aws_ecs_service.node-hello-world-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "node-hello-world-as-down-policy" {
  name               = "hello-world-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.node-hello-world-as-target.resource_id
  scalable_dimension = aws_appautoscaling_target.node-hello-world-as-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.node-hello-world-as-target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.node-hello-world-as-target]
}

resource "aws_appautoscaling_policy" "node-hello-world-as-up-policy" {
  name               = "hello-world-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.node-hello-world-as-target.resource_id
  scalable_dimension = aws_appautoscaling_target.node-hello-world-as-target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.node-hello-world-as-target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
  depends_on = [aws_appautoscaling_target.node-hello-world-as-target]
}

resource "aws_cloudwatch_metric_alarm" "node-hello-world-cpu-high" {
  alarm_name          = "node-hello-world-cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    ClusterName = aws_ecs_cluster.node-hello-world-terraform.name
    ServiceName = aws_ecs_service.node-hello-world-service.name
  }

  alarm_actions = [aws_appautoscaling_policy.node-hello-world-as-up-policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "node-hello-world-cpu-low" {
  alarm_name          = "node-hello-world-cpu-utilization-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    ClusterName = aws_ecs_cluster.node-hello-world-terraform.name
    ServiceName = aws_ecs_service.node-hello-world-service.name
  }

  alarm_actions = [aws_appautoscaling_policy.node-hello-world-as-down-policy.arn]
}
