---
name: rspec-testing
description: Provides RSpec best practices — test structure, factories, system specs, mocking, anti-patterns. Use when writing, reviewing, or improving RSpec tests.
---

# RSpec Testing for Rails

Write maintainable RSpec tests that catch production bugs, each at one layer. This skill combines guidance from Better Specs and thoughtbot's testing guides.

## Core Testing Principles

### 1. Test-Driven Development (TDD)
See the TDD-workflow skill. Follow the Red-Green-Refactor cycle:
- **Red**: Write failing tests that define expected behavior
- **Green**: Implement minimal code to make tests pass
- **Refactor**: Improve code while tests continue to pass

### 2. Test Structure (Arrange-Act-Assert)
Organize tests with clear phases separated by newlines:

```ruby
it 'creates a new article' do
  # Arrange - set up test data
  user = create(:user)
  attributes = {title: 'Test Article', body: 'Content here'}

  # Act - perform the action
  article = Article.create(attributes)

  # Assert - verify the outcome
  expect(article).to be_persisted
  expect(article.title).to eq('Test Article')
end
```

### 3. Single Responsibility
Each test should verify one behavior. For unit tests, use one expectation per test. For integration tests, multiple expectations are acceptable when testing a complete flow.

### 4. Test Real Behavior
Avoid over-mocking. Test actual application behavior when possible. Only stub external services, slow operations, and dependencies outside your control.

## RSpec Syntax & Style Guide

### Describe Blocks
Use Ruby documentation conventions:
- `.method_name` for class methods
- `#method_name` for instance methods

```ruby
describe '.find_by_title' do      # class method
describe '#publish' do              # instance method
describe 'validations' do           # grouping
```

### Context Blocks
Start with "when," "with," or "without":

```ruby
context 'when user is admin' do
context 'with valid parameters' do
context 'without authentication' do
```

### It Blocks
- Keep descriptions under 40 characters
- Use third-person present tense
- **Never** use "should" in descriptions

```ruby
# ✅ Good
it 'creates a new article' do
it 'rejects a duplicate slug' do
it 'redirects to dashboard' do

# ❌ Bad
it 'should create a new article' do
it 'should reject a duplicate slug' do
```

### Expectations
Always use `expect` syntax (never `should`):

```ruby
# ✅ Good
expect(article).to be_valid
expect(response).to have_http_status(:success)
expect { action }.to change(Article, :count).by(1)

# ❌ Bad (deprecated)
article.should be_valid
response.should have_http_status(:success)
```

### One-Liners
Don’t use shoulda-matchers for associations or validations.

For behavior tests, prefer explicit setup/execute/expect over `subject`.

## System Test Best Practices

### Authentication in System Tests

Test authentication flows directly without stubbing:

```ruby
# Good - test the actual login flow
visit '/login'
fill_in 'Email', with: user.email
fill_in 'Password', with: 'password'
click_button 'Sign In'

expect(page).to have_current_path(dashboard_path)
```

### Controller Test Authentication

For controller tests, use direct session assignment rather than stubbing:

```ruby
# ✅ Good - direct session assignment
session[:user_id] = user.id

# ❌ Avoid - stubbing authentication
allow_any_instance_of(Controller).to receive(:logged_in?).and_return(true)
```

### Avoid CSS Class Testing

Don't test implementation details like CSS utility classes or copy. Test semantic selectors, form wiring and record state:

```ruby
# ✅ Good - semantic selectors, form wiring, record state
expect(page).to have_selector(:test_id, 'user-modal')
expect(page).to have_css("[aria-hidden='false']")
expect(page).to have_button('Submit')
expect(page).to have_field('article[title]')
expect(page).to have_css("form[action='#{articles_path}']")
expect(article.reload).to be_published

# ❌ Bad - coupling to copy and CSS implementation
expect(page).to have_content('Success message')
expect(page).to have_css('.opacity-100')
expect(page).to have_css('.bg-red-500')
expect(page).to have_css('.rounded-lg')
```

## Factory Patterns

### Organization
1. Associations (implicit) first
2. Attributes (alphabetical)
3. Traits (alphabetical)

```ruby
FactoryBot.define do
  factory :article do
    # Associations
    user
    category

    # Attributes (alphabetical)
    body { 'Article content goes here...' }
    published_at { Time.current }
    status { :draft }
    title { 'Sample Article Title' }

    # Traits (alphabetical)
    trait :published do
      status { :published }
      published_at { 1.day.ago }
    end

    trait :with_tags do
      after(:create) do |article|
        create_list(:tag, 3, article: article)
      end
    end
  end
end
```

### Prefer Build Over Create
Use `build` and `build_stubbed` when database persistence isn't needed:

```ruby
# ✅ Good - fast, no database hit
it 'requires published_at once published' do
  article = build(:article, status: :published, published_at: nil)
  expect(article).not_to be_valid
end

# Less optimal - unnecessary database hit
it 'requires published_at once published' do
  article = create(:article, status: :draft, published_at: nil)
  article.status = :published
  expect(article).not_to be_valid
end
```

## Common Testing Patterns

### Testing Our Constraints
Test the rules we wrote: conditional and custom validations, and database
constraints. Skip one-line declarations like presence or `belongs_to`.

```ruby
describe 'validations' do
  it 'requires published_at once published' do
    article = build(:article, status: :published, published_at: nil)
    expect(article).not_to be_valid
  end

  it 'allows a draft without published_at' do
    article = build(:article, status: :draft, published_at: nil)
    expect(article).to be_valid
  end
end

describe 'database constraints' do
  it 'rejects a duplicate slug' do
    existing = create(:article)
    article = create(:article)

    expect do
      article.update_column(:slug, existing.slug)
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
```

`update_column` and raw SQL skip the validation, so the test proves the
migration holds.

### Testing Authorization
```ruby
context 'when user is not admin' do
  it 'raises authorization error' do
    user = create(:user, role: :member)
    session[:user_id] = user.id

    expect do
      get :admin_dashboard
    end.to raise_error(Pundit::NotAuthorizedError)
  end
end
```

## What to Avoid

### ❌ Don't Write Tests That Cannot Catch a Bug
Follow the "Do not write" list in `tdd-skill`: no tests of declarations, of
states no caller can produce, or of a branch another layer already tests.

### ❌ Don't Stub the System Under Test
Never mock or stub methods on the class being tested:

```ruby
# ❌ Bad
it 'processes payment' do
  order = Order.new
  allow(order).to receive(:calculate_total).and_return(100)
  expect(order.process_payment).to be true
end

# ✅ Good
it 'processes payment' do
  order = Order.new(line_items: [line_item])
  expect(order.process_payment).to be true
end
```

### ❌ Don't Test Private Methods
Test the public interface. Private methods are tested indirectly:

```ruby
# ❌ Bad
describe '#calculate_total (private)' do
  it 'sums line items' do
    order.send(:calculate_total)
  end
end

# ✅ Good
describe '#total' do
  it 'returns sum of line items' do
    expect(order.total).to eq(100)
  end
end
```

### ❌ Avoid `any_instance_of`
Use dependency injection instead:

```ruby
# ❌ Bad
allow_any_instance_of(PaymentService).to receive(:charge)

# ✅ Good
payment_service = instance_double(PaymentService)
allow(payment_service).to receive(:charge).and_return(success)
order = Order.new(payment_service: payment_service)
```

## Quick Reference

### Test Organization
```ruby
RSpec.describe ClassName do
  # Class methods
  describe '.class_method' do
  end

  # Instance methods
  describe '#instance_method' do
    context 'when condition' do
      it 'does something' do
        resource = create(:resource)

        result = resource.instance_method

        expect(result).to eq(expected)
      end
    end
  end

  # Extract repeated setup into private methods, not let/before blocks
  private

  def create_resource_with_dependencies
    user = create(:user)
    create(:resource, user: user)
  end
end
```

### Prefer Inline Setup Over let/before
Use the setup/execute/expect pattern directly in each test. Extract common setup
into private methods when repetition gets excessive — but some repetition is fine
and preferred over indirection.

### Expectation Matchers
```ruby
# Equality
expect(value).to eq(expected)
expect(value).to be(expected)           # same object
expect(value).to match(/regex/)

# Predicates
expect(object).to be_valid
expect(object).to be_persisted
expect(collection).to be_empty

# Collections
expect(array).to include(item)
expect(array).to contain_exactly(1, 2, 3)
expect(hash).to have_key(:name)

# Changes
expect { action }.to change(Model, :count).by(1)
expect { action }.to change { object.attribute }.from(old).to(new)

# Errors
expect { action }.to raise_error(ErrorClass)
expect { action }.not_to raise_error
```

## Scaling: When the Suite Gets Slow (~3+ min)

1. **First**: disable query log tags and raise log level in test env (`query_log_tags_enabled = false`, `log_level = :fatal`). I/O from SQL annotations is often the biggest bottleneck.
2. **Then**: if still slow, suggest the user adding `parallel_tests` gem. If they decide to try it, plan it as an independent changeset for followup work.

## Resources

This skill includes detailed reference documentation in the `references/` directory:

### `references/better_specs_guide.md`
Comprehensive patterns from Better Specs including:
- Describe/context/it block conventions
- Subject and let usage
- Mocking strategies
- Shared examples
- Factory patterns

### `references/thoughtbot_patterns.md`
thoughtbot's RSpec best practices covering:
- Modern RSpec syntax
- Test structure and organization
- What to avoid in tests
- Capybara patterns for system tests
- Factory organization

Load these references when you need detailed examples or are unsure about a specific pattern.
