variable "project_name"           { type = string }
variable "vpc_id"                  { type = string }
variable "public_subnet_ids"       { type = list(string) }
variable "private_web_subnet_ids"  { type = list(string) }
variable "alb_sg_id"               { type = string }
variable "nginx_sg_id"             { type = string }
variable "webserver_sg_id"         { type = string }
variable "acm_cert_arn"            { type = string }
