#!/bin/bash
set -e

echo "Setting up Crossplane Policy Scheduler Local Testing Environment"

# Check if required tools are installed
check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        exit 1
    else
        echo "✅ $1 is available"
    fi
}

echo "📋 Checking dependencies..."
check_dependency "docker"
check_dependency "python3"
check_dependency "pip"

# Install Crossplane CLI if not present
if ! command -v crossplane &> /dev/null; then
    echo "📦 Installing Crossplane CLI..."
    curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh
    sudo mv crossplane /usr/local/bin/
else
    echo "✅ Crossplane CLI is available"
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install behave python-benedict allure-behave

# Clone the testing framework if not present
if [ ! -d "crossplane-composition-tester" ]; then
    echo "📦 Cloning crossplane-composition-tester..."
    git clone https://github.com/swisscom/crossplane-composition-tester.git
fi

cd crossplane-composition-tester

# Create directory structure
echo "📁 Creating test directory structure..."
mkdir -p test/pkg/policy-scheduler
mkdir -p test/composition-tests/policy-scheduler/resources

# You would copy your files here
echo "📄 Copy your files to:"
echo "  - composition.yaml → test/pkg/policy-scheduler/"
echo "  - claim.yaml → test/composition-tests/policy-scheduler/resources/"
echo "  - functions.yaml → test/"
echo "  - *.feature → test/composition-tests/policy-scheduler/"

echo ""
echo "🧪 To test locally without Kubernetes:"
echo "  1. Copy your files to the directories shown above"
echo "  2. Run: behave test/composition-tests/policy-scheduler/"
echo ""
echo "🔍 To test individual composition rendering:"
echo "  crossplane render --composition=composition.yaml --claim=claim.yaml --functions=functions.yaml"
echo ""
echo "✨ Setup complete! No Kubernetes cluster required for basic testing."