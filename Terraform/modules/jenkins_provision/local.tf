locals {
  ssh_type            = "ssh"
  ssh_user            = "ubuntu"
  ssh_private_key     = file("~/.ssh/id_ed25519")

  scripts_to_execute = [
    "update_upgrade_os.sh",
    "install_openjdk21.sh",
    "install_jenkins.sh",
    "install_jenkins_plugins.sh",
    "jenkins_credential.sh",
    "install_git.sh",
    "tools_jenkins_jdk.sh"
  ]

  scripts_to_upload = [
    "provision_jenkins.sh" ,
    "update_upgrade_os.sh",
    "install_openjdk21.sh",
    "install_jenkins.sh",
    "install_jenkins_plugins.sh",
    "jenkins_credential.sh",
    "install_git.sh",
    "tools_jenkins_jdk.sh"    
  ]
  root_dir = abspath("${path.module}/../../..")
  script_dir            = "${local.root_dir}/shell_script"
  extra_files_source_dir = "${local.root_dir}/Jenkins"
  extra_files            = ["jenkins_plugin.txt"]
}
