if Code.ensure_loaded?(Ash.Resource.Validation) do
  defmodule Plurality.Ash.Validations.PluralForm do
    @moduledoc """
    An `Ash.Resource.Validation` that ensures an attribute value is in plural form.

    ## Options

      * `:attribute` (atom, required) — the attribute to validate

    ## Usage

        validate {Plurality.Ash.Validations.PluralForm, attribute: :table_name}

    `nil` values pass validation (use `allow_nil? false` on the attribute
    if presence is required). Uncountable words like `"software"` pass
    since they are valid in plural context.
    """
    use Ash.Resource.Validation

    @impl true
    def init(opts) do
      cond do
        not Keyword.has_key?(opts, :attribute) -> {:error, "attribute is required"}
        not is_atom(opts[:attribute]) -> {:error, "attribute must be an atom"}
        true -> {:ok, opts}
      end
    end

    @impl true
    def validate(changeset, opts, _context) do
      value = Ash.Changeset.get_attribute(changeset, opts[:attribute])

      cond do
        is_nil(value) -> :ok
        not is_binary(value) -> {:error, field: opts[:attribute], message: "must be a string"}
        Plurality.plural?(value) -> :ok
        true -> {:error, field: opts[:attribute], message: "must be in plural form"}
      end
    end
  end
end
