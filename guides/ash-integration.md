# Ash Integration

Plurality ships optional building blocks for [Ash](https://hex.pm/packages/ash)
applications: changes, validations, and calculations for noun inflection. These
modules compile away to nothing if Ash isn't loaded — no extra dependencies
required.

## Changes

Auto-inflect an attribute from another attribute on create or update.

### Pluralize

```elixir
defmodule MyApp.Resource do
  use Ash.Resource

  attributes do
    attribute :name, :string
    attribute :table_name, :string
  end

  actions do
    create :create do
      change {Plurality.Ash.Changes.Pluralize, attribute: :table_name, from: :name}
    end
  end
end
```

When `:name` is `"user"`, `:table_name` is set to `"users"`.

**Options:**

- `:attribute` (atom, required) — the attribute to write the inflected form to
- `:from` (atom, required) — the source attribute to read from

If the source attribute is `nil`, the changeset is returned unchanged.

### Singularize

```elixir
change {Plurality.Ash.Changes.Singularize, attribute: :resource_name, from: :label}
```

Same options as `Pluralize`. Writes the singular form of the source attribute.

## Validations

Ensure an attribute value is in the expected inflected form.

### PluralForm

```elixir
validate {Plurality.Ash.Validations.PluralForm, attribute: :table_name}
```

Fails validation if the attribute value is not in plural form. `nil` values
pass (use `allow_nil? false` on the attribute if presence is required).
Uncountable words like `"software"` pass since they are valid in plural
context.

**Options:**

- `:attribute` (atom, required) — the attribute to validate

### SingularForm

```elixir
validate {Plurality.Ash.Validations.SingularForm, attribute: :resource_name}
```

Same as `PluralForm` but validates the value is in singular form.

## Calculations

Derive plural or singular forms without storing them as attributes.

### Pluralize

```elixir
calculations do
  calculate :name_plural, :string, {Plurality.Ash.Calculations.Pluralize, attribute: :name}
end
```

Returns the plural form of the source attribute. Returns `nil` if the source
is `nil`.

**Options:**

- `:attribute` (atom, required) — the source attribute to inflect

### Singularize

```elixir
calculations do
  calculate :name_singular, :string, {Plurality.Ash.Calculations.Singularize, attribute: :name}
end
```

## Full example

```elixir
defmodule MyApp.Schema do
  use Ash.Resource,
    domain: MyApp.Admin,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :table_name, :string
    attribute :resource_name, :string
  end

  actions do
    create :create do
      accept [:name]
      change {Plurality.Ash.Changes.Pluralize, attribute: :table_name, from: :name}
      change {Plurality.Ash.Changes.Singularize, attribute: :resource_name, from: :name}
    end

    update :update do
      accept [:name]
      validate {Plurality.Ash.Validations.PluralForm, attribute: :table_name}
      validate {Plurality.Ash.Validations.SingularForm, attribute: :resource_name}
    end
  end

  calculations do
    calculate :display_plural, :string, {Plurality.Ash.Calculations.Pluralize, attribute: :name}
    calculate :display_singular, :string, {Plurality.Ash.Calculations.Singularize, attribute: :name}
  end
end
```

## Conditional compilation

All Ash integration modules are wrapped in `if Code.ensure_loaded?/1` checks.
If Ash is not in your dependency tree, these modules don't exist and have zero
impact on compilation or runtime. You don't need to do anything to enable or
disable them — it's automatic.
