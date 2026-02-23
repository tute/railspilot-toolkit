# Linear Issue Implementation Workflow

Implement a Linear or Jira issue with TDD approach, planning, memory tracking, subagent code reviews, and automated PR creation.

**Auto-detects task manager** by examining recent commits on master for Linear or Jira URLs.

## Usage

```
/task-implement <issue-id>
```

## What this command does

1. **Detect Task Manager**: Examines recent commits on master to identify Linear or Jira
2. **Fetch Issue**: Retrieves issue details using appropriate API (Linear MCP or Jira)
3. **Move to In Progress**: Updates issue status to indicate work has started
4. **Create Branch**: Creates a feature branch using task manager's naming convention
5. **Plan Solution**: Analyzes requirements and creates implementation plan
6. **Save to Memory**: Stores plan in memory graph for tracking
7. **Review Plan**: Presents plan for confirmation before execution
8. **TDD Implementation**: Implements solution with test-first approach
9. **System Testing**: Includes comprehensive system specs
10. **Parallel Code Reviews**: Two subagents review for security and Rails/OOP patterns
11. **Address Review Feedback**: Implement suggested improvements
12. **Validation**: Ensures linters and specs pass
13. **Logical Commits**: Creates meaningful commit history
14. **Create PR**: Opens pull request with proper task manager linking

## Arguments

- `$ARGUMENTS` - The issue ID (e.g., `TRA-9`, `DEV-123`, `PROJ-456`)

## Requirements

**Task Manager (one of):**
- Linear MCP integration configured, OR
- Jira MCP configured, OR Jira REST API credentials (`JIRA_EMAIL`, `JIRA_API_TOKEN`, `JIRA_DOMAIN`)

**Other:**
- Current working directory must be a git repository
- `bin/lint` script available for linting
- `bundle exec rspec` available for testing
- `gh` CLI for PR creation

## Example

```
/task-implement TRA-9
/task-implement PROJ-456
```

This will:

1. Auto-detect whether project uses Linear or Jira (from commit history)
2. Fetch issue details from the detected task manager
3. Move issue to "In Progress" status
4. Create branch using task manager's naming convention
5. Generate and review implementation plan
6. Implement with TDD approach
7. Run parallel code reviews (security + Rails/OOP)
8. Create PR with proper task manager linking

---

I'll help you implement the issue using a structured TDD workflow with comprehensive code reviews. Let me start by detecting which task manager this project uses, then fetch the issue details.

## Step 1: Detect Task Manager

I'll examine recent commits on master to determine whether this project uses Linear or Jira:

```bash
git log master -20 | grep -i "linear.app\|atlassian.net"
```

This detects the task manager by looking for:
- **Linear**: `linear.app` URLs in commit messages
- **Jira**: `atlassian.net` URLs in commit messages

## Step 2: Fetch Issue Details

Based on the detected task manager, I'll retrieve the issue information:

**For Linear:** Using Linear MCP integration
**For Jira:** Using Jira MCP or REST API

The issue details show: **$ARGUMENTS**

This will give me:
- Issue title/summary and description
- Current status and priority
- Branch naming information
- Team/project context
- Any attachments or related work

## Step 3: Move Issue to In Progress

I'll update the issue status to indicate work has started:

**For Linear:**
1. Identifies the current team for the issue
2. Retrieves the "In Progress" state ID for that team
3. Updates the issue status

**For Jira:**
1. Lists available transitions for the issue
2. Finds and executes the "In Progress" transition

This ensures proper project tracking and lets team members know the issue is being actively developed.

## Step 4: Create Feature Branch

I'll create the feature branch using the task manager's naming convention:

**For Linear:** Uses Linear's suggested `branchName` field
**For Jira:** Uses format `<initials>/<issue-key>-<slugified-summary>`

I'll:
1. Ensure we're on main branch and up-to-date
2. Create or checkout the feature branch
3. Verify the correct branch is active

## Step 5: Analyze and Plan Solution

I'll analyze the issue requirements and create a comprehensive implementation plan:

**Analysis Process:**

1. Break down the issue description into specific requirements
2. Identify the affected components and systems
3. Determine the testing strategy (unit, integration, system)
4. Plan the implementation approach
5. Identify potential risks and dependencies

**Planning Output:**

- **Goal**: Clear statement of what needs to be implemented
- **Requirements**: Specific functional and technical requirements
- **Architecture**: How the solution fits into existing codebase
- **Test Strategy**: Comprehensive testing approach including system specs
- **Implementation Steps**: Ordered list of development tasks
- **Acceptance Criteria**: How we'll know when it's complete

## Step 6: Save Plan to Memory

I'll store the implementation plan in the memory graph for tracking:

This creates a permanent record of:

- The issue context and requirements
- Implementation approach and reasoning
- Progress tracking throughout development
- Lessons learned for future similar issues

## Step 7: Review Plan with You

I'll present the complete plan for your review and confirmation:

**Plan Review Includes:**

- Summary of what will be implemented
- Key technical decisions and rationale
- Testing strategy and coverage
- Estimated complexity and risks
- Confirmation request before proceeding

**You can:**

- Approve the plan to proceed
- Request modifications to the approach
- Add additional requirements or constraints
- Ask questions about any aspect of the plan

## Step 8: Test-Driven Development Implementation

Upon your approval, I'll implement using strict TDD methodology:

**TDD Process:**

1. **Red Phase**: Write failing tests first
   - Unit tests for individual components
   - Integration tests for component interactions
   - System specs for end-to-end user workflows
2. **Green Phase**: Implement minimal code to pass tests
   - Focus on making tests pass with simplest solution
   - Avoid over-engineering in initial implementation
3. **Refactor Phase**: Improve code while keeping tests green
   - Extract methods and classes for clarity
   - Optimize performance where needed
   - Ensure code follows project conventions

**System Specs Strategy:**

- Create comprehensive system specs using Capybara
- Test the complete user journey
- Use page objects to keep tests maintainable
- Cover both happy path and edge cases

## Step 9: Parallel Subagent Code Reviews

After implementation, I'll launch two specialized subagents for comprehensive code review:

**Security Review Subagent:**

- Focus on security vulnerabilities and best practices
- Check for SQL injection, XSS, CSRF protections
- Verify authentication and authorization patterns
- Review data validation and sanitization
- Check for secrets or sensitive data exposure
- Validate secure coding practices

**Rails/OOP Patterns Review Subagent:**

- Evaluate adherence to POODR principles
- Check Rails conventions and best practices
- Review object-oriented design patterns
- Verify proper use of Result pattern
- Assess code organization and structure
- Check for code smells and refactoring opportunities

**Parallel Execution:**
Both subagents will run simultaneously to:

- Provide independent perspectives on the code
- Identify different types of issues
- Maximize review efficiency through parallelization
- Generate comprehensive feedback quickly

## Step 10: Address Review Feedback

I'll analyze feedback from both subagents and implement improvements:

**Feedback Processing:**

1. Consolidate recommendations from both reviews
2. Prioritize critical security issues and major design flaws
3. Plan incremental improvements
4. Implement fixes while maintaining test coverage

**Implementation of Fixes:**

- Address security vulnerabilities immediately
- Refactor code to follow better OOP patterns
- Improve Rails convention adherence
- Update tests to cover new scenarios identified
- Ensure all changes maintain backward compatibility

## Step 11: Validation and Quality Assurance

Before creating commits, I'll ensure everything passes:

**Validation Steps:**

1. Run full test suite: `bundle exec rspec`
2. Run linting: `bin/lint`
3. Fix any failures or warnings
4. Verify system specs pass in clean environment
5. Check for any missing test coverage

**Quality Checks:**

- Code follows project POODR principles
- Result pattern used for operations that can fail
- No security vulnerabilities introduced
- Performance impact considered
- All subagent feedback addressed

## Step 12: Create Logical Commits

I'll create meaningful commits that tell the story of implementation:

**Commit Strategy:**

1. **Test commits**: Add failing tests for new functionality
2. **Implementation commits**: Add code to make tests pass
3. **Refactor commits**: Improve code structure and clarity
4. **Security fixes**: Address security review feedback
5. **Pattern improvements**: Implement OOP/Rails pattern suggestions
6. **Documentation commits**: Update docs if needed

**Commit Messages Follow Project Convention:**

- Present-tense summary under 50 characters
- Detailed explanation if needed
- Reference to task manager issue (Linear URL or Jira key in prefix)
- Note which review feedback was addressed
- Claude Code attribution

## Step 13: Create Pull Request

Finally, I'll create a comprehensive PR with task manager integration:

**PR Creation:**

- Use `gh pr create` with detailed description
- Include task manager issue link for automatic integration
  - **Linear:** `Closes <Linear-issue-URL>` in body
  - **Jira:** Issue key in title (e.g., `PROJ-123: Feature`) and link in body
- Add comprehensive summary of changes
- Include test plan and validation steps
- Document code review process and findings
- Request appropriate reviewers

**PR Description Includes:**

- Summary of what was implemented
- Technical approach and key decisions
- Testing strategy and coverage
- Code review findings and resolutions
- Security considerations addressed
- Any breaking changes or migration notes
- Screenshots or demos if applicable

## Step 14: Final Verification

I'll verify the PR is properly set up:

**Final Checks:**

- CI/CD pipeline triggered successfully
- Task manager issue linked and updated
- All tests passing in CI environment
- Code review assignees notified
- Branch protection rules satisfied
- Security and pattern reviews documented

**Completion Summary:**

- Issue analyzed and planned
- Solution implemented with TDD
- Comprehensive system specs added
- Security review completed by subagent
- Rails/OOP patterns review completed by subagent
- All review feedback addressed
- All tests and linting pass
- Logical commit history created
- PR created with task manager integration

The issue will be automatically updated when the PR is merged, completing the full development lifecycle with comprehensive quality assurance.
