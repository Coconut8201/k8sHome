variable "linode_token" {
  description = "Linode API Token"
  sensitive   = true
}

variable "replicas_number" {
  description = "deployment replicas 的數量"
  type        = number
  default     = 2
}

variable "region" {
  description = "linode region"
  type        = string
  default     = "ap-northeast"
}

variable "k8s_version" {
  description = "k8s version"
  type        = string
  default     = "1.35"
}

variable "pool_type" {
  description = "pool type"
  type        = string
  default     = "g6-standard-1" # 練習用最小就好
}

variable "pool_count" {
  description = "pool count"
  type        = number
  default     = 1
}
