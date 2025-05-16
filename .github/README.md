# GitHub Actions Configuration

This directory contains GitHub Actions workflow configurations for CI/CD automation.

## Workflows

### `pr-validation.yml`

Workflow that runs on pull requests to the main branch. It:

1. **Lint**: Verifies the Helm chart for syntax and structural issues
   - Sets up Helm and updates dependencies
   - Runs YAML linting with a custom configuration
   - Uses chart-testing action to perform comprehensive chart linting

2. **Unit Test**: Tests the Helm chart templates functionality
   - Runs helm-unittest against deployment-patch template
   - Runs helm-unittest against migration-job-patch template
   - Validates templates generate expected Kubernetes resources

3. **Security Scan**: Analyzes chart for security vulnerabilities
   - Uses Trivy to scan for security issues with CRITICAL and HIGH severity
   - Displays results in table format

4. **Version Check**: Ensures proper versioning
   - Compares the chart version in the PR with the version in the main branch
   - Verifies that the version has been incremented
   - Adds a comment to the PR indicating version check status

### `release.yml`

Workflow that runs on pushes to the main branch. It:

1. **Lint**: Same linting process as the PR validation

2. **Unit Test**: Same unit tests as the PR validation

3. **Security Scan**: Similar to PR validation but:
   - Outputs results in SARIF format
   - Uploads findings to GitHub Security tab

4. **Release**: Publishes the chart if checks pass
   - Extracts chart information (name, version)
   - Generates release notes using release-drafter
   - Packages the Helm chart
   - Deploys to GitHub Pages
   - Updates the Helm repository index
   - Creates a GitHub Release with the packaged chart

## Secrets & Configuration

This workflow uses the following GitHub secrets:

- `GITHUB_TOKEN`: Automatically provided by GitHub Actions, used for:
  - Pushing to the gh-pages branch
  - Creating GitHub releases
  - Updating the security tab with scan results

## Required GitHub Pages Setup

To enable the chart repository:

1. Go to repository Settings → Pages
2. Set the source to "Deploy from a branch"
3. Select the `gh-pages` branch and `/ (root)` folder
4. Save the configuration

After the first successful workflow run, your Helm repository will be accessible at:
`https://<username>.github.io/<repository>/`

## Adding the Repository

To use your chart repository:

```bash
helm repo add my-repo https://<username>.github.io/<repository>/
helm repo update
helm search repo my-repo
``` 