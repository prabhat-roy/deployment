#!/bin/bash
set -e

install_stackstorm() {
  echo "🔧 Installing StackStorm via Docker..."

  # Pull StackStorm Docker image
  echo "⬇️ Pulling StackStorm Docker image..."
  docker pull stackstorm/st2

  # Run StackStorm container
  echo "🚀 Running StackStorm in Docker..."
  docker run --name stackstorm -d -p 80:80 -p 443:443 stackstorm/st2

  echo "✅ StackStorm is now running in Docker."
  echo "🔑 Access StackStorm via http://<your-server-ip>"
}
