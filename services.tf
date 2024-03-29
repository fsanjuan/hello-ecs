data "template_file" "jenkins_task_template" {
  template = "${file("templates/jenkins.json.tpl")}"
}

resource "aws_ecs_task_definition" "jenkins" {
  family = "jenkins"
  container_definitions = "${data.template_file.jenkins_task_template.rendered}"

  volume {
    name = "jenkins-home"
    host_path = "/ecs/jenkins-home"
  }
}

resource "aws_ecs_service" "jenkins" {
  name = "jenkins"
  cluster = "${module.ecs_cluster.cluster_id}"
  task_definition = "${aws_ecs_task_definition.jenkins.arn}"
  desired_count = "${var.desired_service_count}"
#   depends_on = ["aws_autoscaling_group.asg_jenkins"]
}