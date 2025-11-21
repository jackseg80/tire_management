# Contributing to TeslaMate Tire Management

First off, thank you for considering contributing to TeslaMate Tire Management!

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project adheres to a simple code of conduct:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive criticism
- Assume good faith

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When creating a bug report, include:

- **Clear title** - Descriptive summary of the issue
- **Steps to reproduce** - How to trigger the bug
- **Expected behavior** - What should happen
- **Actual behavior** - What actually happens
- **Environment details:**
  - TeslaMate version
  - PostgreSQL version
  - Grafana version
  - Tesla model
  - Operating system

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title** - Descriptive summary
- **Detailed description** - What you want to happen
- **Use cases** - Why this would be useful
- **Examples** - Mockups, examples, or similar features elsewhere

### Pull Requests

We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`
2. If you've added code, add tests if applicable
3. If you've changed APIs or database schema, update the documentation
4. Ensure your code follows the project's style guidelines
5. Write clear commit messages
6. Update CHANGELOG.md with your changes
7. Submit your pull request!

## Development Setup

### Prerequisites

- Docker and Docker Compose
- PostgreSQL client (`psql`)
- Git
- Text editor or IDE

### Local Setup

1. **Fork and clone the repository:**

```bash
git clone https://github.com/jackseg80/teslamate-tire-management.git
cd teslamate-tire-management
```

2. **Set up test environment:**

```bash
# Connect to your TeslaMate test instance
docker exec -it teslamate-database-1 psql -U teslamate teslamate

# Create test schema
\i tire_management.sql

# Add test data
\i example_data.sql
```

3. **Make changes and test:**

```bash
# Edit files
nano tire_management.sql

# Test your changes
docker exec -it teslamate-database-1 psql -U teslamate teslamate < tire_management.sql

# Verify
SELECT * FROM tire_sets_with_stats;
```

## Coding Standards

### SQL

- Use lowercase for SQL keywords: `select`, `from`, `where`
- Indent with 4 spaces
- One column per line in `SELECT` statements
- Add comments for complex queries
- Use meaningful table/column names

**Example:**

```sql
-- Good
SELECT 
    ts.name,
    ts.date_start,
    tss.consumption_wh_km
FROM tire_sets ts
LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id
WHERE ts.date_end IS NULL;

-- Avoid
select ts.name,ts.date_start,tss.consumption_wh_km from tire_sets ts left join tire_set_statistics tss on ts.id=tss.tire_set_id where ts.date_end is null;
```

### Bash Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Add comments for complex sections
- Use meaningful variable names
- Quote variables: `"$VARIABLE"`

**Example:**

```bash
#!/bin/bash
set -e

CONTAINER_NAME="${POSTGRES_CONTAINER:-teslamate-database-1}"

if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Error: Container not found"
    exit 1
fi
```

### Documentation

- Use clear, concise language
- Include code examples
- Add screenshots where helpful
- Keep README.md up to date
- Document all functions and complex queries

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**

```
feat: add TPMS pressure tracking

Added new columns to tire_sets table to track tire pressure over time.
Includes new Grafana panel for pressure visualization.

Closes #42
```

```
fix: correct consumption calculation for short trips

Changed distance filter from >= 1 km to >= 5 km to exclude outlier
short trips that skew consumption averages.

Fixes #38
```

```
docs: update README with troubleshooting section

Added common issues and solutions based on user feedback.
```

## Pull Request Process

1. **Update documentation** - If you changed functionality, update docs
2. **Update CHANGELOG.md** - Add your changes under `[Unreleased]`
3. **Test thoroughly** - Ensure your changes work as expected
4. **Create clear PR description:**
   - What problem does this solve?
   - How did you solve it?
   - How should reviewers test it?
5. **Link related issues** - Use keywords like "Closes #123"
6. **Be responsive** - Address review feedback promptly

### PR Template

```markdown
## Description
Brief description of changes

## Motivation and Context
Why is this change needed?

## How Has This Been Tested?
Describe your testing process

## Types of Changes
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have updated the documentation accordingly
- [ ] I have added tests to cover my changes (if applicable)
- [ ] All new and existing tests passed
- [ ] I have updated CHANGELOG.md
```

## Areas We Need Help With

We especially welcome contributions in these areas:

### High Priority
- **Testing on different Tesla models** - Verify conversion factors
- **Mobile-friendly dashboard improvements**
- **Translations** - Documentation in other languages
- **Additional Grafana panels** - New visualizations

### Medium Priority
- **Automated testing** - SQL and dashboard tests
- **Performance optimization** - Query improvements
- **UI/UX improvements** - Better dashboard layouts
- **Documentation** - More examples, tutorials

### Low Priority (Future Features)
- **Alert system** - Notifications for tire changes
- **Cost tracking** - Track tire expenses
- **API development** - REST API for mobile apps
- **Tire wear prediction** - ML-based predictions

## Questions?

Don't hesitate to ask questions! You can:

- Open an issue with the `question` label
- Start a discussion on GitHub Discussions
- Check existing issues and pull requests

## Recognition

Contributors will be recognized in:
- README.md acknowledgments section
- Release notes
- GitHub contributors page

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to TeslaMate Tire Management!**