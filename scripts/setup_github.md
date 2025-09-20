# GitHub Repository Setup Guide

This guide will help you complete the GitHub repository setup for CanonMavlinkBridge.

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click "New repository" or go to https://github.com/new
3. Repository settings:
   - **Name**: `CanonMavlinkBridge`
   - **Description**: `MAVLink bridge for Canon cameras on companion computers`
   - **Visibility**: Public (recommended for open source)
   - **Initialize**: Do NOT initialize with README, .gitignore, or license (we already have these)

## Step 2: Push Local Repository

```bash
# Add GitHub remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/CanonMavlinkBridge.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 3: Configure Repository Settings

### Basic Settings
1. Go to repository Settings tab
2. **General** section:
   - Enable "Issues"
   - Enable "Wiki"
   - Enable "Projects"
   - Disable "Packages" (for now)

### Branch Protection
1. Go to **Branches** section
2. Add branch protection rule for `main`:
   - **Branch name pattern**: `main`
   - ✅ **Require a pull request before merging**
   - ✅ **Require approvals**: 1
   - ✅ **Dismiss stale PR approvals when new commits are pushed**
   - ✅ **Require review from code owners**
   - ✅ **Require status checks to pass before merging**
   - ✅ **Require branches to be up to date before merging**
   - ✅ **Require conversation resolution before merging**
   - ✅ **Do not allow bypassing the above settings**

### Required Status Checks
After first CI run, add these required status checks:
- `lint`
- `build (ubuntu-22.04, x64)`
- `build (ubuntu-20.04, x64)`
- `security`

## Step 4: Set Up Labels

Go to **Issues** → **Labels** and create the following labels:

### Type Labels
- `type:bug` - #d73a4a - Bug reports
- `type:feature` - #0075ca - New features
- `type:enhancement` - #a2eeef - Improvements to existing features
- `type:documentation` - #0052cc - Documentation updates
- `type:testing` - #fbca04 - Testing improvements
- `type:ci` - #000000 - CI/CD improvements

### Priority Labels
- `priority:critical` - #b60205 - Critical issues blocking development
- `priority:high` - #d93f0b - High priority items
- `priority:medium` - #fbca04 - Medium priority items
- `priority:low` - #0e8a16 - Low priority items

### Component Labels
- `component:canon` - #1d76db - Canon module related
- `component:mavlink` - #0052cc - MAVLink module related
- `component:bridge` - #5319e7 - Bridge core related
- `component:build` - #000000 - Build system related
- `component:testing` - #006b75 - Testing infrastructure

### Status Labels
- `status:blocked` - #d73a4a - Blocked by dependencies
- `status:in-review` - #fbca04 - Under review
- `status:ready` - #0e8a16 - Ready for implementation
- `status:wip` - #fbca04 - Work in progress

### Milestone Labels
- `milestone:m1` - #0052cc - Milestone 1 tasks
- `milestone:m2` - #0052cc - Milestone 2 tasks
- `milestone:m3` - #0052cc - Milestone 3 tasks
- `milestone:m4` - #0052cc - Milestone 4 tasks

### Good First Issue
- `good first issue` - #7057ff - Good for newcomers

## Step 5: Create Milestones

Go to **Issues** → **Milestones** and create:

1. **Milestone 1: Foundation Setup**
   - **Due date**: 2 weeks from now
   - **Description**: Establish development environment and basic project structure

2. **Milestone 2: Core Module Implementation**
   - **Due date**: 4 weeks from now
   - **Description**: Implement basic Canon and MAVLink modules

3. **Milestone 3: Bridge Integration**
   - **Due date**: 6 weeks from now
   - **Description**: Implement bridge core and basic camera operations

4. **Milestone 4: Production Ready**
   - **Due date**: 8 weeks from now
   - **Description**: Complete feature set and production deployment

## Step 6: Set Up GitHub Projects

1. Go to **Projects** tab
2. Create new project (Classic):
   - **Name**: "Development Board"
   - **Template**: "Basic kanban"
   - **Columns**: Backlog, Ready for Development, In Progress, In Review, Testing, Done

3. Create second project:
   - **Name**: "Release Planning"
   - **Template**: "Basic kanban"
   - **Columns**: Milestone 1, Milestone 2, Milestone 3, Milestone 4, Future

## Step 7: Configure Actions

1. Go to **Actions** tab
2. The CI workflow should automatically run on the first push
3. If it fails, check the workflow file and fix any issues
4. Once working, go to Settings → Branches and add the required status checks

## Step 8: Set Up Container Registry

1. Go to **Packages** tab (it will be empty initially)
2. The Docker images will be published automatically by the CI pipeline
3. Images will be available at `ghcr.io/YOUR_USERNAME/canonmavlinkbridge`

## Step 9: Enable Discussions (Optional)

1. Go to **Settings** → **General**
2. Scroll to **Features** section
3. Enable **Discussions**
4. Choose categories: General, Ideas, Q&A, Show and tell

## Step 10: Set Up Wiki (Optional)

1. Go to **Wiki** tab
2. Create the first page with project overview
3. Link to detailed documentation in the docs/ folder

## Verification Checklist

After completing setup, verify:

- [ ] Repository is public and accessible
- [ ] All files pushed successfully
- [ ] Branch protection rules active
- [ ] Labels created and properly colored
- [ ] Milestones created with dates
- [ ] Projects set up with proper columns
- [ ] CI workflow running successfully
- [ ] Issue templates working
- [ ] PR template working

## Next Steps

1. Create initial issues for Milestone 1 tasks
2. Assign issues to milestones and projects
3. Start development workflow
4. Invite collaborators if needed
5. Set up any additional integrations (CodeQL, Dependabot, etc.)

---

**Note**: Replace `YOUR_USERNAME` with your actual GitHub username in all commands and URLs.