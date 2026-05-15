# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region to deploy the S3 webapp"
  type        = string
  default     = "us-east-1"
}

variable "prefix" {
  description = "Prefix for the S3 bucket name (e.g. your org name)"
  type        = string
}

variable "name" {
  description = "Name component of the S3 bucket (e.g. webapp)"
  type        = string
  default     = "webapp"
}
