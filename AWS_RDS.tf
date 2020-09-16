provider "kubernetes" {
  config_context_cluster = "minikube"
}

//----------------------------------------------------------------------------
provider "aws" {
  region     = "ap-south-1"
  profile = "Divyansh"
}
//----------------------------------------------------------------------------

variable "name" {
  type = string
  default = "divwordpressdb"
}
variable "username" {
  type = string
  default = "divwordpressdb"
}
variable "password" {
  type = string
  default = "mysqldb12345"
}

//----------------------------------------------------------------------------

resource "aws_db_instance" "mydb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.30"
  instance_class       = "db.t2.micro"
  name                 = var.name
  username             = var.username
  password             = var.password
  port                 = 3306
  parameter_group_name = "default.mysql5.7"
  publicly_accessible = true
  skip_final_snapshot = true
}
//----------------------------------------------------------------------------
  resource "kubernetes_deployment" "wordpresspod" {
  metadata {
    name = "wordpresspod"
    labels = {
      App = "wordpresspod"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "wordpresspod"
      }
    }
    template {
      metadata {
        labels = {
          App = "wordpresspod"
        }
      }
      spec {
        container {
          image = "wordpress"
          name  = "wordpresspod"
         env{
            name = "WORDPRESS_DB_HOST"
            value = aws_db_instance.mydb.address
          }
          env{
            name = "WORDPRESS_DB_USER"
            value = var.username
          }
          env{
            name = "WORDPRESS_DB_PASSWORD"
            value = var.password
          }
          env{
          name = "WORDPRESS_DB_NAME"
          value = var.name
          }
         
          port {
            container_port = 80
          }

          }
        }
      }
    }
  }
//----------------------------------------------------------------------------

resource "kubernetes_service" "wordpressservice" {
  metadata {
    name = "wordpressservice"
  }
  spec {
    selector = {
      App = kubernetes_deployment.wordpresspod.spec.0.template.0.metadata[0].labels.App
    }
    port {
      node_port   = 31880
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}

//----------------------------------------------------------------------------
output "instance_ip_addr" {
  value = aws_db_instance.mydb.endpoint
}

