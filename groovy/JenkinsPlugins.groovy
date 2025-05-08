def installFromFile(String pluginFile, String jenkinsUrl, String credsId) {
    withCredentials([usernamePassword(credentialsId: credsId, usernameVariable: 'J_USER', passwordVariable: 'J_PASS')]) {
        sh """
            echo "[*] Downloading Jenkins CLI from: ${jenkinsUrl}"
            curl -s -o jenkins-cli.jar ${jenkinsUrl}/jnlpJars/jenkins-cli.jar

            echo "[*] Reading plugins from file: ${pluginFile}"
            while IFS= read -r plugin || [[ -n "\$plugin" ]]; do
              plugin=\$(echo "\$plugin" | xargs)  # Trim whitespace
              if [ -z "\$plugin" ]; then continue; fi

              echo "[*] Checking status of plugin: \$plugin"
              if java -jar jenkins-cli.jar -s ${jenkinsUrl} -auth \$J_USER:\$J_PASS list-plugins | cut -f1 -d' ' | grep -q "^\\\$plugin\$"; then
                echo "[✓] Already installed: \$plugin"
              else
                echo "[+] Installing plugin: \$plugin"
                if java -jar jenkins-cli.jar -s ${jenkinsUrl} -auth \$J_USER:\$J_PASS install-plugin "\$plugin"; then
                  echo "[✓] Successfully installed: \$plugin"
                else
                  echo "[✗] Failed to install: \$plugin"
                fi
              fi
            done < ${pluginFile}

            echo "[*] Plugin installation completed. Jenkins may require a restart for changes to take effect."
        """
    }
}
return this
