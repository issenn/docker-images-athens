variable "TAG" {
  default = "latest"
}

variable "DOCKER_BUILDKIT" {
  default = true
}

variable "BUILDKIT_PROGRESS" {
  default = "auto"
}

variable "PACKAGE_VERSION" {
  default = "0.0.0"
}

variable "PACKAGE_VERSION_PREFIX" {
  default = ""
}

variable "PACKAGE_HEAD" {
  default = false
}

variable "GO111MODULE" {
  default = "on"
}

variable "GOPROXY" {
  default = "https://proxy.golang.org,direct,direct"
}

variable "GOPROXY_CN" {
  default = "https://goproxy.cn,https://proxy.golang.com.cn,https://mirrors.aliyun.com/goproxy/,https://athens.azurefd.net,direct"
}

variable "CGO_ENABLED" {
  default = 0
}

variable "BUILD_FLAGS" {
  default = "-v"
}

group "default" {
  targets = [
    "main",
    "other",
    "darwin",
  ]
}

target "main" {
  dockerfile = "Dockerfile"
  platforms = [
    "linux/386",
    "linux/amd64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64",
    "linux/mips64",
    "linux/mips64le",
    "linux/ppc64le",
    "linux/s390x",
    "linux/riscv64",
  ]
  args = {
    PACKAGE_NAME = "athens"
    PACKAGE_VERSION = "0.11.0"
    PACKAGE_VERSION_PREFIX = "v"
    PACKAGE_URL = "https://github.com/gomods/athens"
    PACKAGE_SOURCE_URL = "https://github.com/gomods/athens/archive/master.tar.gz"
    PACKAGE_HEAD_URL = "https://github.com/gomods/athens.git"
    PACKAGE_HEAD = true
    GO111MODULE = GO111MODULE
    GOPROXY = GOPROXY
    CGO_ENABLED = CGO_ENABLED
    BUILD_FLAGS = BUILD_FLAGS
  }
}

target "darwin" {
  platforms = [
    "darwin/amd64",
    // "darwin/arm",
    "darwin/arm64",
  ]
  inherits = [
    "main"
  ]
}

target "other" {
  platforms = [
    // "linux/arm",
    // "linux/arm64/v8",
    "linux/mips",
    "linux/mipsle",
    "linux/ppc64",
  ]
  inherits = [
    "main"
  ]
}

target "android" {
  platforms = [
    "android/386",
    "android/amd64",
    "android/arm",
    "android/arm64",
  ]
}
